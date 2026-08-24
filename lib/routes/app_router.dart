import 'package:flutter/material.dart';

import '../screens/home/main_shell.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/login/create_account_screen.dart';
import '../screens/login/forgot_password_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/student_info_screen.dart';
import '../screens/student/student_more_options_screen.dart';
import '../screens/student/group_class_menu_screen.dart';
import '../screens/student/student_menu_screen.dart';
import '../screens/support/support_query_screen.dart';
import '../screens/support/privacy_policy_screen.dart';
import '../screens/admin/admin_other_options.dart';
import '../screens/admin/school_content_management.dart';
import '../screens/admin/splash_screen_editor.dart';
import '../screens/admin/admin_home_screen.dart';
import '../models/group.dart';
import '../screens/admin/admin_section_page.dart';
import '../screens/admin/school_settings_editor.dart';
import '../screens/admin/other_groups_screen.dart';
import '../screens/admin/group_details_page.dart';
import '../screens/admin/group_info_edit_page.dart';
import '../screens/admin/group_info_page.dart';
import '../screens/admin/group_menu_page.dart';
import '../screens/admin/group_menu_placeholder_page.dart';
import 'app_routes.dart';

/// App-wide route factory.
class AppRouter {
  AppRouter._();
  static bool _splashShown = false;

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
      AppRoutes.adminDashboard => const AdminDashboard(),
      AppRoutes.adminOtherOptions => const AdminOtherOptions(),
      AppRoutes.adminOtherGroups => const OtherGroupsScreen(),
      AppRoutes.adminGroupDetails => (() {
        final group = settings.arguments as dynamic;
        return GroupDetailsPage(group: group);
      })(),
      AppRoutes.teacherGroupClasses => (() {
        final group = settings.arguments as dynamic;
        return GroupMenuPage(group: group);
      })(),
      AppRoutes.teacherGroupInfo => (() {
        final group = settings.arguments as dynamic;
        return GroupInfoPage(group: group is Group ? group : Group(id: 'unknown', name: 'Unknown'));
      })(),
      AppRoutes.teacherFutureEventCalendar => _groupMenuPlaceholder(
        settings,
        'Future Event Calendar',
      ),
      AppRoutes.teacherHomeworkToday => _groupMenuPlaceholder(
        settings,
        'HW Today In Class',
      ),
      AppRoutes.teacherGroupMessages => _groupMenuPlaceholder(
        settings,
        'Group Messages',
      ),
      AppRoutes.teacherWriteMessage => _groupMenuPlaceholder(
        settings,
        'Write Write Emsg',
      ),
      AppRoutes.teacherClassDemography => _groupMenuPlaceholder(
        settings,
        'Class Demography',
      ),
      AppRoutes.teacherClassResources => _groupMenuPlaceholder(
        settings,
        'Class Resources',
      ),
      AppRoutes.teacherPhotosNews => _groupMenuPlaceholder(
        settings,
        'Photos News',
      ),
      AppRoutes.teacherClassTimetable => _groupMenuPlaceholder(
        settings,
        'Class Timetable',
      ),
      AppRoutes.teacherClassPlanner => _groupMenuPlaceholder(
        settings,
        'Class Planner',
      ),
      AppRoutes.teacherVideoConference => _groupMenuPlaceholder(
        settings,
        'Video Conf',
      ),
      AppRoutes.teacherClassFilePlan => _groupMenuPlaceholder(
        settings,
        'Class File/Plan',
      ),
      AppRoutes.teacherOnlineAssignment => _groupMenuPlaceholder(
        settings,
        'Online Assignment',
      ),
      AppRoutes.teacherOnlineAssessment => _groupMenuPlaceholder(
        settings,
        'Online Assessment',
      ),
      AppRoutes.teacherGroupInfoEdit => (() {
        final group = settings.arguments as dynamic;
        return GroupInfoEditPage(group: group is Group ? group : Group(id: 'unknown', name: 'Unknown'));
      })(),
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
      _ => const SplashScreen(),
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

  static Widget _groupMenuPlaceholder(RouteSettings settings, String title) {
    final group = settings.arguments as dynamic;
    return GroupMenuPlaceholderPage(title: title, group: group);
  }
}
