import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('FLUTTER ERROR: ${details.exception}');
        FlutterError.presentError(details);
      };

      runApp(const SchoolApp());
      unawaited(_initializeFirebase());
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('UNHANDLED ASYNC ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

Future<void> _initializeFirebase() async {
  try {
    final firebaseApp = await FirebaseBootstrap.initialize();
    debugPrint(
      'Firebase initialized: projectId=${firebaseApp.options.projectId}, '
      'appId=${firebaseApp.options.appId}, authDomain=${firebaseApp.options.authDomain}',
    );
  } catch (error, stackTrace) {
    debugPrint('FIREBASE INITIALIZATION ERROR: ${error.runtimeType}: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
