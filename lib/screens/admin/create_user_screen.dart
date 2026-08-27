import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/textfields/custom_text_field.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class CreateUserScreen extends StatefulWidget {
  final String role; // 'student', 'staff', or 'admin'

  const CreateUserScreen({
    super.key,
    required this.role,
  });

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  int _currentStep = 1;
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isLoading = false;

  final UserService _userService = UserService();

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidUserId(String userId) {
    if (userId.isEmpty) {
      setState(() => _errorMessage = 'User ID is required.');
      return false;
    }
    setState(() => _errorMessage = '');
    return true;
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required.');
      return false;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return false;
    }
    setState(() => _errorMessage = '');
    return true;
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required.');
      return false;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return false;
    }
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"<>?/\\|`~]'));

    if (!hasUppercase) {
      setState(() => _errorMessage = 'Password must contain at least one uppercase letter.');
      return false;
    }
    if (!hasLowercase) {
      setState(() => _errorMessage = 'Password must contain at least one lowercase letter.');
      return false;
    }
    if (!hasDigit) {
      setState(() => _errorMessage = 'Password must contain at least one digit.');
      return false;
    }
    if (!hasSpecial) {
      setState(() => _errorMessage = 'Password must contain at least one special character.');
      return false;
    }

    setState(() => _errorMessage = '');
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Oops...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Success!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Text('${widget.role.capitalize()} user created successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _returnToPreviousPage();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_isValidUserId(_userIdController.text.trim())) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_isValidEmail(_emailController.text.trim())) {
        setState(() => _currentStep = 3);
      }
    } else if (_currentStep == 3) {
      if (_isValidPassword(_passwordController.text)) {
        _createUser();
      }
    }
  }

  Future<void> _createUser() async {
    setState(() => _isLoading = true);

    try {
      final created = await _userService.createUser(
        userId: _userIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.role,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle ApiException specially
        // ignore: avoid_print
        print('Create user error: ${e.toString()}');
        if (e is ApiException) {
          // Show backend-provided message for duplicate handling
          final msg = e.message;
          _showErrorDialog(msg);
        } else {
          _showErrorDialog('Unable to create user. Please try again.');
        }
      }
    }
  }

  void _returnToPreviousPage() {
    // Store the newly created user in a simple list for demo
    // In real app, this would be fetched from backend

    if (widget.role == 'student') {
      Navigator.of(context).pop(true); // Signal to refresh student list
    } else if (widget.role == 'staff') {
      Navigator.of(context).pop(true);
    } else if (widget.role == 'admin') {
      Navigator.of(context).pop(true);
    }
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            width: 40,
            height: 2,
            color: _currentStep >= 2 ? Colors.blue : Colors.grey[300],
          ),
        ),
        _buildStep(2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            width: 40,
            height: 2,
            color: _currentStep >= 3 ? Colors.blue : Colors.grey[300],
          ),
        ),
        _buildStep(3),
      ],
    );
  }

  Widget _buildStep(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Create User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 40),
            if (_currentStep == 1) ...[
              Text(
                'Create UserId',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enter a unique userId - Let users create the UserID if possible',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  hintText: 'Enter User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
              ),
            ] else if (_currentStep == 2) ...[
              Text(
                'Enter Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Email has to be unique',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
              ),
            ] else if (_currentStep == 3) ...[
              Text(
                'Enter Password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Dont make it simple',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: '',
                hintText: 'Enter Password',
                controller: _passwordController,
                obscureText: true,
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Password requirements:\n• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One digit\n• One special character',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.left,
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _nextStep,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_currentStep == 3 ? 'Create' : 'Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
