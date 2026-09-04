import 'package:flutter/material.dart';

import '../screens/home/main_shell.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/login/create_account_screen.dart';
import '../screens/login/forgot_password_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_overview_dashboard_page.dart';
import '../screens/announcements/announcements_page.dart';
import '../screens/admin/announcement_edit_page.dart';
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
import '../screens/admin/demography_edit_page.dart';
import '../screens/admin/school_handbook_edit_page.dart';
import '../screens/admin/events_celebration_edit_page.dart';
import '../screens/admin/school_resources_edit_page.dart';
import '../screens/admin/news_letter_page.dart';
import '../screens/admin/library_page.dart';
import '../screens/admin/library_edit_page.dart';
import '../screens/admin/school_news_page.dart';
import '../screens/admin/admin_medical_event_list_page.dart';
import '../screens/admin/admin_medical_event_view_page.dart';
import '../screens/admin/track_bus_gps_page.dart';
import '../screens/admin/one_on_one_staff_meetings_page.dart';
import '../screens/admin/one_on_one_meeting_info_page.dart';
import '../screens/admin/gate_register_page.dart';
import '../screens/admin/employee_attendance_page.dart';
import '../screens/admin/facebook_edit_page.dart';
import '../screens/admin/youtube_edit_page.dart';
import '../screens/admin/instagram_edit_page.dart';
import '../screens/admin/whatsapp_edit_page.dart';
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
import '../screens/admin/create_class_screen.dart';
import '../screens/admin/empty_admin_option_page.dart';
import '../screens/admin/admin_write_message_page.dart';
import '../screens/admin/emp_leave_approval_page.dart';
import '../screens/admin/emp_leave_history_page.dart';
import '../screens/admin/grade_content_management_screen.dart';
import '../screens/admin/content_edit_screen.dart';
import '../screens/admin/school_content_management.dart';
import '../screens/admin/splash_screen_editor.dart';
import '../screens/admin/admin_home_screen.dart';
import '../models/group.dart';
import '../models/medical_event.dart';
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
import '../screens/admin/admin_user_profile_page.dart';
import '../screens/admin/admin_change_password_page.dart';
import '../utils/slug_generator.dart';
import 'app_routes.dart';

/// App-wide route factory.
class AppRouter {
  AppRouter._();
  static bool _splashShown = false;
  static Group? _lastSelectedGroup;

  static void markSplashShown() {
    _splashShown = true;
  }

  static void rememberSelectedGroup(Group group) {
    _lastSelectedGroup = group;
  }

  /// Safely extract Group from arguments, with fallback to the last selected group.
  /// This prevents TypeError: null crashes when arguments are missing or wrong type.
  static Group _groupFromArguments(Object? arguments) {
    if (arguments == null) {
      return _lastSelectedGroup ?? Group(id: 'unknown', name: 'Unknown');
    }
    if (arguments is Group) {
      rememberSelectedGroup(arguments);
      return arguments;
    }
    if (arguments is Map) {
      try {
        final values = Map<String, dynamic>.from(arguments);

        final nestedGroup = values['group'];
        if (nestedGroup is Group) return nestedGroup;
        if (nestedGroup is Map) {
          final nestedValues = Map<String, dynamic>.from(nestedGroup);
          if (nestedValues.containsKey('name') ||
              nestedValues.containsKey('id') ||
              nestedValues.containsKey('groupId') ||
              nestedValues.containsKey('_id')) {
            final group = Group.fromJson(nestedValues);
            rememberSelectedGroup(group);
            return group;
          }
        }

        if (values.containsKey('name') ||
            values.containsKey('id') ||
            values.containsKey('groupId') ||
            values.containsKey('_id')) {
          final group = Group.fromJson(values);
          rememberSelectedGroup(group);
          return group;
        }

        final name = values['name']?.toString().trim() ?? '';
        final id = (values['id'] ?? values['groupId'])?.toString().trim() ?? '';
        if (name.isNotEmpty || id.isNotEmpty) {
          final group = Group(
            databaseId: (values['_id'] ?? values['databaseId'] ?? '')
                .toString(),
            id: id.isEmpty ? name : id,
            name: name.isEmpty ? id : name,
            code: values['code']?.toString() ?? '',
            description: values['description']?.toString() ?? '',
            type: values['type']?.toString() ?? 'Other',
            status: values['status']?.toString() ?? 'Active',
            year: values['year']?.toString() ?? '2022',
          );
          rememberSelectedGroup(group);
          return group;
        }
      } catch (e) {
        debugPrint('WARNING: Failed to extract Group from arguments: $e');
      }
    }
    return _lastSelectedGroup ?? Group(id: 'unknown', name: 'Unknown');
  }

