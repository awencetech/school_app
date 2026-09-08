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

  static const _userGroups = [
    _MessageGroup(
      'UNI Route Z1',
      'UNI Route Z1\n2025(2025)',
      'MOHAMED TAJDEEHEN R in UNI Route Z1 2025(2025)',
    ),
  ];

  static const _studentGroups = [
    _MessageGroup(
      '10 C Grade 10 C',
      '10 C Grade 10 C -\n2026-27 (2026)',
      'MOHAMED AZEEMSHA A in 10 C Grade 10 C - 2026-27 (2026)',
    ),
    _MessageGroup(
      'UNI-Route Z2',
      'UNI-Route Z2\nUN Route 2026-27',
      'Parent of MOHAMED AZEEMSHA A in UNI-Route-Z2 UNI Route Z2 2026(2026)',
    ),
    _MessageGroup(
      'SP7 UNI - Route',
      'SP7 UNI - Route\nS7 - 2025(2026)',
      'MOHAMED AZEEMSHA A in SP7 UNI - Route SP7 - 2025(2026)',
    ),
  ];

  void _selectGroup(BuildContext context, _MessageGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _StaffMessageComposePage(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (studentMode) {
      return _StudentWriteMessageForm(
        title: quickAccessTitle ?? 'Write Message',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
        appBar: quickAccessTitle != null
          ? QuickAccessAppBar(title: quickAccessTitle!)
          : AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Write Message',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 17, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Write Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff444444),
                        ),
                      ),
                      InkWell(
                        onTap: () => navigateBack(context),
                        child: const Icon(
                          Icons.close,
                          size: 19,
                          color: Color(0xff333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'First Select a group or class to Write a Message',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groups/Classes of MOHAMED TAJDEEHEN R',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 4),
                  _GroupRow(
                    groups: _userGroups,
                    onTap: (group) => _selectGroup(context, group),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groups/Classes of Student MOHAMED AZEEMSHA A',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 4),
                  _GroupRow(
                    groups: _studentGroups,
                    onTap: (group) => _selectGroup(context, group),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _MessageGroup {
  const _MessageGroup(this.title, this.subtitle, this.messageHeading);

  final String title;
  final String subtitle;
  final String messageHeading;
}

class _StaffMessageComposePage extends StatefulWidget {
  const _StaffMessageComposePage({required this.group});

  final _MessageGroup group;

  @override
  State<_StaffMessageComposePage> createState() =>
      _StaffMessageComposePageState();
}

class _StaffMessageComposePageState extends State<_StaffMessageComposePage> {
  String _selectedMessageType = '(Select One)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
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
            Text(
              widget.group.messageHeading,
              style: const TextStyle(fontSize: 11, height: 1.25),
            ),
            const Text(
              'Message for',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedMessageType,
              isExpanded: true,
              iconSize: 15,
              style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  borderSide: BorderSide(color: Color(0xffcccccc)),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: '(Select One)',
                  child: Text('(Select One)'),
                ),
                DropdownMenuItem(value: 'School', child: Text('School')),
                DropdownMenuItem(value: 'Class/es', child: Text('Class/es')),
                DropdownMenuItem(value: 'Teacher/s', child: Text('Teacher/s')),
                DropdownMenuItem(value: 'Student/s', child: Text('Student/s')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMessageType = value);
                }
              },
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 19,
                width: 29,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xff087ff5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text('Send', style: TextStyle(fontSize: 8)),
                ),
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

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.groups, required this.onTap});

  final List<_MessageGroup> groups;
  final ValueChanged<_MessageGroup> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups
          .map(
            (group) => SizedBox(
              width: 72,
              child: InkWell(
                onTap: () => onTap(group),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.directions_bus_filled,
                        size: 28,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7,
                          height: 1.15,
                          color: Color(0xff777777),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
