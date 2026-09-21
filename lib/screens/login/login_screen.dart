import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/user_service.dart';
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
  bool _isLoading = false;
  bool _isGoogleLoading = false;

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
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    setState(() => _isLoading = true);
    final svc = UserService();
    svc
        .login(identifier: identifier, password: password)
        .then((user) async {
          if (!mounted) return;

          try {
            final firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken();
            final authEmail = (user.email ?? '').trim().isNotEmpty ? user.email!.trim() : identifier;
            final authorization = await svc.checkEmailAuthorization(
              email: authEmail,
              firebaseIdToken: firebaseIdToken,
            );

            if (authorization['authorized'] != true) {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    authorization['message']?.toString() ??
                        'Your email is not registered with the school. Please contact the school administration.',
                  ),
                ),
              );
              return;
            }

            final authorizedRole = authorization['role']?.toString() ?? user.role;
            await context.read<AppState>().setAuthenticatedUser(
              userId: user.userId,
              email: user.email,
              role: authorizedRole,
              token: user.token,
            );

            if (!mounted) return;
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            if (authorizedRole == 'student') {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.studentDashboard,
                (route) => false,
              );
            } else if (authorizedRole == 'staff') {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.staffDashboard,
                (route) => false,
              );
            } else if (authorizedRole == 'admin') {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
            } else {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n?.invalidUserRole ?? 'Invalid user role')),
              );
            }
          } catch (e, stackTrace) {
            debugPrint('Email authorization check failed: $e');
            debugPrintStack(stackTrace: stackTrace);
            if (!mounted) return;
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your email is not registered with the school. Please contact the school administration.',
                ),
              ),
            );
          }
        })
        .catchError((e) {
          if (!mounted) return;
          // Log error for debugging but show generic message to user
          debugPrint('Login error: $e');
          String message = l10n?.invalidCredentials ?? 'Invalid credentials';
          if (e is! Exception) {
            message = l10n?.connectionError ?? 'Connection error';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        })
        .whenComplete(() {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});

        final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final user = userCredential.user;

        if (user == null) {
          throw FirebaseAuthException(
            code: 'sign_in_failed',
            message: 'Google sign-in completed without a Firebase user.',
          );
        }

        await _authorizeAuthenticatedUser(user);
        return;
      }

      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'sign_in_failed',
          message: 'Google sign-in completed without a Firebase user.',
        );
      }

      await _authorizeAuthenticatedUser(user);
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Firebase Auth Error: ${e.code}');
      debugPrint('Firebase Auth Message: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.message ?? e.code}')),
      );
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _authorizeAuthenticatedUser(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing_email',
        message: 'No email is available for this Firebase user.',
      );
    }

    final firebaseIdToken = await user.getIdToken();
    final authorization = await UserService().checkEmailAuthorization(
      email: email,
      firebaseIdToken: firebaseIdToken,
    );

    if (authorization['authorized'] != true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authorization['message']?.toString() ??
                'Your email is not registered with the school. Please contact the school administration.',
          ),
        ),
      );
      return;
    }

    final role = authorization['role']?.toString() ?? 'student';
    await context.read<AppState>().setAuthenticatedUser(
      userId: user.uid,
      email: email,
      role: role,
      token: user.uid,
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.studentDashboard,
      (route) => false,
    );
  }

  Future<void> _completeGoogleLogin(User user) async {
    final email = (user.email ?? user.displayName ?? 'google-user').trim();
    final userId = user.uid.isNotEmpty ? user.uid : email.split('@').first;

    await context.read<AppState>().setAuthenticatedUser(
      userId: userId,
      email: email,
      role: 'student',
      token: user.uid,
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.studentDashboard,
      (route) => false,
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
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    final isLoginEnabled =
        _usernameController.text.trim().isNotEmpty &&
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(config.schoolName, style: AppTextStyles.appTitle),
                  Positioned(
                    right: 4,
                    child: IconButton(
                      tooltip: 'Change language',
                      icon: const Icon(Icons.language),
                      color: AppColors.white,
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.language,
                      ),
                    ),
                  ),
                ],
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
                            l10n?.schoolName ?? 'School name',
                            style: AppTextStyles.pageTitle.copyWith(
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _usernameController,
                          label: l10n?.usernameOrEmail ?? 'Username or email',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: l10n?.password ?? 'Password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.forgotPassword),
                            child: Text(
                              l10n?.forgotPassword ?? 'Forgot your password?',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.blueButton,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.border),
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA4335),
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            label: Text(
                              _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: _isLoading ? (l10n?.signingIn ?? 'Signing in') : (l10n?.signIn ?? 'Sign In'),
                          onPressed: isLoginEnabled && !_isLoading
                              ? _handleSignIn
                              : null,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.createAccount),
                          child: Text(
                            l10n?.accountRegisterPrompt ?? 'Don\'t have an account? Register',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: l10n?.register ?? 'Register',
                          backgroundColor: AppColors.orangeButton,
                          textColor: AppColors.white,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.createAccount),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            l10n?.registrationInfo ?? 'Contact our school to get information about registration',
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
