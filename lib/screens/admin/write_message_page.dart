import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/group_message_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class WriteMessagePage extends StatefulWidget {
  const WriteMessagePage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<WriteMessagePage> createState() => _WriteMessagePageState();
}

class _WriteMessagePageState extends State<WriteMessagePage> {
  final GroupMessageService _service = GroupMessageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  static const List<String> _messageTypes = [
    'General',
    'Important',
    'Homework',
    'Announcement',
  ];

  String _selectedMessageType = 'General';
  bool _isSending = false;
  String? _titleError;
  String? _contentError;
  String? _submitError;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String? get _studentName {
    final appState = context.read<AppState>();
    final email = (appState.currentUserEmail ?? '').trim();
    final id = (appState.currentUserId ?? '').trim();
    if (email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      return localPart.isNotEmpty ? localPart : 'Student';
    }
    return id.isEmpty ? 'Student' : id;
  }

  String? get _studentId => context.read<AppState>().currentUserId?.trim();

  bool get _hasCurrentGroup => widget.groupId.trim().isNotEmpty;

  bool get _hasLoggedInStudent => (_studentId ?? '').trim().isNotEmpty;

  Future<void> _sendMessage() async {
    setState(() {
      _hasSubmitted = true;
      _titleError = _titleController.text.trim().isEmpty ? 'Message title is required.' : null;
      _contentError = _contentController.text.trim().isEmpty ? 'Message content is required.' : null;
      _submitError = null;
    });

    if (_titleError != null || _contentError != null) {
      return;
    }

    if (!_hasCurrentGroup) {
      setState(() => _submitError = 'Current group is missing. Please reopen this group and try again.');
      return;
    }

    if (!_hasLoggedInStudent) {
      setState(() => _submitError = 'Student account is missing. Please login again.');
      return;
    }

    if (_isSending) return;

    final appState = context.read<AppState>();
    final userId = (appState.currentUserId ?? '').trim();
    final userEmail = (appState.currentUserEmail ?? '').trim();
    final role = (appState.currentUserRole ?? '').trim().toLowerCase();

    if (role != 'student') {
      setState(() => _submitError = 'Only students can send messages from this page.');
      return;
    }

    if (userId.isEmpty) {
      setState(() => _submitError = 'Logged-in student is missing. Please sign in again.');
      return;
    }

    setState(() => _isSending = true);

    try {
      await _service.createMessage(
        groupId: widget.groupId,
        groupName: widget.groupName,
        messageType: _selectedMessageType,
        title: _titleController.text.trim(),
        message: _contentController.text.trim(),
        senderId: userId,
        senderName: _studentName ?? 'Student',
        senderEmail: userEmail,
        senderRole: 'student',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );

      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedMessageType = 'General';
        _isSending = false;
        _titleError = null;
        _contentError = null;
        _submitError = null;
        _hasSubmitted = false;
      });

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _submitError = 'Unable to send message: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final studentName = (appState.currentUserEmail ?? appState.currentUserId ?? 'Student').trim();
    final studentEmail = (appState.currentUserEmail ?? '').trim();
    final studentId = (appState.currentUserId ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Write Message', style: AppTextStyles.appTitle.copyWith(fontSize: 16)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Message',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              _sectionHeader('Message Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _messageTypes.map((type) {
                  final selected = _selectedMessageType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedMessageType = type),
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.primaryText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _sectionHeader('Student Information'),
              const SizedBox(height: 8),
              _infoCard(
                label: 'Student Name',
                value: studentName.isEmpty ? 'Student' : studentName,
              ),
              const SizedBox(height: 8),
              _infoCard(
                label: 'Email',
                value: studentEmail.isEmpty ? 'Not available' : studentEmail,
              ),
              const SizedBox(height: 8),
              _infoCard(
                label: 'Student ID',
                value: studentId.isEmpty ? 'Not available' : studentId,
              ),
              const SizedBox(height: 18),
              _sectionHeader('Message Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: _fieldDecoration(hintText: 'Enter message title', errorText: _hasSubmitted ? _titleError : null),
                onChanged: (_) {
                  if (_hasSubmitted && _titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              const SizedBox(height: 18),
              _sectionHeader('Message Content'),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: _fieldDecoration(
                  hintText: 'Write your message here...',
                  errorText: _hasSubmitted ? _contentError : null,
                ),
                onChanged: (_) {
                  if (_hasSubmitted && _contentError != null) {
                    setState(() => _contentError = null);
                  }
                },
              ),
              const SizedBox(height: 18),
              _sectionHeader('Current Group'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.groupName.isEmpty ? 'Current group' : widget.groupName,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hasCurrentGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Group is required to send a message.',
                    style: AppTextStyles.body.copyWith(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _submitError!,
                    style: AppTextStyles.body.copyWith(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  label: _isSending
                      ? const Text('Sending...')
                      : const Text('Send Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      ),
    );
  }

  Widget _infoCard({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText, String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
