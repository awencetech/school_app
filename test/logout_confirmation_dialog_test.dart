import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_app/widgets/logout_confirmation_dialog.dart';

void main() {
  testWidgets('No closes the dialog without invoking logout', (tester) async {
    var logoutCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => LogoutConfirmationDialog.show(
              context,
              onConfirm: () async => logoutCalls++,
            ),
            child: const Text('Open logout'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open logout'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Logout'), findsOneWidget);

    await tester.tap(find.text('No, Stay Logged In'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Logout'), findsNothing);
    expect(logoutCalls, 0);
  });

  testWidgets('Yes invokes logout once and prevents duplicate taps', (
    tester,
  ) async {
    var logoutCalls = 0;
    final logoutCompleter = Future<void>.delayed(
      const Duration(milliseconds: 100),
      () => logoutCalls++,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => LogoutConfirmationDialog.show(
              context,
              onConfirm: () => logoutCompleter,
            ),
            child: const Text('Open logout'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, Logout'));
    await tester.tap(find.text('Yes, Logout'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(logoutCalls, 1);
    expect(find.text('Confirm Logout'), findsNothing);
  });

  testWidgets(
    'logout error keeps the dialog open and re-enables confirmation',
    (tester) async {
      var attempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LogoutConfirmationDialog.show(
                  context,
                  onConfirm: () async {
                    attempts++;
                    throw StateError('synthetic logout failure');
                  },
                ),
                child: const Text('Open logout'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, Logout'));
      await tester.pumpAndSettle();

      expect(attempts, 1);
      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.text('Unable to log out. Please try again.'), findsOneWidget);
      expect(find.text('Yes, Logout'), findsOneWidget);
    },
  );
}
