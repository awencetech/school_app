import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/textfields/custom_text_field.dart';

/// Login tab screen with username/password fields and sign-in/register actions.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const _studentUsername = 'StudentC@11';
  static const _studentPassword = 'Studend123#';
  static const _staffUsername = 'StaffC@22';
  static const _staffPassword = 'Staff123#';
  static const _adminUsername = 'AdminC@33';
  static const _adminPassword = 'Admin123#';

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_refreshLoginState);
    _passwordController.addListener(_refreshLoginState);
  }

  void _refreshLoginState() {
    setState(() {});
  }

  void _handleSignIn() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == _studentUsername && password == _studentPassword) {
      context.read<AppState>().setLoggedIn(true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.studentDashboard,
        (route) => false,
      );
      return;
    }

    if (username == _staffUsername && password == _staffPassword) {
      context.read<AppState>().setLoggedIn(true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.staffDashboard,
        (route) => false,
      );
      return;
    }

    if (username == _adminUsername && password == _adminPassword) {
      context.read<AppState>().setLoggedIn(true);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.adminDashboard,
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid username or password')),
    );
  }

  @override
  void dispose() {
    _usernameController.removeListener(_refreshLoginState);
    _passwordController.removeListener(_refreshLoginState);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoginEnabled = _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    final config = context.watch<SchoolConfigService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              width: double.infinity,
              color: AppColors.primary,
              alignment: Alignment.center,
              child: Text(
                config.schoolName,
                style: AppTextStyles.appTitle,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'School name',
                            style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username or email',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.forgotPassword),
                            child: Text(
                              'Forgot your password?',
                              style: AppTextStyles.body.copyWith(color: AppColors.blueButton),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SecondaryButton(
                          label: 'Sign In',
                          onPressed: isLoginEnabled ? _handleSignIn : null,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.createAccount),
                          child: Text(
                            'Don\'t have an account? Register',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Register',
                          backgroundColor: AppColors.orangeButton,
                          textColor: AppColors.white,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.createAccount),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Contact our school to get information about registration',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

