import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<FirebaseApp>? _initialization;

  static Future<FirebaseApp> initialize() {
    return _initialization ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
