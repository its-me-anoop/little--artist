import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage service for uploading, downloading, and deleting files
/// with retry support and path generation helpers.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const int _maxRetries = 3;
  static const int _maxDownloadSize = 20 * 1024 * 1024; // 20 MB

  // ---------------------------------------------------------------------------
  // MARK: - Upload
  // ---------------------------------------------------------------------------

  /// Uploads [data] to Firebase Storage at [path] and returns the download URL.
  ///
  /// Throws a [FirebaseException] on failure.
  Future<String> upload(
    Uint8List data,
    String path, {
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(data, metadata);
    return ref.getDownloadURL();
  }

  /// Attempts [upload] up to [_maxRetries] times with exponential backoff.
  ///
  /// Returns the download URL on success, or `null` after all retries fail.
  Future<String?> uploadWithRetry(
    Uint8List data,
    String path, {
    String contentType = 'image/jpeg',
  }) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await upload(data, path, contentType: contentType);
      } catch (e) {
        debugPrint(
          'StorageService: upload attempt $attempt/$_maxRetries failed – $e',
        );
        if (attempt < _maxRetries) {
          final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
          await Future<void>.delayed(delay);
        }
      }
    }
    debugPrint('StorageService: upload failed after $_maxRetries attempts');
    return null;
  }

  // ---------------------------------------------------------------------------
  // MARK: - Download
  // ---------------------------------------------------------------------------

  /// Downloads the file at [path] from Firebase Storage.
  ///
  /// Maximum download size is 20 MB. Throws on failure.
  Future<Uint8List> download(String path) async {
    final ref = _storage.ref(path);
    final data = await ref.getData(_maxDownloadSize);
    if (data == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        message: 'Downloaded data was null for path: $path',
      );
    }
    return data;
  }

  /// Downloads a file from a full download [url] (not a storage path).
  ///
  /// Returns the bytes on success, or `null` on failure.
  Future<Uint8List?> downloadUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getData(_maxDownloadSize);
    } catch (e) {
      debugPrint('StorageService: downloadUrl failed – $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Delete
  // ---------------------------------------------------------------------------

  /// Deletes the file at [path]. Silently ignores missing files.
  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      // object-not-found is expected when the file was already removed.
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MARK: - Path Generators
  // ---------------------------------------------------------------------------

  /// Storage path for a child's avatar image.
  static String avatarPath(String uid, String childId) =>
      'users/$uid/children/$childId/avatar.jpg';

  /// Storage path for an artwork's main image.
  static String artworkImagePath(
    String uid,
    String childId,
    String artworkId,
  ) =>
      'users/$uid/children/$childId/artworks/$artworkId/image.jpg';

  /// Storage path for an artwork's voice note.
  static String voiceNotePath(
    String uid,
    String childId,
    String artworkId,
  ) =>
      'users/$uid/children/$childId/artworks/$artworkId/voicenote.m4a';
}
