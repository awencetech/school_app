import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../widgets/appbar/custom_app_bar.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../achievements/achievements_screen.dart';
import '../login/login_screen.dart';
import '../school/school_screen.dart';
import '../support/support_screen.dart';
import 'home_screen.dart';

/// Main scaffold hosting the bottom navigation pages.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final showAppBar = state.bottomNavIndex != 4;

        final schoolConfig = context.watch<SchoolConfigService>();

        return Scaffold(
          appBar: showAppBar ? CustomAppBar(title: schoolConfig.schoolName) : null,
          body: SafeArea(
            child: IndexedStack(
              index: state.bottomNavIndex,
              children: const [
                HomeScreen(),
                SchoolScreen(),
                AchievementsScreen(),
                SupportScreen(),
                LoginScreen(),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavigation(),
        );
      },
    );
  }
}

