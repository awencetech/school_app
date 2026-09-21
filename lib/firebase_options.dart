// File generated from the existing Firebase project configuration for this app.
// The web app ID and iOS app ID below must match the Firebase Console registrations
// exactly. The project metadata itself is already correct for the existing project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQ3RHy7CHSLSNIXkpKMyRfzxt7PIxCP18',
    appId: '1:74427495793:web:0000000000000000',
    messagingSenderId: '74427495793',
    projectId: 'mhss-de0e7',
    authDomain: 'mhss-de0e7.firebaseapp.com',
    storageBucket: 'mhss-de0e7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQ3RHy7CHSLSNIXkpKMyRfzxt7PIxCP18',
    appId: '1:74427495793:android:864b60abc41f2800eb72d0',
    messagingSenderId: '74427495793',
    projectId: 'mhss-de0e7',
    storageBucket: 'mhss-de0e7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQ3RHy7CHSLSNIXkpKMyRfzxt7PIxCP18',
    appId: '1:74427495793:ios:0000000000000000',
    messagingSenderId: '74427495793',
    projectId: 'mhss-de0e7',
    storageBucket: 'mhss-de0e7.firebasestorage.app',
    iosBundleId: 'com.school.mmhs_app',
  );
}
