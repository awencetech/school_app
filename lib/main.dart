import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Set up global error handling to prevent app crashes from unhandled exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrintStack(
      label: 'FLUTTER ERROR: ${details.exception}',
      stackTrace: details.stack,
    );
  };

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
