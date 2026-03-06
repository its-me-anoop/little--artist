import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/database.dart';
import 'firebase_auth_service.dart';
import 'storage_service.dart';

// ---------------------------------------------------------------------------
// MARK: - Error Enum
// ---------------------------------------------------------------------------

enum FirestoreError {
  notAuthenticated,
  syncFailed,
}

// ---------------------------------------------------------------------------
// MARK: - Sharing Data Classes
// ---------------------------------------------------------------------------

class ShareParticipant {
  final String userId;
  final String role;
  final DateTime? acceptedAt;
  ShareParticipant({
    required this.userId,
    required this.role,
    this.acceptedAt,
  });
}

class ShareInfo {
  final String shareId;
  final String status;
  ShareInfo({required this.shareId, required this.status});
}

// ---------------------------------------------------------------------------
// MARK: - Firestore Repository
// ---------------------------------------------------------------------------

/// Central write layer implementing dual-write pattern:
/// 1. Write to local Drift database (immediate UI update)
/// 2. Async write to Firestore (queued if offline)
/// 3. Binary upload to Firebase Storage if needed
class FirestoreRepository {
  final AppDatabase db;
  final FirebaseAuthService authService;
  final StorageService storageService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Local write IDs for echo suppression in sync service.
  final Set<String> localWriteIds = {};

  /// True while uploadAllLocalData is running.
  bool isUploadingAll = false;

  String? get _userId => authService.userId;
  bool get isSyncActive => _userId != null;
  // Premium check will be wired later
  // ignore: unused_element
  bool get _canUsePremiumFeatures => true; // TODO: wire to PremiumManager

  FirestoreRepository({
    required this.db,
    required this.authService,
    required this.storageService,
  });

  // ---------------------------------------------------------------------------
  // MARK: - Preferences
  // ---------------------------------------------------------------------------

  /// Pushes SharedPreferences values to Firestore `users/{uid}/meta/preferences`.
  Future<void> syncUserPreferencesToFirestore() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'hasCompletedOnboarding': prefs.getBool('hasCompletedOnboarding') ?? false,
        'selectedChildId': prefs.getInt('selectedChildId'),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.doc('users/$uid/meta/preferences').set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FirestoreRepository: syncUserPreferences failed – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Children (Create)
  // ---------------------------------------------------------------------------

  /// Creates a child in local DB and asynchronously syncs to Firestore.
  /// Returns the local DB row ID.
  Future<int> createChild({
    required String name,
    String avatarColor = 'F2784B',
    Uint8List? avatarImageData,
  }) async {
    final uid = _userId;
    final childDocId = _uuid.v4();
    final firestoreId = uid != null ? 'users/$uid/children/$childDocId' : null;

    // Register for echo suppression before insert
    if (firestoreId != null) {
      localWriteIds.add(childDocId);
    }

    // 1. Insert into Drift DB
    final localId = await db.childDao.insertChild(
      ChildrenCompanion(
        name: Value(name),
        avatarColor: Value(avatarColor),
        avatarImageData: avatarImageData != null
            ? Value(avatarImageData)
            : const Value.absent(),
        firestoreId: firestoreId != null
            ? Value(firestoreId)
            : const Value.absent(),
        ownerUserId: uid != null ? Value(uid) : const Value.absent(),
      ),
    );

    // 2. Async: sync to Firestore
    if (uid != null && firestoreId != null) {
      _syncChildToFirestore(
        uid: uid,
        childDocId: childDocId,
        name: name,
        avatarColor: avatarColor,
        avatarImageData: avatarImageData,
        createdAt: DateTime.now(),
      );
    }

    return localId;
  }

  // ---------------------------------------------------------------------------
  // MARK: - Children (Update)
  // ---------------------------------------------------------------------------

