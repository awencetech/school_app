import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_app/services/class_content_service.dart';
import 'package:school_app/services/demography_service.dart';
import 'package:school_app/services/employee_attendance_service.dart';
import 'package:school_app/services/medical_event_service.dart';
import 'package:school_app/services/library_service.dart';
import 'package:school_app/services/main_page_info_repository.dart';
import 'package:school_app/services/online_assignment_service.dart';
import 'package:school_app/services/school_resource_service.dart';
import 'package:school_app/services/student_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_user_token': 'unit-test-token',
    });
  });

  test('sensitive service requests send the stored bearer token', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/upload/medical-report') {
        return http.Response(
          '{"url":"https://unit.test/api/images/test-image"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/mainpage-info') {
        return http.Response(
          '{"homeContent":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200);
    });

    await http.runWithClient(() async {
      await MedicalEventService(baseUrl: 'https://unit.test').getAll();
      await MedicalEventService(
        baseUrl: 'https://unit.test',
      ).uploadReport('report.png', [1, 2, 3]);
      await StudentService(baseUrl: 'https://unit.test').getStudents();
      await EmployeeAttendanceService(baseUrl: 'https://unit.test').getAll();
      await ClassContentService(
        baseUrl: 'https://unit.test',
      ).getPhotosForGroup('group-1');
      await ClassContentService(
        baseUrl: 'https://unit.test',
      ).getNewsForGroup('group-1');
      await DemographyService(
        baseUrl: 'https://unit.test',
      ).getDemographiesByGroup('group-1');
      await LibraryService(baseUrl: 'https://unit.test').getBooks();
      await MainPageInfoRepository(
        baseUrl: 'https://unit.test',
      ).getMainPageInfo();
      await OnlineAssignmentService(
        baseUrl: 'https://unit.test',
      ).getAssignments(groupId: 'group-1', groupReferences: const []);
      await SchoolResourceService(
        baseUrl: 'https://unit.test',
      ).getResources('group-1');
    }, () => client);

    expect(requests, hasLength(11));
    expect(
      requests.map((request) => request.url.path),
      containsAll([
        '/api/upload/medical-report',
        '/api/medical-events',
        '/api/students',
        '/api/employee-attendance',
        '/api/groups/group-1/photos',
        '/api/groups/group-1/news',
        '/api/demography/group/group-1',
        '/api/library',
        '/api/mainpage-info',
        '/api/online-assignment',
        '/api/class-resources/group-1',
      ]),
    );
    for (final request in requests) {
      expect(request.headers['Authorization'], 'Bearer unit-test-token');
    }
  });
}
