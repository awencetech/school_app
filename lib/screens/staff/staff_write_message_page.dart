import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';

class StaffWriteMessagePage extends StatelessWidget {
  const StaffWriteMessagePage({
    super.key,
    this.quickAccessTitle,
    this.studentMode = false,
  });

  final String? quickAccessTitle;
  final bool studentMode;

  @override
  Widget build(BuildContext context) {
    if (studentMode) {
      return _StudentWriteMessageForm(
        title: quickAccessTitle ?? 'Write Message',
      );
    }
    return const StaffMessageComposePage(
      group: StaffMessageGroup('All Groups', '', ''),
    );
  }
}

class _StudentWriteMessageForm extends StatefulWidget {
  const _StudentWriteMessageForm({required this.title});

  final String title;

  @override
  State<_StudentWriteMessageForm> createState() =>
      _StudentWriteMessageFormState();
}

class _StudentWriteMessageFormState extends State<_StudentWriteMessageForm> {
  final _service = AdminMessageService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _error;

  String get _username {
    final appState = context.read<AppState>();
    final username = (appState.currentUserId ?? '').trim();
    return username.isEmpty ? 'Student' : username;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    final appState = context.read<AppState>();
    String? error;
    if (subject.isEmpty) error = 'Please enter a subject.';
    if (message.isEmpty) error = 'Please enter a message.';
    if ((appState.currentUserId ?? '').trim().isEmpty) {
      error = 'Your student account is missing. Please log in again.';
    }
    if ((appState.currentUserRole ?? '').trim().toLowerCase() != 'student') {
      error = 'Only students can send messages from this page.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await _service.createStudentMessage(
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Message sent'),
          content: const Text('Your message was saved successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.studentDashboardMessages,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Unable to send message. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: QuickAccessAppBar(title: widget.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Write Message',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text(
                'From',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Color(0xff555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_messageController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Message Preview',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff7f8fc),
                    border: Border.all(color: Color(0xffdddddd)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _messageController.text,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.main,
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Quick Menu',
          ),
        ],
      ),
    );
  }
}

class StaffMessageGroup {
  const StaffMessageGroup(this.title, this.subtitle, this.messageHeading);

  final String title;
  final String subtitle;
  final String messageHeading;
}

class StaffMessageComposePage extends StatefulWidget {
  const StaffMessageComposePage({super.key, required this.group});

  final StaffMessageGroup group;

  @override
  State<StaffMessageComposePage> createState() =>
      _StaffMessageComposePageState();
}

class _StaffMessageComposePageState extends State<StaffMessageComposePage> {
  final _service = AdminMessageService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _error;

  String get _username {
    final username = (context.read<AppState>().currentUserId ?? '').trim();
    return username.isEmpty ? 'Staff' : username;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(() => _error = 'Please enter a subject and message.');
      return;
    }
    final appState = context.read<AppState>();
    if ((appState.currentUserId ?? '').trim().isEmpty ||
        (appState.currentUserRole ?? '').trim().toLowerCase() != 'staff') {
      setState(() => _error = 'Please log in with a staff account.');
      return;
    }
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await _service.createStaffMessage(
        subject: subject,
        message: message,
        groupName: widget.group.title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.staffDashboard);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const QuickAccessAppBar(title: 'Write Message'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Write Message',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 9),
            const Text(
              'From',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Staff',
                  style: TextStyle(fontSize: 11, color: Color(0xff555555)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_messageController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Message Preview',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xfff7f8fc),
                  border: Border.all(color: const Color(0xffdddddd)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _messageController.text,
                  style: const TextStyle(fontSize: 10, height: 1.3),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 10)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Quick Menu',
          ),
        ],
      ),
    );
  }
}

