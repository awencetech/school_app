import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminWriteMessagePage extends StatefulWidget {
  const AdminWriteMessagePage({super.key});

  @override
  State<AdminWriteMessagePage> createState() => _AdminWriteMessagePageState();
}

class _AdminWriteMessagePageState extends State<AdminWriteMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _service = AdminMessageService();
  static const _types = ['General', 'Important', 'Announcement', 'Reminder'];
  String _type = 'General';
  bool _students = true;
  bool _staff = false;
  bool _sending = false;
  String? _error;
  List<Group> _groups = [];
  Group? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_changed);
    _messageController.addListener(_changed);
    _loadGroups();
  }

  void _changed() => setState(() {});

  Future<void> _loadGroups() async {
    try {
      final groups = await _service.getGroups();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_students && !_staff) {
      setState(() => _error = 'Please select Students or Staff/Teachers.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Message?'),
        content: Text(
          'Are you sure you want to send this message to:\n'
          '${_students ? '✓ Students\n' : ''}${_staff ? '✓ Staff / Teachers' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.createMessage(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        messageType: _type,
        sendToStudents: _students,
        sendToStaff: _staff,
        groupId: _selectedGroup?.id,
        groupName: _selectedGroup?.name ?? 'All Groups',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _type = 'General';
        _students = true;
        _staff = false;
        _selectedGroup = null;
        _sending = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Unable to send message. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminName = (context.read<AppState>().currentUserEmail ?? '')
        .split('@')
        .first;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Write Message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _panel(
              Icons.admin_panel_settings,
              'From',
              '${adminName.isEmpty ? 'Admin' : adminName}  •  Administrator',
            ),
            const SizedBox(height: 18),
            const _Heading('Message Subject'),
            TextFormField(
              controller: _subjectController,
              decoration: _decoration('Enter message subject'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Subject cannot be empty.'
                  : null,
            ),
            const SizedBox(height: 16),
            const _Heading('Message Content'),
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              decoration: _decoration('Type your message here...'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Message content cannot be empty.'
                  : null,
            ),
            const SizedBox(height: 16),
            const _Heading('Message Type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: _type == value,
                      onSelected: (_) => setState(() => _type = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const _Heading('Send To'),
            const SizedBox(height: 8),
            _recipient(
              'Students',
              _students,
              (value) => setState(() => _students = value),
            ),
            _recipient(
              'Staff / Teachers',
              _staff,
              (value) => setState(() => _staff = value),
            ),
            const SizedBox(height: 12),
            const _Heading('Send To Group / Class'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Group?>(
              initialValue: _selectedGroup,
              isExpanded: true,
              decoration: _decoration('All Groups'),
              items: [
                const DropdownMenuItem<Group?>(
                  value: null,
                  child: Text('All Groups'),
                ),
                ..._groups.map(
                  (group) => DropdownMenuItem<Group?>(
                    value: group,
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedGroup = value),
            ),
            const SizedBox(height: 18),
            _preview(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Sending...' : 'Send Message'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/admin-dashboard', (route) => false);
          }
        },
      ),
    );
  }

  Widget _panel(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.hintText, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _recipient(
    String label,
    bool selected,
    ValueChanged<bool> onChanged,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      title: Text(label),
      secondary: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? Colors.green : AppColors.hintText,
      ),
    ),
  );

  Widget _preview() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message Preview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _type,
          style: TextStyle(
            color: _type == 'Important' ? Colors.red : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subjectController.text.isEmpty ? 'Subject' : _subjectController.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        const Text('From: Admin'),
        const SizedBox(height: 8),
        Text(
          _messageController.text.isEmpty
              ? 'Your message will appear here.'
              : _messageController.text,
        ),
        const SizedBox(height: 8),
        Text(
          'Sent to: ${[_students ? 'Students' : '', _staff ? 'Staff / Teachers' : ''].where((value) => value.isNotEmpty).join(', ')}',
        ),
        const SizedBox(height: 4),
        Text('Class: ${_selectedGroup?.name ?? 'All Groups'}'),
      ],
    ),
  );

  static InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    ),
  );
}
