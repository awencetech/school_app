import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling to prevent app crashes from unhandled exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrintStack(
      label: 'FLUTTER ERROR: ${details.exception}',
      stackTrace: details.stack,
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('FIREBASE INITIALIZATION ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runZonedGuarded(
    () {
      runApp(const SchoolApp());
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('UNHANDLED ASYNC ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
