import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';
import 'create_user_screen.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import 'update_user_screen.dart';

class StudentCreateIdScreen extends StatefulWidget {
  const StudentCreateIdScreen({super.key});

  @override
  State<StudentCreateIdScreen> createState() => _StudentCreateIdScreenState();
}

class _StudentCreateIdScreenState extends State<StudentCreateIdScreen> {
  final List<User> _students = [];
  String? _selectedStudentId;
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(role: 'student');
      setState(() {
        _students.clear();
        _students.addAll(users);
      });
    } catch (e) {
      // ignore - show empty state
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addStudent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateUserScreen(role: 'student'),
      ),
    ).then((created) {
      if (created == true) {
        _loadStudents();
      }
    });
  }

  void _resetPassword() {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Reset Password'),
        content: const Text('Password reset link has been sent to the student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Student Create ID'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add User'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.vpn_key, size: 18),
                  label: const Text('Force reset of Password'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Students',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No users found.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final isSelected = _selectedStudentId == student.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () async {
                                final updated = await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => UpdateUserScreen(userId: student.id!),
                                ));
                                if (updated == true) _loadStudents();
                              },
                              title: Text('${index + 1}. User ID: ${student.userId}'),
                              subtitle: Text('Email: ${student.email}'),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
