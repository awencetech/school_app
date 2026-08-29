import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';

class UpdateUserScreen extends StatefulWidget {
  final String userId;

  const UpdateUserScreen({super.key, required this.userId});

  @override
  State<UpdateUserScreen> createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final u = await _userService.getUserById(widget.userId);
      setState(() {
        _user = u;
        _emailController.text = u.email;
      });
    } catch (e) {
      if (mounted) {
        _showError('Unable to load user: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Oops...'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Success!'),
        content: const Text('User updated successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _userService.updateUser(widget.userId, email: email, password: password.isEmpty ? null : password);
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (mounted) _showError('Something went wrong! ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Update User'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: TextEditingController(text: _user?.userId ?? ''),
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'User ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (leave empty to keep existing)'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: const Text('Save / Update'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: (_isSaving || _isDeleting)
                          ? null
                          : () async {
                              // confirmation
                              final should = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext dialogContext) => AlertDialog(
                                  title: const Text('Delete User?'),
                                  content: Text(
                                      'Are you sure you want to permanently delete this user?\n\nUser ID: ${_user?.userId ?? ''}\nEmail: ${_user?.email ?? ''}'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (!mounted || should != true) return;

                              setState(() => _isDeleting = true);

                              try {
                                await _userService.deleteUser(widget.userId);
                                if (!mounted) return;
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User deleted successfully')),
                                  );
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop(true);
                                  }
                                }
                              } catch (e) {
                                if (mounted) _showError('Failed to delete user: ${e.toString()}');
                              } finally {
                                if (mounted) setState(() => _isDeleting = false);
                              }
                            },
                      child: _isDeleting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Delete User'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
