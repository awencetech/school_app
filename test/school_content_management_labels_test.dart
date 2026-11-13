import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/generated/l10n/app_localizations.dart';
import 'package:school_app/models/management_member.dart';
import 'package:school_app/screens/admin/school_content_management.dart';
import 'package:school_app/screens/school/school_screen.dart';
import 'package:school_app/services/school_config_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('content editor uses generic member labels', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SchoolConfigService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SchoolContentManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member Details'), findsNWidgets(4));
    expect(find.text('Member Photo'), findsNWidgets(3));
    expect(find.text('Vision Title'), findsNWidgets(3));
    expect(find.text('Vision Description'), findsNWidgets(3));
    expect(find.text('Founder'), findsNothing);
    expect(find.text('Secretary'), findsNothing);
    expect(find.text('Principal'), findsNothing);
    expect(find.text('Headmaster'), findsNothing);
    expect(find.text('Management Members'), findsNothing);
    expect(find.text('No members added yet.'), findsOneWidget);
    expect(find.text('No management members added yet.'), findsNothing);
  });

  testWidgets('new member form uses the generic member labels', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SchoolConfigService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SchoolContentManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add Member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Member'));
    await tester.pumpAndSettle();

    expect(find.text('Member Photo'), findsNWidgets(4));
    expect(find.text('Name'), findsNWidgets(4));
    expect(find.text('Designation'), findsNWidgets(4));
    expect(find.text('Vision Title'), findsNWidgets(4));
    expect(find.text('Vision Description'), findsNWidgets(4));
    expect(find.text('Founder'), findsNothing);
    expect(find.text('Secretary'), findsNothing);
    expect(find.text('Principal'), findsNothing);
    expect(find.text('Headmaster'), findsNothing);
    expect(find.text('Management Members'), findsNothing);
  });

  testWidgets('School tab reflects saved members under a generic heading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'founder_name': 'Existing Member',
      'founder_designation': 'Board Member',
      'founder_vision_title': 'Vision',
      'founder_vision_description': 'Existing description',
      'secretary_name': 'Second Existing Member',
      'secretary_designation': 'Trustee',
      'secretary_welcome_title': 'Shared Values',
      'secretary_welcome_message': 'A message for the community',
      'headmaster_name': 'Third Existing Member',
      'headmaster_designation': 'Education Leader',
      'headmaster_message_title': 'Learning Vision',
      'headmaster_message': 'A commitment to learning',
      'management_members': jsonEncode([
        ManagementMember(
          id: 'existing-member',
          photoBase64: '',
          name: 'Newly Added Member',
          designation: 'Community Member',
          title: 'Community Vision',
          description: 'Existing management member',
        ).toJson(),
      ]),
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SchoolConfigService(),
        child: const MaterialApp(home: SchoolScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member Details'), findsOneWidget);
    expect(find.text('Existing Member'), findsOneWidget);
    expect(find.text('Second Existing Member'), findsOneWidget);
    expect(find.text('Third Existing Member'), findsOneWidget);
    expect(find.text('Newly Added Member'), findsOneWidget);
    expect(find.text('Board Member'), findsOneWidget);
    expect(find.text('Community Member'), findsOneWidget);
    expect(find.text('Founder'), findsNothing);
    expect(find.text('Secretary'), findsNothing);
    expect(find.text('Principal'), findsNothing);
    expect(find.text('Headmaster'), findsNothing);
    expect(find.text('Management Members'), findsNothing);
  });
}