  /// Updates a child in local DB and asynchronously syncs changes to Firestore.
  Future<void> updateChild(
    Child child, {
    String? name,
    String? avatarColor,
    Uint8List? avatarImageData,
  }) async {
    final updated = child.copyWith(
      name: name ?? child.name,
      avatarColor: avatarColor ?? child.avatarColor,
      avatarImageData: avatarImageData != null
          ? Value(avatarImageData)
          : const Value.absent(),
    );

    // 1. Update in Drift DB
    await db.childDao.updateChild(updated);

    // 2. Async: update in Firestore
    final uid = _userId;
    if (uid != null && child.firestoreId != null) {
      final docId = _extractDocId(child.firestoreId!);
      localWriteIds.add(docId);
      _updateChildInFirestore(
        uid: uid,
        childDocId: docId,
        name: name,
        avatarColor: avatarColor,
        avatarImageData: avatarImageData,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Children (Delete)
  // ---------------------------------------------------------------------------

  /// Deletes a child and all its artworks from local DB and Firestore.
  Future<void> deleteChild(int childId) async {
    final child = await db.childDao.getChildById(childId);
    if (child == null) return;

    final uid = _userId;

    // Track for echo suppression
    if (child.firestoreId != null) {
      localWriteIds.add(_extractDocId(child.firestoreId!));
    }

    // 1. Delete from Drift DB (cascade deletes artworks)
    await db.childDao.deleteChild(childId);

    // 2. Async: delete from Firestore + Storage
    if (uid != null && child.firestoreId != null) {
      _deleteChildFromFirestore(
        uid: uid,
        childDocId: _extractDocId(child.firestoreId!),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Artworks (Create)
  // ---------------------------------------------------------------------------

  /// Creates an artwork in local DB and asynchronously syncs to Firestore.
  /// Returns the local DB row ID.
  Future<int> createArtwork({
    required String title,
    String caption = '',
    Uint8List? imageData,
    Uint8List? thumbnailData,
    Uint8List? voiceNoteData,
    bool isFavorited = false,
    DateTime? createdAt,
    required int childId,
    List<String>? tagNames,
  }) async {
    final uid = _userId;
    final artworkDocId = _uuid.v4();
    final child = await db.childDao.getChildById(childId);
    final childDocId = child?.firestoreId != null
        ? _extractDocId(child!.firestoreId!)
        : null;
    final firestoreId = uid != null && childDocId != null
        ? 'users/$uid/children/$childDocId/artworks/$artworkDocId'
        : null;

    // Register for echo suppression
    if (firestoreId != null) {
      localWriteIds.add(artworkDocId);
    }

    final now = createdAt ?? DateTime.now();

    // 1. Insert into Drift DB
    final localId = await db.artworkDao.insertArtwork(
      ArtworksCompanion(
        title: Value(title),
        caption: Value(caption),
        imageData: imageData != null ? Value(imageData) : const Value.absent(),
        thumbnailData: thumbnailData != null
            ? Value(thumbnailData)
            : const Value.absent(),
        voiceNoteData: voiceNoteData != null
            ? Value(voiceNoteData)
            : const Value.absent(),
        isFavorited: Value(isFavorited),
        createdAt: Value(now),
        childId: Value(childId),
        firestoreId: firestoreId != null
            ? Value(firestoreId)
            : const Value.absent(),
      ),
    );

    // 2. Handle tags
    if (tagNames != null && tagNames.isNotEmpty) {
      for (final tagName in tagNames) {
        final tagId = await db.tagDao.getOrCreateTag(tagName);
        await db.tagDao.addTagToArtwork(localId, tagId);
      }
    }

    // 3. Async: sync to Firestore
    if (uid != null && childDocId != null) {
      _syncArtworkToFirestore(
        uid: uid,
        childDocId: childDocId,
        artworkDocId: artworkDocId,
        title: title,
        caption: caption,
        imageData: imageData,
        voiceNoteData: voiceNoteData,
        isFavorited: isFavorited,
        createdAt: now,
        localId: localId,
        tagNames: tagNames,
      );
    }

    return localId;
  }

  // ---------------------------------------------------------------------------
  // MARK: - Artworks (Batch Create)
  // ---------------------------------------------------------------------------

  /// Creates multiple artworks, offsetting dates by index to avoid collisions.
  Future<void> batchCreateArtworks({
    required List<({
      String title,
      String caption,
      Uint8List? imageData,
      Uint8List? thumbnailData,
      Uint8List? voiceNoteData,
      List<String>? tagNames,
    })> items,
    required int childId,
  }) async {
    final baseDate = DateTime.now();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await createArtwork(
        title: item.title,
        caption: item.caption,
        imageData: item.imageData,
        thumbnailData: item.thumbnailData,
        voiceNoteData: item.voiceNoteData,
        createdAt: baseDate.add(Duration(seconds: i)),
        childId: childId,
        tagNames: item.tagNames,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Artworks (Update)
  // ---------------------------------------------------------------------------

  /// Updates an artwork in local DB and asynchronously syncs to Firestore.
  Future<void> updateArtwork(
    Artwork artwork, {
    String? title,
    String? caption,
    Uint8List? imageData,
    Uint8List? voiceNoteData,
    bool? isFavorited,
    List<String>? tagNames,
  }) async {
    final updated = artwork.copyWith(
      title: title ?? artwork.title,
      caption: caption ?? artwork.caption,
      imageData: imageData != null ? Value(imageData) : const Value.absent(),
      voiceNoteData: voiceNoteData != null
          ? Value(voiceNoteData)
          : const Value.absent(),
      isFavorited: isFavorited ?? artwork.isFavorited,
    );

    // 1. Update in Drift DB
    await db.artworkDao.updateArtwork(updated);

    // 2. Update tags if provided
    if (tagNames != null) {
      final existingTags = await db.tagDao.getTagsForArtwork(artwork.id);
      final existingNames = existingTags.map((t) => t.name).toSet();
      final newNames = tagNames.toSet();

      // Remove tags no longer present
      for (final tag in existingTags) {
        if (!newNames.contains(tag.name)) {
          await db.tagDao.removeTagFromArtwork(artwork.id, tag.id);
        }
      }
      // Add new tags
      for (final name in newNames) {
        if (!existingNames.contains(name)) {
          final tagId = await db.tagDao.getOrCreateTag(name);
          await db.tagDao.addTagToArtwork(artwork.id, tagId);
        }
      }
    }

    // 3. Async: update in Firestore
    final uid = _userId;
    if (uid != null && artwork.firestoreId != null) {
      final parts = artwork.firestoreId!.split('/');
      final childDocId = parts[3];
      final artworkDocId = parts[5];
      localWriteIds.add(artworkDocId);

      // Fetch current tags for Firestore
      final currentTags = await db.tagDao.getTagsForArtwork(artwork.id);
      _updateArtworkInFirestore(
        uid: uid,
        childDocId: childDocId,
        artworkDocId: artworkDocId,
        title: title,
        caption: caption,
        imageData: imageData,
        voiceNoteData: voiceNoteData,
        isFavorited: isFavorited,
        localId: artwork.id,
        tagNames: currentTags.map((t) => t.name).toList(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Artworks (Delete)
  // ---------------------------------------------------------------------------

  /// Deletes an artwork from local DB and Firestore.
  Future<void> deleteArtwork(int artworkId) async {
    final artwork = await db.artworkDao.getArtworkById(artworkId);
    if (artwork == null) return;

    final uid = _userId;

    // Track for echo suppression
    if (artwork.firestoreId != null) {
      final parts = artwork.firestoreId!.split('/');
      localWriteIds.add(parts[5]);
    }

    // 1. Delete from Drift DB
    await db.artworkDao.deleteArtwork(artworkId);

    // 2. Async: delete from Firestore + Storage
    if (uid != null && artwork.firestoreId != null) {
      final parts = artwork.firestoreId!.split('/');
      _deleteArtworkFromFirestore(
        uid: uid,
        childDocId: parts[3],
        artworkDocId: parts[5],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Sharing
  // ---------------------------------------------------------------------------

  /// Creates a share document for a child. Returns the share ID.
  Future<String> shareChild(int childId) async {
    final uid = _userId;
    if (uid == null) {
      throw FirestoreError.notAuthenticated;
    }

    final child = await db.childDao.getChildById(childId);
    if (child == null) {
      throw FirestoreError.syncFailed;
    }

    // Ensure child is synced to Firestore first
    if (child.firestoreId == null) {
      final childDocId = _uuid.v4();
      final firestoreId = 'users/$uid/children/$childDocId';
      await _syncChildToFirestore(
        uid: uid,
        childDocId: childDocId,
        name: child.name,
        avatarColor: child.avatarColor,
        avatarImageData: child.avatarImageData,
        createdAt: child.createdAt,
      );
      final updated = child.copyWith(firestoreId: Value(firestoreId));
      await db.childDao.updateChild(updated);
    }

    final childDocId = _extractDocId(child.firestoreId!);
    final childPath = 'users/$uid/children/$childDocId';

    final shareRef = _firestore.collection('shares').doc();
    await shareRef.set({
      'ownerUserId': uid,
      'childId': childDocId,
      'childPath': childPath,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mark child as shared locally
    final updatedChild = child.copyWith(isShared: true);
    await db.childDao.updateChild(updatedChild);

    return shareRef.id;
  }

  /// Adds the current user as a participant of a share.
  Future<void> acceptShare(String shareId) async {
    final uid = _userId;
    if (uid == null) throw FirestoreError.notAuthenticated;

    await _firestore
        .doc('shares/$shareId/participants/$uid')
        .set({
      'userId': uid,
      'role': 'viewer',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Revokes a share by setting its status to "revoked".
  Future<void> stopSharing(String shareId) async {
    final uid = _userId;
    if (uid == null) throw FirestoreError.notAuthenticated;

    await _firestore.doc('shares/$shareId').update({
      'status': 'revoked',
      'revokedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes the current user from a share's participants.
  Future<void> leaveShare(String shareId) async {
    final uid = _userId;
    if (uid == null) throw FirestoreError.notAuthenticated;

    await _firestore
        .doc('shares/$shareId/participants/$uid')
        .delete();
  }

  /// Fetches all participants for a share.
  Future<List<ShareParticipant>> fetchParticipants(String shareId) async {
    final snapshot = await _firestore
        .collection('shares/$shareId/participants')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ShareParticipant(
        userId: data['userId'] as String? ?? doc.id,
        role: data['role'] as String? ?? 'viewer',
        acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  /// Finds an active share for a given child Firestore ID.
  Future<ShareInfo?> findShare(String childFirestoreId) async {
    final childDocId = _extractDocId(childFirestoreId);
    final snapshot = await _firestore
        .collection('shares')
        .where('childId', isEqualTo: childDocId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return ShareInfo(
      shareId: doc.id,
      status: doc.data()['status'] as String? ?? 'active',
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Bulk Operations
  // ---------------------------------------------------------------------------

  /// Uploads all local data that hasn't been synced to Firestore yet.
  Future<void> uploadAllLocalData() async {
    final uid = _userId;
    if (uid == null) return;

    if (isUploadingAll) return;
    isUploadingAll = true;

    try {
      // Get all children (watch returns a stream, so we use a direct query approach)
      final allChildren = await db.childDao.watchAllChildren().first;

      for (final child in allChildren) {
        String childDocId;

        if (child.firestoreId == null) {
          // Check if a matching child already exists in Firestore
          final existingDocId = await _findExistingFirestoreChild(
            uid: uid,
            name: child.name,
          );

          if (existingDocId != null) {
            childDocId = existingDocId;
          } else {
            childDocId = _uuid.v4();
            await _syncChildToFirestore(
              uid: uid,
              childDocId: childDocId,
              name: child.name,
              avatarColor: child.avatarColor,
              avatarImageData: child.avatarImageData,
              createdAt: child.createdAt,
            );
          }

          // Update local row with firestoreId
          final firestoreId = 'users/$uid/children/$childDocId';
          final updated = child.copyWith(
            firestoreId: Value(firestoreId),
            ownerUserId: Value(uid),
          );
          await db.childDao.updateChild(updated);
        } else {
          childDocId = _extractDocId(child.firestoreId!);
        }

        // Upload all artworks for this child
        final artworks = await db.artworkDao
            .watchArtworksByChild(child.id)
            .first;

        for (final artwork in artworks) {
          if (artwork.firestoreId != null) continue;

          final artworkDocId = _uuid.v4();
          final tags = await db.tagDao.getTagsForArtwork(artwork.id);

          await _syncArtworkToFirestore(
            uid: uid,
            childDocId: childDocId,
            artworkDocId: artworkDocId,
            title: artwork.title,
            caption: artwork.caption,
            imageData: artwork.imageData,
            voiceNoteData: artwork.voiceNoteData,
            isFavorited: artwork.isFavorited,
            createdAt: artwork.createdAt,
            localId: artwork.id,
            tagNames: tags.map((t) => t.name).toList(),
          );

          // Update local row with firestoreId and URLs
          final artworkFirestoreId =
              'users/$uid/children/$childDocId/artworks/$artworkDocId';
          final updated = artwork.copyWith(
            firestoreId: Value(artworkFirestoreId),
          );
          await db.artworkDao.updateArtwork(updated);
        }
      }
    } catch (e) {
      debugPrint('FirestoreRepository: uploadAllLocalData failed – $e');
    } finally {
      isUploadingAll = false;
    }
  }

  /// Deletes all user data from Firestore and clears the local DB.
  Future<void> deleteAllUserData(String userId) async {
    try {
      // Delete all children and their artworks from Firestore
      final childrenSnap = await _firestore
          .collection('users/$userId/children')
          .get();

      for (final childDoc in childrenSnap.docs) {
        // Delete all artworks under this child
        final artworksSnap = await _firestore
            .collection('users/$userId/children/${childDoc.id}/artworks')
            .get();

        for (final artworkDoc in artworksSnap.docs) {
          // Delete storage files
          try {
            await storageService.delete(
              StorageService.artworkImagePath(userId, childDoc.id, artworkDoc.id),
            );
          } catch (_) {}
          try {
            await storageService.delete(
              StorageService.voiceNotePath(userId, childDoc.id, artworkDoc.id),
            );
          } catch (_) {}

          await artworkDoc.reference.delete();
        }

        // Delete avatar from storage
        try {
          await storageService.delete(
            StorageService.avatarPath(userId, childDoc.id),
          );
        } catch (_) {}

        await childDoc.reference.delete();
      }

      // Delete preferences
      try {
        await _firestore.doc('users/$userId/meta/preferences').delete();
      } catch (_) {}

      // Delete shares owned by this user
      final sharesSnap = await _firestore
          .collection('shares')
          .where('ownerUserId', isEqualTo: userId)
          .get();

      for (final shareDoc in sharesSnap.docs) {
        // Delete participants subcollection
        final participantsSnap = await _firestore
            .collection('shares/${shareDoc.id}/participants')
            .get();
        for (final pDoc in participantsSnap.docs) {
          await pDoc.reference.delete();
        }
        await shareDoc.reference.delete();
      }

      // Delete user document
      try {
        await _firestore.doc('users/$userId').delete();
      } catch (_) {}

      // Clear local DB — delete all children (cascade deletes artworks)
      final localChildren = await db.childDao.watchAllChildren().first;
      for (final child in localChildren) {
        await db.childDao.deleteChild(child.id);
      }
    } catch (e) {
      debugPrint('FirestoreRepository: deleteAllUserData failed – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Public Helpers (used by sync service)
  // ---------------------------------------------------------------------------

  /// Deletes a Firestore child doc that has no local counterpart.
  Future<void> deleteOrphanedFirestoreChild({
    required String uid,
    required String childDocId,
  }) async {
    try {
      // Delete all artworks under this child
      final artworksSnap = await _firestore
          .collection('users/$uid/children/$childDocId/artworks')
          .get();

      for (final artworkDoc in artworksSnap.docs) {
        try {
          await storageService.delete(
            StorageService.artworkImagePath(uid, childDocId, artworkDoc.id),
          );
        } catch (_) {}
        try {
          await storageService.delete(
            StorageService.voiceNotePath(uid, childDocId, artworkDoc.id),
          );
        } catch (_) {}
        await artworkDoc.reference.delete();
      }

      // Delete avatar
      try {
        await storageService.delete(
          StorageService.avatarPath(uid, childDocId),
        );
      } catch (_) {}

      // Delete child doc
      await _firestore.doc('users/$uid/children/$childDocId').delete();
    } catch (e) {
      debugPrint(
        'FirestoreRepository: deleteOrphanedFirestoreChild failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Sync Child to Firestore
  // ---------------------------------------------------------------------------

  Future<void> _syncChildToFirestore({
    required String uid,
    required String childDocId,
    required String name,
    required String avatarColor,
    Uint8List? avatarImageData,
    required DateTime createdAt,
  }) async {
    try {
      String? avatarURL;

      // Upload avatar if present
      if (avatarImageData != null) {
        final path = StorageService.avatarPath(uid, childDocId);
        avatarURL = await storageService.uploadWithRetry(avatarImageData, path);
      }

      final data = <String, dynamic>{
        'name': name,
        'avatarColor': avatarColor,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'avatarURL': ?avatarURL,
      };

      await _firestore
          .doc('users/$uid/children/$childDocId')
          .set(data);
    } catch (e) {
      debugPrint('FirestoreRepository: _syncChildToFirestore failed – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Update Child in Firestore
  // ---------------------------------------------------------------------------

  Future<void> _updateChildInFirestore({
    required String uid,
    required String childDocId,
    String? name,
    String? avatarColor,
    Uint8List? avatarImageData,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) data['name'] = name;
      if (avatarColor != null) data['avatarColor'] = avatarColor;

      // Re-upload avatar if changed
      if (avatarImageData != null) {
        final path = StorageService.avatarPath(uid, childDocId);
        final avatarURL =
            await storageService.uploadWithRetry(avatarImageData, path);
        if (avatarURL != null) data['avatarURL'] = avatarURL;
      }

      await _firestore
          .doc('users/$uid/children/$childDocId')
          .update(data);
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _updateChildInFirestore failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Delete Child from Firestore
  // ---------------------------------------------------------------------------

  Future<void> _deleteChildFromFirestore({
    required String uid,
    required String childDocId,
  }) async {
    try {
      // Delete all artworks under this child
      final artworksSnap = await _firestore
          .collection('users/$uid/children/$childDocId/artworks')
          .get();

      for (final artworkDoc in artworksSnap.docs) {
        try {
          await storageService.delete(
            StorageService.artworkImagePath(uid, childDocId, artworkDoc.id),
          );
        } catch (_) {}
        try {
          await storageService.delete(
            StorageService.voiceNotePath(uid, childDocId, artworkDoc.id),
          );
        } catch (_) {}
        await artworkDoc.reference.delete();
      }

      // Delete avatar from storage
      try {
        await storageService.delete(
          StorageService.avatarPath(uid, childDocId),
        );
      } catch (_) {}

      // Delete child document
      await _firestore.doc('users/$uid/children/$childDocId').delete();
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _deleteChildFromFirestore failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Sync Artwork to Firestore
  // ---------------------------------------------------------------------------

  Future<void> _syncArtworkToFirestore({
    required String uid,
    required String childDocId,
    required String artworkDocId,
    required String title,
    required String caption,
    Uint8List? imageData,
    Uint8List? voiceNoteData,
    required bool isFavorited,
    required DateTime createdAt,
    required int localId,
    List<String>? tagNames,
  }) async {
    try {
      String? imageURL;
      String? voiceNoteURL;

      // Upload image
      if (imageData != null) {
        final path = StorageService.artworkImagePath(uid, childDocId, artworkDocId);
        imageURL = await storageService.uploadWithRetry(imageData, path);
      }

      // Upload voice note
      if (voiceNoteData != null) {
        final path = StorageService.voiceNotePath(uid, childDocId, artworkDocId);
        voiceNoteURL = await storageService.uploadWithRetry(
          voiceNoteData,
          path,
          contentType: 'audio/m4a',
        );
      }

      final data = <String, dynamic>{
        'title': title,
        'caption': caption,
        'isFavorited': isFavorited,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageURL': ?imageURL,
        'voiceNoteURL': ?voiceNoteURL,
        if (tagNames != null && tagNames.isNotEmpty) 'tags': tagNames,
      };

      await _firestore
          .doc('users/$uid/children/$childDocId/artworks/$artworkDocId')
          .set(data);

      // Update local row with URLs if available
      if (imageURL != null || voiceNoteURL != null) {
        final artwork = await db.artworkDao.getArtworkById(localId);
        if (artwork != null) {
          final updated = artwork.copyWith(
            imageURL: imageURL != null ? Value(imageURL) : const Value.absent(),
            voiceNoteURL: voiceNoteURL != null
                ? Value(voiceNoteURL)
                : const Value.absent(),
          );
          await db.artworkDao.updateArtwork(updated);
        }
      }
    } catch (e) {
      debugPrint('FirestoreRepository: _syncArtworkToFirestore failed – $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Update Artwork in Firestore
  // ---------------------------------------------------------------------------

  Future<void> _updateArtworkInFirestore({
    required String uid,
    required String childDocId,
    required String artworkDocId,
    String? title,
    String? caption,
    Uint8List? imageData,
    Uint8List? voiceNoteData,
    bool? isFavorited,
    required int localId,
    List<String>? tagNames,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) data['title'] = title;
      if (caption != null) data['caption'] = caption;
      if (isFavorited != null) data['isFavorited'] = isFavorited;
      if (tagNames != null) data['tags'] = tagNames;

      // Re-upload image if changed
      if (imageData != null) {
        final path =
            StorageService.artworkImagePath(uid, childDocId, artworkDocId);
        final imageURL =
            await storageService.uploadWithRetry(imageData, path);
        if (imageURL != null) {
          data['imageURL'] = imageURL;
          // Update local URL
          final artwork = await db.artworkDao.getArtworkById(localId);
          if (artwork != null) {
            final updated = artwork.copyWith(imageURL: Value(imageURL));
            await db.artworkDao.updateArtwork(updated);
          }
        }
      }

      // Re-upload voice note if changed
      if (voiceNoteData != null) {
        final path =
            StorageService.voiceNotePath(uid, childDocId, artworkDocId);
        final voiceNoteURL = await storageService.uploadWithRetry(
          voiceNoteData,
          path,
          contentType: 'audio/m4a',
        );
        if (voiceNoteURL != null) {
          data['voiceNoteURL'] = voiceNoteURL;
          final artwork = await db.artworkDao.getArtworkById(localId);
          if (artwork != null) {
            final updated = artwork.copyWith(voiceNoteURL: Value(voiceNoteURL));
            await db.artworkDao.updateArtwork(updated);
          }
        }
      }

      await _firestore
          .doc('users/$uid/children/$childDocId/artworks/$artworkDocId')
          .update(data);
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _updateArtworkInFirestore failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Delete Artwork from Firestore
  // ---------------------------------------------------------------------------

  Future<void> _deleteArtworkFromFirestore({
    required String uid,
    required String childDocId,
    required String artworkDocId,
  }) async {
    try {
      // Delete storage files
      try {
        await storageService.delete(
          StorageService.artworkImagePath(uid, childDocId, artworkDocId),
        );
      } catch (_) {}
      try {
        await storageService.delete(
          StorageService.voiceNotePath(uid, childDocId, artworkDocId),
        );
      } catch (_) {}

      // Delete Firestore document
      await _firestore
          .doc('users/$uid/children/$childDocId/artworks/$artworkDocId')
          .delete();
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _deleteArtworkFromFirestore failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Find Existing Firestore Child
  // ---------------------------------------------------------------------------

  Future<String?> _findExistingFirestoreChild({
    required String uid,
    required String name,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users/$uid/children')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _findExistingFirestoreChild failed – $e',
      );
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Delete Orphaned Storage
  // ---------------------------------------------------------------------------

  // ignore: unused_element
  Future<void> _deleteOrphanedStorage({
    required String uid,
    required String childDocId,
    String? artworkDocId,
  }) async {
    try {
      if (artworkDocId != null) {
        await storageService.delete(
          StorageService.artworkImagePath(uid, childDocId, artworkDocId),
        );
        await storageService.delete(
          StorageService.voiceNotePath(uid, childDocId, artworkDocId),
        );
      } else {
        await storageService.delete(
          StorageService.avatarPath(uid, childDocId),
        );
      }
    } catch (e) {
      debugPrint(
        'FirestoreRepository: _deleteOrphanedStorage failed – $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Private: Extract Doc ID
  // ---------------------------------------------------------------------------

  /// Extracts the last path component from a full Firestore path.
  /// e.g. "users/abc/children/xyz" -> "xyz"
  String _extractDocId(String firestoreId) {
    return firestoreId.split('/').last;
  }
}