  static Group _eventGroupFromArguments(Object? arguments) {
    if (arguments is Group) return arguments;
    if (arguments is Map) {
      final values = Map<String, dynamic>.from(arguments);
      if (values['group'] is Group) return values['group'] as Group;
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

  static bool _isViewOnly(Object? arguments) {
    return arguments is Map && arguments['viewOnly'] == true;
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
      AppRoutes.staffAnnouncements => const AnnouncementsPage(),
      AppRoutes.staffResources => const StaffResourcesPage(),
      AppRoutes.schoolResources => const SchoolResourcesPage(),
      AppRoutes.staffHandbook => const StaffHandbookPage(),
      AppRoutes.staffEventsCelebration => StaffEventsCelebrationPage(),
      AppRoutes.staffTodoTasks => const StaffTodoTasksPage(),
      AppRoutes.adminDashboard => const AdminDashboard(),
      AppRoutes.adminMedicalEventList => const AdminMedicalEventListPage(),
      AppRoutes.adminMedicalEventListView => AdminMedicalEventViewPage(
        event: settings.arguments is MedicalEvent
            ? settings.arguments as MedicalEvent
            : null,
      ),
      AppRoutes.adminWrite => const AdminWriteMessagePage(),
      AppRoutes.adminTrackBusGps => const TrackBusGpsPage(),
      AppRoutes.adminEmployeeAttendance => const EmployeeAttendancePage(),
      AppRoutes.adminEmpLeaveApproval => const EmpLeaveApprovalPage(),
      AppRoutes.adminEmpLeaveApprovalHistory => const EmpLeaveHistoryPage(),
      AppRoutes.adminOneOnOne => const OneOnOneStaffMeetingsPage(),
      AppRoutes.adminOneOnOneMeetingInfo =>
        settings.arguments is StaffInfo
            ? OneOnOneMeetingInfoPage(staff: settings.arguments as StaffInfo)
            : const EmptyAdminOptionPage(title: 'Meeting Info History'),
      AppRoutes.adminGateRegister => const GateRegisterPage(),
      AppRoutes.adminDashboardNewsletter => const NewsLetterPage(),
      AppRoutes.adminDashboardLibrary => const LibraryPage(),
      AppRoutes.adminSchoolNews => const SchoolNewsPage(),
      AppRoutes.adminDashboardDemography => ClassDemographyPage(
        group: Group(id: 'grade-10-c', name: 'Grade 10 C', year: '2026-27'),
        isStaffView: true,
      ),
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
        const AnnouncementEditPage(),
      AppRoutes.adminKnowYourSchoolDemographyEdit => const DemographyEditPage(),
      AppRoutes.adminKnowYourSchoolFacebookEdit => const FacebookEditPage(),
      AppRoutes.adminKnowYourSchoolYoutubeEdit => const YoutubeEditPage(),
      AppRoutes.adminKnowYourSchoolWhatsappEdit => const WhatsappEditPage(),
      AppRoutes.adminKnowYourSchoolInstagramEdit => const InstagramEditPage(),
      AppRoutes.adminKnowYourSchoolLibraryEdit => const LibraryEditPage(),
      AppRoutes.adminStudentOptions => const StudentManagementPage(),
      AppRoutes.adminListStudents => const ListStudentsPage(),
      AppRoutes.adminListClasses => const EmptyAdminOptionPage(
        title: 'Classes',
      ),
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
      AppRoutes.adminAddClasses => const CreateClassesScreen(),
      AppRoutes.adminMainEditGradePage => const GradeContentManagementScreen(),
      AppRoutes.adminMainEditContentEdit => const ContentEditScreen(),
      _
          when settings.name != null &&
              RegExp(
                r'^/admin/other-groups/list-other-groups/[^/]+/group-menu/[^/]+$',
              ).hasMatch(settings.name!) =>
        _adminGroupMenuPage(settings),
      _
          when settings.name?.startsWith(AppRoutes.adminOtherGroupDetails) ==
              true =>
        (() {
          final group = settings.arguments is Group
              ? settings.arguments as Group
              : Group(
                  id: Uri.decodeComponent(settings.name!.split('/').last),
                  name: Uri.decodeComponent(settings.name!.split('/').last),
                );
          return GroupDetailsPage(group: group, isViewOnly: true);
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
        return GroupInfoPage(
          group: group,
          isViewOnly: _isViewOnly(settings.arguments),
        );
      })(),
      AppRoutes.teacherFutureEventCalendar ||
      AppRoutes.teacherEditFutureEventCalendar => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        final viewOnly = _isViewOnly(settings.arguments);
        return FutureEventCalendarPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
          isEdit:
              !viewOnly &&
              settings.name == AppRoutes.teacherEditFutureEventCalendar,
        );
      })(),
      AppRoutes.teacherHomeworkToday ||
      AppRoutes.teacherEditHomeworkToday => (() {
        final group = _eventGroupFromArguments(settings.arguments);
        final viewOnly = _isViewOnly(settings.arguments);
        return HomeworkTodayInClassPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
          groupYear: group.year,
          isEdit:
              !viewOnly && settings.name == AppRoutes.teacherEditHomeworkToday,
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
        final viewOnly = _isViewOnly(settings.arguments);
        return GroupMessagesPage(
          groupId: generateGroupDatabaseId(group.name),
          groupName: group.name,
          groupYear: group.year,
          isViewOnly: viewOnly,
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
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherClassResources ||
      AppRoutes.teacherEditClassResources => (() {
        final selectedGroup = _groupFromArguments(settings.arguments);
        final group = selectedGroup.id.toLowerCase() == 'unknown'
            ? Group(id: 'NCC2022', name: 'NCC2022', year: '2022')
            : selectedGroup;
        return ClassResourcesPage(
          group: group,
          isViewOnly:
              settings.name == AppRoutes.teacherClassResources ||
              _isViewOnly(settings.arguments),
        );
      })(),
      AppRoutes.teacherPhotosNews ||
      AppRoutes.teacherEditPhotosNews => ClassNewsPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
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
      AppRoutes.teacherClassPlanner ||
      AppRoutes.teacherEditClassPlanner => ClassPlannerPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherVideoConference ||
      AppRoutes.teacherEditVideoConference => OnlineClassMeetingPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherClassFilePlan ||
      AppRoutes.teacherEditClassFilePlan => ClassFileplanPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherOnlineAssignment ||
      AppRoutes.teacherEditOnlineAssignment => OnlineAssignmentPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherOnlineAssessment ||
      AppRoutes.teacherEditOnlineAssessment => OnlineAssessmentPage(
        group: _groupFromArguments(settings.arguments),
        isViewOnly: _isViewOnly(settings.arguments),
      ),
      AppRoutes.teacherGroupInfoEdit => (() {
        final group = _groupFromArguments(settings.arguments);
        return GroupInfoEditPage(group: group);
      })(),
      AppRoutes.teacherGroupClassMenu => (() {
        final arguments = settings.arguments;
        final viewOnly = arguments is Map && arguments['viewOnly'] == true;
        return GroupMenuPage(
          group: _groupFromArguments(arguments),
          isViewOnly: viewOnly,
        );
      })(),
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
      AppRoutes.adminUserProfile => const AdminUserProfilePage(),
      AppRoutes.adminChangePassword => const AdminChangePasswordPage(),
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

  static Widget _adminGroupMenuPage(RouteSettings settings) {
    final parts = settings.name!.split('/');
    final feature = parts.last;
    final arguments = settings.arguments;
    final argumentGroup = arguments is Map ? arguments['group'] : null;
    final group = arguments is Group
        ? arguments
        : argumentGroup is Group
        ? argumentGroup
        : Group(id: parts[4], name: parts[4]);
    switch (feature) {
      case 'group-menu':
        return GroupMenuPage(group: group, isViewOnly: true);
      case 'group-info':
        return GroupInfoPage(group: group, isViewOnly: true);
      case 'future-event-calendar':
        return FutureEventCalendarPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
        );
      case 'hw-today-in-class':
        return HomeworkTodayInClassPage(
          groupId: _eventGroupId(group),
          groupName: group.name,
          groupYear: group.year,
        );
      case 'group-messages':
      case 'write-message':
        return GroupMessagesPage(
          groupId: generateGroupDatabaseId(group.name),
          groupName: group.name,
          groupYear: group.year,
          isViewOnly: true,
        );
      case 'class-demography':
        return ClassDemographyPage(group: group, isViewOnly: true);
      case 'class-resources':
        return ClassResourcesPage(group: group, isViewOnly: true);
      case 'photo-news':
        return ClassNewsPage(group: group, isViewOnly: true);
      case 'class-timetable':
        return ClassTimetablePage(group: group);
      case 'class-planner':
        return ClassPlannerPage(group: group, isViewOnly: true);
      case 'video-conference':
        return OnlineClassMeetingPage(group: group, isViewOnly: true);
      case 'class-files':
        return ClassFileplanPage(group: group, isViewOnly: true);
      case 'online-assignment':
        return OnlineAssignmentPage(group: group, isViewOnly: true);
      case 'online-assessment':
        return OnlineAssessmentPage(group: group, isViewOnly: true);
      case 'group-dashboard':
        return GroupDashboardPage(group: group);
      case 'diary-summary':
        return DiarySummaryPage(group: group);
      case 'take-attendance':
        return AbsencePage(group: group);
      case 'appreciate-award':
        return GroupAchievementAwardPage(group: group);
      case 'leave-approval':
        return LeaveApprovalPage(group: group);
      case 'medical-event-list':
        return MedicalEventListPage(group: group);
      case 'happiness-report':
        return HappinessReportPage(group: group);
      case 'one-on-one-meeting':
        return OneOnOneMeetingPage(group: group);
      case 'pick-drop-entry':
        return PickDropEntryPage(group: group);
      case 'access-management':
        return AccessManagementPage(group: group);
      case 'class-fee-details':
        return ClassFeeDetailsPage(group: group);
      default:
        return GroupDetailsPage(group: group, isViewOnly: true);
    }
  }
}
