import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

/// Root widget for the School App.
class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'School App',
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}

