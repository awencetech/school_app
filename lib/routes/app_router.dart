import 'package:flutter/material.dart';

import '../screens/home/main_shell.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/login/create_account_screen.dart';
import '../screens/login/forgot_password_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_overview_dashboard_page.dart';
import '../screens/messages/messages_page.dart';
import '../screens/staff/staff_apply_leave_page.dart';
import '../screens/staff/staff_info_page.dart';
import '../screens/staff/staff_swipe_attendance_page.dart';
import '../screens/staff/staff_meeting_page.dart';
import '../screens/staff/staff_resources_page.dart';
import '../screens/staff/school_resources_page.dart';
import '../screens/staff/staff_handbook_page.dart';
import '../screens/staff/staff_events_celebration_page.dart';
import '../screens/staff/staff_todo_tasks_page.dart';
import '../screens/staff/staff_placeholder_page.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/student_info_screen.dart';
import '../screens/student/student_more_options_screen.dart';
import '../screens/student/group_class_menu_screen.dart';
import '../screens/student/student_menu_screen.dart';
import '../screens/support/support_query_screen.dart';
import '../screens/support/privacy_policy_screen.dart';
import '../screens/admin/admin_other_options.dart';
import '../screens/admin/admin_detail_page.dart';
import '../screens/admin/know_your_school_page.dart';
import '../screens/admin/know_your_school_detail_page.dart';
import '../screens/admin/school_handbook_edit_page.dart';
import '../screens/admin/events_celebration_edit_page.dart';
import '../screens/admin/school_resources_edit_page.dart';
import '../screens/admin/news_letter_page.dart';
import '../screens/admin/newsletter_edit_page.dart';
import '../screens/admin/list_teachers_page.dart';
import '../screens/admin/staff_management_page.dart';
import '../screens/admin/staff_details_page.dart';
import '../screens/admin/student_management_page.dart';
import '../screens/admin/list_students_page.dart';
import '../screens/admin/admin_student_menu_page.dart';
import '../screens/admin/student_info_page.dart';
import '../models/staff_info.dart';
import '../services/student_service.dart';
import '../screens/admin/add_options.dart';
import '../screens/admin/student_create_id_screen.dart';
import '../screens/admin/staff_create_id_screen.dart';
import '../screens/admin/admin_create_id_screen.dart';
import '../screens/admin/create_group_screen.dart';
import '../screens/admin/grade_content_management_screen.dart';
import '../screens/admin/content_edit_screen.dart';
import '../screens/admin/school_content_management.dart';
import '../screens/admin/splash_screen_editor.dart';
import '../screens/admin/admin_home_screen.dart';
import '../models/group.dart';
import '../models/class_timetable.dart';
import '../models/event_celebration.dart';
import '../screens/admin/admin_section_page.dart';
import '../screens/admin/school_settings_editor.dart';
import '../screens/admin/other_groups_screen.dart';
import '../screens/admin/group_details_page.dart';
import '../screens/admin/group_info_edit_page.dart';
import '../screens/admin/group_info_page.dart';
import '../screens/admin/group_menu_page.dart';
import '../screens/admin/class_demography_page.dart';
import '../screens/admin/class_fileplan_page.dart';
import '../screens/admin/class_news_page.dart';
import '../screens/admin/class_planner_page.dart';
import '../screens/admin/class_resources_page.dart';
import '../screens/admin/class_timetable_page.dart';
import '../screens/admin/class_timetable_form_page.dart';
import '../screens/admin/group_messages_page.dart';
import '../screens/admin/group_messages_edit_page.dart';
import '../screens/admin/homework_today_in_class_page.dart';
import '../screens/admin/future_event_calendar_page.dart';
import '../screens/admin/online_assignment_page.dart';
import '../screens/admin/online_assessment_page.dart';
import '../screens/admin/online_class_meeting_page.dart';
import '../screens/admin/write_message_page.dart';
import '../screens/admin/absence_page.dart';
import '../screens/admin/access_management_page.dart';
import '../screens/admin/class_fee_details_page.dart';
import '../screens/admin/group_achievement_award_page.dart';
import '../screens/admin/group_dashboard_page.dart';
import '../screens/admin/diary_summary_page.dart';
import '../screens/admin/happiness_report_page.dart';
import '../screens/admin/leave_approval_page.dart';
import '../screens/admin/medical_event_list_page.dart';
import '../screens/admin/one_on_one_meeting_page.dart';
import '../screens/admin/pick_drop_entry_page.dart';
import '../utils/slug_generator.dart';
import 'app_routes.dart';

/// App-wide route factory.
class AppRouter {
  AppRouter._();
  static bool _splashShown = false;

  static void markSplashShown() {
    _splashShown = true;
  }

