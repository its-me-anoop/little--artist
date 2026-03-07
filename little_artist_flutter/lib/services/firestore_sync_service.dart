import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/database.dart';
import 'firebase_auth_service.dart';
import 'firestore_repository.dart';
import 'image_processing_service.dart';
import 'storage_service.dart';

// ---------------------------------------------------------------------------
// MARK: - Firestore Sync Service
// ---------------------------------------------------------------------------

/// Listens to Firestore snapshot changes and reconciles them into the local
/// Drift database. This is the READ path of Firebase sync — the counterpart
/// to [FirestoreRepository] (write path).
class FirestoreSyncService {
  final AppDatabase db;
  final FirestoreRepository repository;
  final StorageService storageService;
  final FirebaseAuthService authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isListening = false;
  DateTime? lastSyncDate;
  final List<String> diagnosticLog = [];

  // Listener registrations
  StreamSubscription<QuerySnapshot>? _childrenListener;
  StreamSubscription<QuerySnapshot>? _sharesListener;
  StreamSubscription<DocumentSnapshot>? _preferencesListener;
  final Map<String, StreamSubscription<QuerySnapshot>> _artworkListeners = {};
  final Map<String, StreamSubscription<QuerySnapshot>>
  _sharedChildrenListeners = {};
  final Map<String, String> _activeShareChildMap = {};
  bool _hasProcessedInitialChildrenSnapshot = false;

  FirestoreSyncService({
    required this.db,
    required this.repository,
    required this.storageService,
    required this.authService,
  });

  // ---------------------------------------------------------------------------
  // MARK: - Lifecycle
  // ---------------------------------------------------------------------------

  /// Begins all listeners if userId is available and not already listening.
  void start() {
    final userId = authService.userId;
    if (userId == null) {
      diag('start: no userId available, skipping');
      return;
    }
    if (isListening) {
      diag('start: already listening, skipping');
      return;
    }

    diag('start: beginning listeners for user $userId');
    isListening = true;
    _hasProcessedInitialChildrenSnapshot = false;

    _listenToPreferences(userId);
    _listenToChildren(userId);
    _listenToShares(userId);
  }

  /// Cancels all subscriptions and clears listener maps.
  Future<void> stop() async {
    diag('stop: cancelling all subscriptions');
    isListening = false;

    await _childrenListener?.cancel();
    _childrenListener = null;

    await _sharesListener?.cancel();
    _sharesListener = null;

    await _preferencesListener?.cancel();
    _preferencesListener = null;

    for (final sub in _artworkListeners.values) {
      await sub.cancel();
    }
    _artworkListeners.clear();

    for (final sub in _sharedChildrenListeners.values) {
      await sub.cancel();
    }
    _sharedChildrenListeners.clear();
    _activeShareChildMap.clear();
    _hasProcessedInitialChildrenSnapshot = false;
  }

  // ---------------------------------------------------------------------------
  // MARK: - Preferences Listener
  // ---------------------------------------------------------------------------

  void _listenToPreferences(String userId) {
    final docRef = _firestore.doc('users/$userId/meta/preferences');

    _preferencesListener = docRef.snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data == null) return;

