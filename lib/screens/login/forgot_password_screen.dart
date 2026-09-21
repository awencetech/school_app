import 'dart:math';

import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/textfields/custom_text_field.dart';

enum _ForgotPasswordStep { email, otp, reset }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  bool _isLoading = false;
  int _generatedOtp = 0;
  String? _emailError;
  String? _otpError;
  String? _passwordError;

  bool get _isValidGmail {
    final email = _emailController.text.trim();
    return RegExp(r'^[A-Za-z0-9._%+-]+@gmail\.com$', caseSensitive: false)
        .hasMatch(email);
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!_isValidGmail) {
      setState(() => _emailError = 'Enter a valid Gmail address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      final user = await UserService().getUserByEmail(email);
      if (user == null) {
        setState(() => _emailError = 'No account found for this Gmail address.');
        return;
      }

      _generatedOtp = Random().nextInt(900000) + 100000;
      _step = _ForgotPasswordStep.otp;
      _otpController.clear();
      _otpError = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $email. Demo code: $_generatedOtp'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send OTP: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty) {
      setState(() => _otpError = 'Enter the OTP code.');
      return;
    }
    if (enteredOtp != _generatedOtp.toString()) {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
      return;
    }
    setState(() {
      _otpError = null;
      _step = _ForgotPasswordStep.reset;
    });
  }

  Future<void> _saveNewPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      final user = await UserService().getUserByEmail(_emailController.text.trim());
      if (user == null) {
        setState(() => _passwordError = 'User not found. Please check your email.');
        return;
      }

      await UserService().updateUser(user.userId, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password saved successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save password: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: const Text('SCHOOL NAME'),
        titleTextStyle: AppTextStyles.appTitle,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Recover Your Password',
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_step == _ForgotPasswordStep.email) ...[
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hintText: 'name@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _emailError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isLoading ? 'Sending...' : 'Send OTP',
                      backgroundColor: AppColors.orangeButton,
                      textColor: AppColors.white,
                      onPressed: _isLoading ? null : _sendOtp,
                    ),
                  ] else if (_step == _ForgotPasswordStep.otp) ...[
                    CustomTextField(
                      controller: _otpController,
                      label: 'OTP',
                      hintText: 'Enter 6-digit OTP',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    if (_otpError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _otpError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Verify OTP',
                      backgroundColor: AppColors.orangeButton,
                      textColor: AppColors.white,
                      onPressed: _verifyOtp,
                    ),
                  ] else ...[
                    CustomTextField(
                      controller: _passwordController,
                      label: 'New password',
                      hintText: 'Enter new password',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hintText: 'Confirm password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _passwordError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isLoading ? 'Saving...' : 'Save Password',
                      backgroundColor: AppColors.orangeButton,
                      textColor: AppColors.white,
                      onPressed: _isLoading ? null : _saveNewPassword,
                    ),
                  ],
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 6),
                  Text(
                    'Contact your school if you face issues',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