  /// Safely extract Group from arguments, with fallback to unknown group.
  /// This prevents TypeError: null crashes when arguments are missing or wrong type.
  static Group _groupFromArguments(Object? arguments) {
    if (arguments == null) {
      return Group(id: 'unknown', name: 'Unknown');
    }
    if (arguments is Group) return arguments;
    if (arguments is Map) {
      try {
        final values = Map<String, dynamic>.from(arguments);
        final nestedGroup = values['group'];
        if (nestedGroup is Group) return nestedGroup;
        if (nestedGroup is Map) {
          final name = (nestedGroup['name'] ?? '').toString().trim();
          final id = (nestedGroup['id'] ?? nestedGroup['groupId'] ?? '')
              .toString()
              .trim();
          if (name.isNotEmpty || id.isNotEmpty) {
            return Group(
              id: id.isEmpty ? name : id,
              name: name.isEmpty ? id : name,
            );
          }
        }

        final name = values['name']?.toString().trim() ?? '';
        final id = (values['id'] ?? values['groupId'])?.toString().trim() ?? '';
        if (name.isNotEmpty || id.isNotEmpty) {
          return Group(
            id: id.isEmpty ? name : id,
            name: name.isEmpty ? id : name,
          );
        }
      } catch (e) {
        debugPrint('WARNING: Failed to extract Group from arguments: $e');
      }
    }
    return Group(id: 'unknown', name: 'Unknown');
  }

  static Group _eventGroupFromArguments(Object? arguments) {
    if (arguments is Group) return arguments;
    if (arguments is Map) {
      final values = Map<String, dynamic>.from(arguments);
      final name = values['name']?.toString().trim() ?? '';
      final id = (values['id'] ?? values['groupId'])?.toString().trim() ?? '';
      if (name.isNotEmpty || id.isNotEmpty) {
        return Group(
          id: id.isEmpty ? name : id,
          name: name.isEmpty ? id : name,
        );
      }
    }
    return Group(id: 'unknown', name: 'Unknown');
  }