        try {
          final prefs = await SharedPreferences.getInstance();

          if (data.containsKey('hasCompletedOnboarding')) {
            await prefs.setBool(
              'hasCompletedOnboarding',
              data['hasCompletedOnboarding'] as bool? ?? false,
            );
          }

          if (data.containsKey('aiCaptionsEnabled')) {
            await prefs.setBool(
              'aiCaptionsEnabled',
              data['aiCaptionsEnabled'] as bool? ?? true,
            );
          }

          if (data.containsKey('defaultCameraBack')) {
            await prefs.setBool(
              'defaultCameraBack',
              data['defaultCameraBack'] as bool? ?? true,
            );
          }

          if (data.containsKey('notificationsEnabled')) {
            await prefs.setBool(
              'notificationsEnabled',
              data['notificationsEnabled'] as bool? ?? false,
            );
          }

          if (data.containsKey('selectedChildId') &&
              data['selectedChildId'] != null) {
            await prefs.setInt(
              'selectedChildId',
              data['selectedChildId'] as int,
            );
          }

          diag('preferences: synced from Firestore');
        } catch (e) {
          diag('preferences: sync failed - $e');
        }
      },
      onError: (Object e) {
        diag('preferences: listener error - $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Children Listener
  // ---------------------------------------------------------------------------

  void _listenToChildren(String userId) {
    final collectionRef = _firestore.collection('users/$userId/children');

    _childrenListener = collectionRef.snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final docId = change.doc.id;

          // Echo suppression: skip docs we wrote locally
          if (repository.localWriteIds.contains(docId)) {
            repository.localWriteIds.remove(docId);
            diag('children: skipping echo for $docId');
            continue;
          }

          final firestoreId = 'users/$userId/children/$docId';

          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await _upsertChild(change.doc, firestoreId, false, userId);
              // Attach artwork listener for this child
              if (!_artworkListeners.containsKey(docId)) {
                _listenToArtworks(userId, docId, firestoreId);
              }
            case DocumentChangeType.removed:
              await _removeChild(firestoreId);
              // Cancel artwork listener for this child
              await _artworkListeners[docId]?.cancel();
              _artworkListeners.remove(docId);
          }
        }

        // Run one-time deduplication after initial snapshot
        if (!_hasProcessedInitialChildrenSnapshot) {
          _hasProcessedInitialChildrenSnapshot = true;
          await _deduplicateChildren();
        }

        lastSyncDate = DateTime.now();
      },
      onError: (Object e) {
        diag('children: listener error - $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Artworks Listener
  // ---------------------------------------------------------------------------

  void _listenToArtworks(
    String userId,
    String childDocId,
    String childFirestoreId,
  ) {
    final collectionRef = _firestore.collection(
      'users/$userId/children/$childDocId/artworks',
    );

    _artworkListeners[childDocId] = collectionRef.snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final docId = change.doc.id;

          // Echo suppression
          if (repository.localWriteIds.contains(docId)) {
            repository.localWriteIds.remove(docId);
            diag('artworks: skipping echo for $docId');
            continue;
          }

          final firestoreId =
              'users/$userId/children/$childDocId/artworks/$docId';

          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await _upsertArtwork(change.doc, firestoreId, childFirestoreId);
            case DocumentChangeType.removed:
              await _removeArtwork(firestoreId);
          }
        }
      },
      onError: (Object e) {
        diag('artworks[$childDocId]: listener error - $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Shares Listener
  // ---------------------------------------------------------------------------

  void _listenToShares(String userId) {
    final query = _firestore
        .collection('shares')
        .where('status', isEqualTo: 'active');

    _sharesListener = query.snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final shareId = change.doc.id;
          final ownerUserId = data['ownerUserId'] as String?;
          final childId = data['childId'] as String?;

          if (ownerUserId == null || childId == null) continue;

          // Skip shares we own
          if (ownerUserId == userId) continue;

          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await _checkAndListenToSharedChild(
                shareId,
                ownerUserId,
                childId,
                userId,
              );
            case DocumentChangeType.removed:
              final childFirestoreId = 'users/$ownerUserId/children/$childId';
              await _removeSharedChild(childFirestoreId, shareId);
          }
        }
      },
      onError: (Object e) {
        diag('shares: listener error - $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Shared Child Listener
  // ---------------------------------------------------------------------------

  Future<void> _checkAndListenToSharedChild(
    String shareId,
    String ownerUserId,
    String childId,
    String currentUserId,
  ) async {
    // Check if the current user is a participant of this share
    try {
      final participantDoc = await _firestore
          .doc('shares/$shareId/participants/$currentUserId')
          .get();

      if (!participantDoc.exists) {
        diag('shares: not a participant of $shareId, skipping');
        return;
      }
    } catch (e) {
      diag('shares: failed to check participant status for $shareId - $e');
      return;
    }

    final childFirestoreId = 'users/$ownerUserId/children/$childId';
    _activeShareChildMap[shareId] = childFirestoreId;

    // Skip if already listening
    if (_sharedChildrenListeners.containsKey(childFirestoreId)) {
      diag('shares: already listening to shared child $childFirestoreId');
      return;
    }

    diag('shares: starting listener for shared child $childFirestoreId');

    // Listen to the shared child document via a collection query on the parent
    // that filters to only this child's doc changes.
    final childDocRef = _firestore.doc('users/$ownerUserId/children/$childId');

    // Listen to the child doc itself using a wrapper query
    // We use the parent collection with a single-doc approach
    final childCollectionRef = _firestore.collection(
      'users/$ownerUserId/children',
    );

    _sharedChildrenListeners[childFirestoreId] = childCollectionRef
        .snapshots()
        .listen(
          (snapshot) async {
            for (final change in snapshot.docChanges) {
              if (change.doc.id != childId) continue;

              final fid = 'users/$ownerUserId/children/${change.doc.id}';

              switch (change.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  await _upsertChild(change.doc, fid, true, ownerUserId);
                case DocumentChangeType.removed:
                  await _removeChild(fid);
              }
            }
          },
          onError: (Object e) {
            diag('sharedChild[$childFirestoreId]: listener error - $e');
          },
        );

    // Also fetch the child doc once to bootstrap
    try {
      final childSnap = await childDocRef.get();
      if (childSnap.exists) {
        await _upsertChild(childSnap, childFirestoreId, true, ownerUserId);
      }
    } catch (e) {
      diag('shares: initial fetch of shared child failed - $e');
    }

    // Listen to shared child's artworks
    if (!_artworkListeners.containsKey('shared_$childId')) {
      final artworksRef = _firestore.collection(
        'users/$ownerUserId/children/$childId/artworks',
      );

      _artworkListeners['shared_$childId'] = artworksRef.snapshots().listen(
        (snapshot) async {
          for (final change in snapshot.docChanges) {
            final docId = change.doc.id;
            final artworkFid =
                'users/$ownerUserId/children/$childId/artworks/$docId';

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _upsertArtwork(change.doc, artworkFid, childFirestoreId);
              case DocumentChangeType.removed:
                await _removeArtwork(artworkFid);
            }
          }
        },
        onError: (Object e) {
          diag('sharedArtworks[$childId]: listener error - $e');
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Upsert Child
  // ---------------------------------------------------------------------------

  Future<void> _upsertChild(
    DocumentSnapshot doc,
    String firestoreId,
    bool isShared,
    String? ownerUserId,
  ) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    try {
      final name = data['name'] as String? ?? '';
      final avatarColor = data['avatarColor'] as String? ?? 'F2784B';
      final avatarURL = data['avatarURL'] as String?;
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Download avatar if URL is present
      Uint8List? avatarImageData;
      if (avatarURL != null && avatarURL.isNotEmpty) {
        avatarImageData = await storageService.downloadUrl(avatarURL);
      }

      // Check for existing child by firestoreId
      final existing = await db.childDao.getChildByFirestoreId(firestoreId);

      if (existing != null) {
        // Update existing child
        final updated = existing.copyWith(
          name: name,
          avatarColor: avatarColor,
          createdAt: createdAt,
          avatarImageData: avatarImageData != null
              ? Value(avatarImageData)
              : const Value.absent(),
          isShared: isShared,
          ownerUserId: ownerUserId != null
              ? Value(ownerUserId)
              : const Value.absent(),
        );
        await db.childDao.updateChild(updated);
        diag('upsertChild: updated ${existing.id} ($name)');
      } else {
        // Try to adopt an orphaned local child (null firestoreId + same name)
        final allChildren = await db.childDao.watchAllChildren().first;
        Child? orphan;
        for (final child in allChildren) {
          if (child.firestoreId == null &&
              child.name.trim().toLowerCase() == name.trim().toLowerCase()) {
            orphan = child;
            break;
          }
        }

        if (orphan != null) {
          // Adopt the orphaned child by setting its firestoreId
          final updated = orphan.copyWith(
            name: name,
            avatarColor: avatarColor,
            firestoreId: Value(firestoreId),
            isShared: isShared,
            ownerUserId: ownerUserId != null
                ? Value(ownerUserId)
                : const Value.absent(),
            avatarImageData: avatarImageData != null
                ? Value(avatarImageData)
                : const Value.absent(),
          );
          await db.childDao.updateChild(updated);
          diag('upsertChild: adopted orphan ${orphan.id} ($name)');
        } else {
          // Insert new child
          await db.childDao.insertChild(
            ChildrenCompanion(
              name: Value(name),
              avatarColor: Value(avatarColor),
              createdAt: Value(createdAt),
              avatarImageData: avatarImageData != null
                  ? Value(avatarImageData)
                  : const Value.absent(),
              firestoreId: Value(firestoreId),
              isShared: Value(isShared),
              ownerUserId: ownerUserId != null
                  ? Value(ownerUserId)
                  : const Value.absent(),
            ),
          );
          diag('upsertChild: inserted new child ($name)');
        }
      }
    } catch (e) {
      diag('upsertChild: failed for $firestoreId - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Remove Child
  // ---------------------------------------------------------------------------

  Future<void> _removeChild(String firestoreId) async {
    try {
      final existing = await db.childDao.getChildByFirestoreId(firestoreId);
      if (existing != null) {
        await db.childDao.deleteChild(existing.id);
        diag('removeChild: deleted ${existing.id} (${existing.name})');
      } else {
        diag('removeChild: no local child found for $firestoreId');
      }
    } catch (e) {
      diag('removeChild: failed for $firestoreId - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Upsert Artwork
  // ---------------------------------------------------------------------------

  Future<void> _upsertArtwork(
    DocumentSnapshot doc,
    String firestoreId,
    String childFirestoreId,
  ) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    try {
      final title = data['title'] as String? ?? '';
      final caption = data['caption'] as String? ?? '';
      final isFavorited = data['isFavorited'] as bool? ?? false;
      final imageURL = data['imageURL'] as String?;
      final voiceNoteURL = data['voiceNoteURL'] as String?;
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final tagNames =
          (data['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [];

      // Download image and generate thumbnail
      Uint8List? imageData;
      Uint8List? thumbnailData;
      if (imageURL != null && imageURL.isNotEmpty) {
        imageData = await storageService.downloadUrl(imageURL);
        if (imageData != null) {
          thumbnailData = await ImageProcessingService().generateThumbnail(
            imageData,
          );
        }
      }

      // Download voice note
      Uint8List? voiceNoteData;
      if (voiceNoteURL != null && voiceNoteURL.isNotEmpty) {
        voiceNoteData = await storageService.downloadUrl(voiceNoteURL);
      }

      // Find parent child by firestoreId
      final parentChild = await db.childDao.getChildByFirestoreId(
        childFirestoreId,
      );
      if (parentChild == null) {
        diag('upsertArtwork: parent child not found for $childFirestoreId');
        return;
      }

      // Handle tags
      final tagIds = <int>[];
      for (final tagName in tagNames) {
        final tagId = await db.tagDao.getOrCreateTag(tagName);
        tagIds.add(tagId);
      }

      // Check for existing artwork by firestoreId
      final existing = await db.artworkDao.getArtworkByFirestoreId(firestoreId);

      if (existing != null) {
        // Update existing artwork
        final updated = existing.copyWith(
          title: title,
          caption: caption,
          isFavorited: isFavorited,
          createdAt: createdAt,
          childId: Value(parentChild.id),
          imageData: imageData != null
              ? Value(imageData)
              : const Value.absent(),
          thumbnailData: thumbnailData != null
              ? Value(thumbnailData)
              : const Value.absent(),
          voiceNoteData: voiceNoteData != null
              ? Value(voiceNoteData)
              : const Value.absent(),
          imageURL: imageURL != null ? Value(imageURL) : const Value.absent(),
          voiceNoteURL: voiceNoteURL != null
              ? Value(voiceNoteURL)
              : const Value.absent(),
        );
        await db.artworkDao.updateArtwork(updated);

        // Update tags: remove old, add new
        final existingTags = await db.tagDao.getTagsForArtwork(existing.id);
        for (final tag in existingTags) {
          await db.tagDao.removeTagFromArtwork(existing.id, tag.id);
        }
        for (final tagId in tagIds) {
          await db.tagDao.addTagToArtwork(existing.id, tagId);
        }

        diag('upsertArtwork: updated ${existing.id} ($title)');
      } else {
        // Insert new artwork
        final localId = await db.artworkDao.insertArtwork(
          ArtworksCompanion(
            title: Value(title),
            caption: Value(caption),
            isFavorited: Value(isFavorited),
            createdAt: Value(createdAt),
            childId: Value(parentChild.id),
            firestoreId: Value(firestoreId),
            imageData: imageData != null
                ? Value(imageData)
                : const Value.absent(),
            thumbnailData: thumbnailData != null
                ? Value(thumbnailData)
                : const Value.absent(),
            voiceNoteData: voiceNoteData != null
                ? Value(voiceNoteData)
                : const Value.absent(),
            imageURL: imageURL != null ? Value(imageURL) : const Value.absent(),
            voiceNoteURL: voiceNoteURL != null
                ? Value(voiceNoteURL)
                : const Value.absent(),
          ),
        );

        // Add tags to the new artwork
        for (final tagId in tagIds) {
          await db.tagDao.addTagToArtwork(localId, tagId);
        }

        diag('upsertArtwork: inserted $localId ($title)');
      }
    } catch (e) {
      diag('upsertArtwork: failed for $firestoreId - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Remove Artwork
  // ---------------------------------------------------------------------------

  Future<void> _removeArtwork(String firestoreId) async {
    try {
      final existing = await db.artworkDao.getArtworkByFirestoreId(firestoreId);
      if (existing != null) {
        await db.artworkDao.deleteArtwork(existing.id);
        diag('removeArtwork: deleted ${existing.id} (${existing.title})');
      } else {
        diag('removeArtwork: no local artwork found for $firestoreId');
      }
    } catch (e) {
      diag('removeArtwork: failed for $firestoreId - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Remove Shared Child
  // ---------------------------------------------------------------------------

  Future<void> _removeSharedChild(
    String childFirestoreId,
    String shareId,
  ) async {
    diag('removeSharedChild: removing $childFirestoreId (share: $shareId)');

    // Cancel shared child listener
    await _sharedChildrenListeners[childFirestoreId]?.cancel();
    _sharedChildrenListeners.remove(childFirestoreId);

    // Cancel shared artwork listener
    final childDocId = childFirestoreId.split('/').last;
    await _artworkListeners['shared_$childDocId']?.cancel();
    _artworkListeners.remove('shared_$childDocId');

    // Remove from active share map
    _activeShareChildMap.remove(shareId);

    // Delete the local child
    try {
      final existing = await db.childDao.getChildByFirestoreId(
        childFirestoreId,
      );
      if (existing != null) {
        await db.childDao.deleteChild(existing.id);
        diag('removeSharedChild: deleted local child ${existing.id}');
      }
    } catch (e) {
      diag('removeSharedChild: failed - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Deduplication
  // ---------------------------------------------------------------------------

  /// Groups all children by name (case-insensitive, trimmed). For each group
  /// with duplicates, keeps the child with the most artworks (tie-break by
  /// earliest creation date), reassigns artworks from duplicates to the
  /// winner, and deletes the duplicate Firestore docs.
  Future<void> _deduplicateChildren() async {
    try {
      final allChildren = await db.childDao.watchAllChildren().first;
      if (allChildren.isEmpty) return;

      // Group by normalized name
      final groups = <String, List<Child>>{};
      for (final child in allChildren) {
        final key = child.name.trim().toLowerCase();
        groups.putIfAbsent(key, () => []).add(child);
      }

      for (final entry in groups.entries) {
        final group = entry.value;
        if (group.length <= 1) continue;

        diag('dedup: found ${group.length} children named "${entry.key}"');

        // Count artworks for each child
        final counts = <int, int>{};
        for (final child in group) {
          counts[child.id] = await db.artworkDao.getArtworkCountForChild(
            child.id,
          );
        }

        // Sort: most artworks first, then earliest createdAt
        group.sort((a, b) {
          final countDiff = (counts[b.id] ?? 0) - (counts[a.id] ?? 0);
          if (countDiff != 0) return countDiff;
          return a.createdAt.compareTo(b.createdAt);
        });

        final winner = group.first;
        final losers = group.sublist(1);

        for (final loser in losers) {
          // Reassign artworks from loser to winner
          final loserArtworks = await db.artworkDao
              .watchArtworksByChild(loser.id)
              .first;
          for (final artwork in loserArtworks) {
            final updated = artwork.copyWith(childId: Value(winner.id));
            await db.artworkDao.updateArtwork(updated);
          }

          // Delete the duplicate from Firestore
          if (loser.firestoreId != null) {
            final uid = authService.userId;
            if (uid != null) {
              final docId = loser.firestoreId!.split('/').last;
              await repository.deleteOrphanedFirestoreChild(
                uid: uid,
                childDocId: docId,
              );
            }
          }

          // Delete from local DB
          await db.childDao.deleteChild(loser.id);
          diag('dedup: merged child ${loser.id} into ${winner.id}');
        }
      }
    } catch (e) {
      diag('dedup: failed - $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Diagnostics
  // ---------------------------------------------------------------------------

  /// Appends a timestamped entry to [diagnosticLog] (max 50 entries) and
  /// prints via [debugPrint].
  void diag(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';
    diagnosticLog.add(entry);
    if (diagnosticLog.length > 50) {
      diagnosticLog.removeAt(0);
    }
    debugPrint('FirestoreSyncService: $message');
  }

  /// Returns a summary of the current sync state.
  Map<String, String> diagnosticSnapshot() {
    return {
      'isListening': isListening.toString(),
      'lastSyncDate': lastSyncDate?.toIso8601String() ?? 'never',
      'userId': authService.userId ?? 'none',
      'childrenListener': (_childrenListener != null).toString(),
      'sharesListener': (_sharesListener != null).toString(),
      'preferencesListener': (_preferencesListener != null).toString(),
      'artworkListenerCount': _artworkListeners.length.toString(),
      'sharedChildrenListenerCount': _sharedChildrenListeners.length.toString(),
      'activeShareCount': _activeShareChildMap.length.toString(),
      'diagnosticLogCount': diagnosticLog.length.toString(),
    };
  }
}
