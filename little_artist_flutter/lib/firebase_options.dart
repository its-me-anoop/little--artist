import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXlRK2gSeKbELsPoNQ-uGQx_8QHEv7_WM',
    appId: '1:576887246267:ios:fc84c094e0cbe06a5a089e',
    messagingSenderId: '576887246267',
    projectId: 'little-artist-fb9a8',
    storageBucket: 'little-artist-fb9a8.firebasestorage.app',
    iosBundleId: 'uk.co.flutterly.Little-Artist',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC2eaVNnsOrAqvLZZ6ogMgxpXoKrG61Y8k',
    appId: '1:576887246267:android:58a4a0e0a286485f5a089e',
    messagingSenderId: '576887246267',
    projectId: 'little-artist-fb9a8',
    storageBucket: 'little-artist-fb9a8.firebasestorage.app',
  );

}