  static String _eventGroupId(Group group) {
    final id = group.id.trim();
    if (id.isNotEmpty && id.toLowerCase() != 'unknown') {
      if (id.toUpperCase().startsWith('SAMUNI-2022-')) return id;
      return generateGroupDatabaseId(group.name.isEmpty ? id : group.name);
    }
    return generateGroupDatabaseId(group.name);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      // On first route resolution in this app session, show splash first so
      // users always see the splash on page refresh / initial load.
      _ when !_splashShown => () {
        _splashShown = true;
        return SplashScreen(targetRoute: settings.name);
      }(),
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.language => const LanguageSelectionScreen(),
      AppRoutes.main => const MainShell(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.createAccount => const CreateAccountScreen(),
      AppRoutes.studentDashboard => const StudentDashboard(),
      AppRoutes.studentInfo => const StudentInfoScreen(),
      AppRoutes.studentMoreOptions => const StudentMoreOptionsScreen(),
      AppRoutes.groupClassMenu => const GroupClassMenuScreen(),
      AppRoutes.studentMenu => const StudentMenuScreen(),
      AppRoutes.staffDashboard => const StaffDashboard(),
      AppRoutes.staffOverviewDashboard => const StaffOverviewDashboardPage(),
      AppRoutes.staffEventCalendar => const FutureEventCalendarPage(
        groupId: 'grade-10-c',
        groupName: 'Grade 10 C',
        isStaffView: true,
      ),
      AppRoutes.staffInfo => (() {
        final staff = settings.arguments;
        return staff is StaffInfo
            ? StaffInfoPage(staff: staff)
            : const StaffInfoPage();
      })(),
      AppRoutes.staffInfoEdit => (() {
        final staff = settings.arguments;
        return staff is StaffInfo
            ? StaffInfoPage(staff: staff, initialEditing: true)
            : const StaffInfoPage(initialEditing: true);
      })(),
      AppRoutes.staffApplyLeave => const StaffApplyLeavePage(),
      AppRoutes.staffSwipeAttendance => const StaffSwipeAttendancePage(),
      AppRoutes.staffManagementFeedback => const StaffPlaceholderPage(
        title: 'Management Feedback',
      ),
      AppRoutes.staffMeeting => const StaffMeetingPage(),
      AppRoutes.staffAnnouncements => const MessagesPage(),
      AppRoutes.staffResources => const StaffResourcesPage(),
      AppRoutes.schoolResources => const SchoolResourcesPage(),
      AppRoutes.staffHandbook => const StaffHandbookPage(),
      AppRoutes.staffEventsCelebration => StaffEventsCelebrationPage(),
      AppRoutes.staffTodoTasks => const StaffTodoTasksPage(),
      AppRoutes.adminDashboard => const AdminDashboard(),
      AppRoutes.adminDashboardNewsletter => const NewsLetterPage(),
      AppRoutes.adminOtherOptions => const AdminOtherOptions(),
      AppRoutes.adminMainEdit => const AdminDetailPage(),
      AppRoutes.adminAdd => const AddOptions(),
      AppRoutes.adminKnowYourSchool => const KnowYourSchoolPage(),
      AppRoutes.adminKnowYourSchoolWebsiteEdit =>
        const KnowYourSchoolDetailPage(title: 'Website', icon: Icons.language),
      AppRoutes.adminKnowYourSchoolSchoolHandbookEdit =>
        const SchoolHandbookEditPage(),
      AppRoutes.adminKnowYourSchoolEventsCelebrationEdit =>
        const EventsCelebrationEditPage(),
      AppRoutes.adminKnowYourSchoolEventsCelebrationEditAddEvent =>
        const EventCelebrationFormPage(),
      AppRoutes.adminKnowYourSchoolEventsCelebrationEditEditEvent =>
        EventCelebrationFormPage(
          event: settings.arguments is EventCelebration
              ? settings.arguments as EventCelebration
              : null,
        ),
      AppRoutes.adminKnowYourSchoolSchoolResourcesEdit =>
        const SchoolResourcesEditPage(),
      AppRoutes.adminKnowYourSchoolNewsletterEdit => const NewsletterEditPage(),
      AppRoutes.adminKnowYourSchoolAnnouncementEdit =>
        const KnowYourSchoolDetailPage(
          title: 'Announcement',
          icon: Icons.announcement,
        ),
      AppRoutes.adminKnowYourSchoolDemographyEdit =>
        const KnowYourSchoolDetailPage(title: 'Demography', icon: Icons.people),
      AppRoutes.adminKnowYourSchoolFacebookEdit =>
        const KnowYourSchoolDetailPage(title: 'Facebook', icon: Icons.facebook),
      AppRoutes.adminKnowYourSchoolYoutubeEdit =>
        const KnowYourSchoolDetailPage(
          title: 'Youtube',
          icon: Icons.ondemand_video,
        ),
      AppRoutes.adminKnowYourSchoolWhatsappEdit =>
        const KnowYourSchoolDetailPage(title: 'WhatsApp', icon: Icons.chat),
      AppRoutes.adminKnowYourSchoolInstagramEdit =>
        const KnowYourSchoolDetailPage(
          title: 'Instagram',
          icon: Icons.camera_alt,
        ),
      AppRoutes.adminKnowYourSchoolLibraryEdit =>
        const KnowYourSchoolDetailPage(
          title: 'Library',
          icon: Icons.library_books,
        ),
      AppRoutes.adminStudentOptions => const StudentManagementPage(),
      AppRoutes.adminListStudents => const ListStudentsPage(),
      AppRoutes.adminStudentInfo => (() {
        final student = settings.arguments;
        return student is StudentRecord
            ? StudentInfoPage(student: student)
            : const ListStudentsPage();
      })(),
      AppRoutes.adminStudentMenu => (() {
        final student = settings.arguments;
        return student is StudentRecord
            ? AdminStudentMenuPage(student: student)
            : const ListStudentsPage();
      })(),
      AppRoutes.adminStaffOptions => const StaffManagementPage(),
      AppRoutes.adminListTeachers => const ListTeachersPage(),
      AppRoutes.adminEmployeeInfo => (() {
        final staff = settings.arguments;
        return staff is StaffInfo
            ? StaffDetailsPage(staff: staff)
            : const ListTeachersPage();
      })(),
      AppRoutes.adminAddStudent => const StudentCreateIdScreen(),
      AppRoutes.adminAddStaff => const StaffCreateIdScreen(),
      AppRoutes.adminAddAdmin => const AdminCreateIdScreen(),
      AppRoutes.adminAddGroup => const CreateGroupScreen(),
      AppRoutes.adminMainEditGradePage => const GradeContentManagementScreen(),
      AppRoutes.adminMainEditContentEdit => const ContentEditScreen(),
      _
          when settings.name?.startsWith(AppRoutes.adminOtherGroupDetails) ==
              true =>
        (() {
          final group = settings.arguments as Group;
          return GroupDetailsPage(group: group);
        })(),
      AppRoutes.adminOtherGroups => const OtherGroupsScreen(),
      AppRoutes.adminGroupDetails => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupDetailsPage(group: group);
      })(),
      AppRoutes.teacherGroupClasses => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupMenuPage(group: group);
      })(),
      AppRoutes.teacherGroupInfo => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupInfoPage(group: group);
      })(),
      AppRoutes.teacherFutureEventCalendar ||
      AppRoutes.teacherEditFutureEventCalendar => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        return FutureEventCalendarPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
          isEdit: settings.name == AppRoutes.teacherEditFutureEventCalendar,
        );
      })(),
      AppRoutes.teacherHomeworkToday ||
      AppRoutes.teacherEditHomeworkToday => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        return HomeworkTodayInClassPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
          groupYear: group.year,
          isEdit: settings.name == AppRoutes.teacherEditHomeworkToday,
        );
      })(),
      AppRoutes.teacherHomeworkAdd => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        return HomeworkAddPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
        );
      })(),
      AppRoutes.teacherTodayClassAdd => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        return TodayClassAddPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
        );
      })(),
      AppRoutes.teacherGroupMessages => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupMessagesPage(
          groupId: generateGroupDatabaseId(group.name),
          groupName: group.name,
          groupYear: group.year,
        );
      })(),
      AppRoutes.teacherEditGroupMessages => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupMessagesEditPage(
          groupId: generateGroupDatabaseId(group.name),
          groupName: group.name,
          groupYear: group.year,
        );
      })(),
      AppRoutes.teacherWriteMessage ||
      AppRoutes.teacherEditWriteMessage => (() {
        final group = _groupFromArguments(settings.arguments);
        return WriteMessagePage(
          groupId: generateGroupDatabaseId(group.name),
          groupName: group.name,
          groupYear: group.year,
        );
      })(),
      AppRoutes.teacherClassDemography ||
      AppRoutes.teacherEditClassDemography => ClassDemographyPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherClassResources || AppRoutes.teacherEditClassResources =>
        ClassResourcesPage(group: _groupFromArguments(settings.arguments)),
      AppRoutes.teacherPhotosNews || AppRoutes.teacherEditPhotosNews =>
        ClassNewsPage(group: _groupFromArguments(settings.arguments)),
      AppRoutes.teacherClassTimetable => ClassTimetablePage(
        group: _eventGroupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherEditClassTimetable => ClassTimetablePage(
        group: _eventGroupFromArguments(settings.arguments),
        isEdit: true,
      ),
      AppRoutes.teacherClassTimetableAdd => (() {
        final arguments = settings.arguments;
        if (arguments is Group) return ClassTimetableFormPage(group: arguments);
        final values = arguments is Map
            ? Map<String, dynamic>.from(arguments)
            : <String, dynamic>{};
        return ClassTimetableFormPage(
          group: values['group'] is Group
              ? values['group'] as Group
              : _eventGroupFromArguments(null),
          entry: values['entry'] is ClassTimetableEntry
              ? values['entry'] as ClassTimetableEntry
              : null,
        );
      })(),
      AppRoutes.teacherClassPlanner || AppRoutes.teacherEditClassPlanner =>
        ClassPlannerPage(group: _groupFromArguments(settings.arguments)),
      AppRoutes.teacherVideoConference ||
      AppRoutes.teacherEditVideoConference => OnlineClassMeetingPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherClassFilePlan || AppRoutes.teacherEditClassFilePlan =>
        ClassFileplanPage(group: _groupFromArguments(settings.arguments)),
      AppRoutes.teacherOnlineAssignment ||
      AppRoutes.teacherEditOnlineAssignment => OnlineAssignmentPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherOnlineAssessment ||
      AppRoutes.teacherEditOnlineAssessment => OnlineAssessmentPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherGroupInfoEdit => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupInfoEditPage(group: group);
      })(),
      AppRoutes.teacherGroupClassMenu => GroupMenuPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherGroupDashboard => GroupDashboardPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherDiarySummary => DiarySummaryPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherTakeAttendance => AbsencePage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherAppreciateAward => GroupAchievementAwardPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherLeaveApproval => LeaveApprovalPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherMedicalEventList => MedicalEventListPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherHappinessReport => HappinessReportPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherOneOnOneMeeting => OneOnOneMeetingPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherPickDropEntry => PickDropEntryPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherAccessManagement => AccessManagementPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.teacherClassFeeDetails => ClassFeeDetailsPage(
        group: _groupFromArguments(settings.arguments),
      ),
      AppRoutes.adminHomeScreen => const AdminHomeScreen(),
      AppRoutes.adminSchoolSettings => const SchoolSettingsEditor(),
      AppRoutes.adminSchoolContentManagement =>
        const SchoolContentManagementScreen(),
      AppRoutes.adminSection => (() {
        final title = settings.arguments as String? ?? 'Section';
        return AdminSectionPage(title: title);
      })(),
      AppRoutes.adminSplashScreenEditor => const SplashScreenEditor(),
      AppRoutes.supportQuery => const SupportQueryScreen(),
      AppRoutes.privacyPolicy => const PrivacyPolicyScreen(),
      _ => const MainShell(),
    };

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}
