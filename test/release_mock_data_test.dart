import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_app/generated/l10n/app_localizations.dart';
import 'package:school_app/models/group.dart';
import 'package:school_app/models/school_resource.dart';
import 'package:school_app/screens/admin/class_fileplan_page.dart';
import 'package:school_app/screens/admin/online_assignment_page.dart';
import 'package:school_app/screens/admin/online_class_meeting_page.dart';
import 'package:school_app/services/online_assignment_service.dart';
import 'package:school_app/services/school_resource_service.dart';

class _FakeAssignmentService extends OnlineAssignmentService {
  _FakeAssignmentService(this.records);

  final List<Map<String, dynamic>> records;

  @override
  Future<List<Map<String, dynamic>>> getAssignments({
    required String groupId,
    required List<String> groupReferences,
  }) async => records;
}

class _FakeResourceService extends SchoolResourceService {
  _FakeResourceService(this.resources);

  final List<SchoolResource> resources;

  @override
  Future<List<SchoolResource>> getResources([String? groupId]) async =>
      resources;
}

Widget _localizedApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

final _group = Group(id: 'group-1', name: 'Class 1');

void main() {
  testWidgets('assignment list displays backend empty state', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        OnlineAssignmentPage(
          group: _group,
          assignmentService: _FakeAssignmentService(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No assignments available.'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Mathematics Assignment'), findsNothing);
  });

  testWidgets('assignment list displays backend records', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        OnlineAssignmentPage(
          group: _group,
          assignmentService: _FakeAssignmentService([
            {
              'id': 'assignment-1',
              'groupId': 'group-1',
              'title': 'Backend assignment',
              'subject': 'Science',
              'assignedDate': '2026-10-01T00:00:00.000Z',
              'dueDate': '2026-10-10T00:00:00.000Z',
              'maxMarks': 25,
              'status': 'Active',
              'folder': 'Science',
              'attachments': [],
              'submissions': [],
            },
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backend assignment'), findsWidgets);
  });

  testWidgets('class file plan displays backend empty state', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ClassFileplanPage(
          group: _group,
          resourceService: _FakeResourceService(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No files or resources available.'), findsOneWidget);
    expect(find.text('Mathematics Notes.pdf'), findsNothing);
  });

  testWidgets('class file plan displays backend resources', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ClassFileplanPage(
          group: _group,
          resourceService: _FakeResourceService([
            SchoolResource(
              id: 'resource-1',
              heading: 'Backend study guide',
              date: '2026-10-01T00:00:00.000Z',
              resourceName: 'Published resource',
              groupId: 'group-1',
              resourceType: 'pdf',
              fileName: 'study-guide.pdf',
              fileSize: 1024,
              createdAt: DateTime.utc(2026, 10, 1),
              updatedAt: DateTime.utc(2026, 10, 1),
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Backend study guide'), findsWidgets);
  });

  testWidgets(
    'online class screen displays the scheduled-meeting empty state',
    (tester) async {
      await tester.pumpWidget(
        _localizedApp(OnlineClassMeetingPage(group: _group, isViewOnly: true)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No online class meeting is currently scheduled.'),
        findsOneWidget,
      );
      expect(find.text('Current Teacher'), findsNothing);
      expect(find.textContaining('meet.google.com'), findsNothing);
    },
  );
}
