import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/group_message.dart';
import '../../services/app_state.dart';
import '../../services/group_message_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupMessagesEditPage extends StatefulWidget {
  const GroupMessagesEditPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<GroupMessagesEditPage> createState() => _GroupMessagesEditPageState();
}

class _GroupMessagesEditPageState extends State<GroupMessagesEditPage> {
  final GroupMessageService _service = GroupMessageService();
  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _displayGroupName {
    final raw = widget.groupName.trim();
    if (raw.isNotEmpty && raw.toLowerCase() != 'unknown') {
      return raw;
    }
    return widget.groupId.trim().isNotEmpty ? widget.groupId : 'Group';
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await _service.getMessages(widget.groupId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load messages.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddMessagePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddGroupMessagePage(
          groupId: widget.groupId,
          groupName: _displayGroupName,
          groupYear: widget.groupYear,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(
          'Group Messages',
          style: AppTextStyles.appTitle.copyWith(fontSize: 16),
        ),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_errorMessage!),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      children: [
                        Text(
                          'Group Message Details',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _displayGroupName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_messages.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text('No messages available yet.'),
                          )
                        else
                          ..._messages.map(_buildMessageCard),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMessagePage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _buildMessageCard(GroupMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.messageType.isEmpty ? message.category : message.messageType,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              if (message.priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(message.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.priority,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(message.priority),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TeacherNameBadge(
            teacherName: _teacherDisplayName(message),
          ),
          const SizedBox(height: 10),
          Text(
            message.title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Like ${message.likedBy.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Comments ${message.comments.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(message.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _teacherDisplayName(GroupMessage message) {
    final senderName = message.senderName.trim();
    if (senderName.isNotEmpty && senderName.toLowerCase() != 'user') {
      return senderName;
    }
    final authorRole = message.authorRole.trim();
    if (authorRole.isNotEmpty && authorRole.toLowerCase() != 'unknown') {
      return authorRole[0].toUpperCase() + authorRole.substring(1);
    }
    return 'Teacher';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Normal':
        return Colors.grey;
      case 'Important':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TeacherNameBadge extends StatelessWidget {
  const TeacherNameBadge({
    super.key,
    required this.teacherName,
  });

  final String teacherName;

  @override
  Widget build(BuildContext context) {
    final displayName = teacherName.trim();
    final label = displayName.isEmpty ? 'Teacher' : displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGroupMessagePage extends StatefulWidget {
  const _AddGroupMessagePage({
    required this.groupId,
    required this.groupName,
    required this.groupYear,
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<_AddGroupMessagePage> createState() => _AddGroupMessagePageState();
}

class _AddGroupMessagePageState extends State<_AddGroupMessagePage> {
  final GroupMessageService _service = GroupMessageService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final Set<String> _selectedAudience = {'All Group Members'};
  String _selectedMessageType = 'General';
  String _selectedPriority = 'Normal';
  bool _allowComments = true;
  bool _isSaving = false;
  String? _titleError;
  String? _messageError;
  String? _submitError;

  static const List<String> _messageTypes = [
    'General',
    'Important',
    'Announcement',
    'Homework',
    'Event',
    'Reminder',
  ];

  static const List<String> _priorities = [
    'Normal',
    'Important',
    'Urgent',
  ];

  static const List<String> _audienceOptions = [
    'All Group Members',
    'Students',
    'Staff/Teachers',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty ? 'Title is required' : null;
      _messageError = _messageController.text.trim().isEmpty ? 'Message is required' : null;
      _submitError = null;
    });

    if (_titleError != null || _messageError != null) {
      return;
    }

    _saveMessage();
  }

  Future<void> _saveMessage() async {
    final appState = context.read<AppState>();
    setState(() => _isSaving = true);

    try {
      await _service.createMessage(
        groupId: widget.groupId,
        groupName: widget.groupName,
        title: _titleController.text.trim(),
        messageType: _selectedMessageType,
        message: _messageController.text.trim(),
        senderId: appState.currentUserId ?? '',
        senderName: appState.currentUserEmail ?? appState.currentUserId ?? 'User',
        senderRole: appState.currentUserRole ?? '',
        priority: _selectedPriority,
        audience: _selectedAudience.toList(),
        allowComments: _allowComments,
        expiryDate: _expiryDateController.text.trim().isEmpty ? null : _expiryDateController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message created successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = 'Unable to save message: $error';
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _expiryDateController.text = selectedDate.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(
          'Create Group Message',
          style: AppTextStyles.appTitle.copyWith(fontSize: 16),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
                'group-classes / group-messages-edit / add-message',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MESSAGE TITLE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter message title',
                  errorText: _titleError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'MESSAGE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your message here',
                  errorText: _messageError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (_) {
                  if (_messageError != null) {
                    setState(() => _messageError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'MESSAGE TYPE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _messageTypes.map((type) {
                  final isSelected = _selectedMessageType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMessageType = type),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.secondaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'PRIORITY',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priorities.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return FilterChip(
                    label: Text(priority),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedPriority = priority),
                    backgroundColor: Colors.white,
                    selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? _getPriorityColor(priority) : AppColors.secondaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? _getPriorityColor(priority) : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'MESSAGE VISIBILITY',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ..._audienceOptions.map((audience) {
                final isSelected = _selectedAudience.contains(audience);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedAudience.add(audience);
                      } else {
                        _selectedAudience.remove(audience);
                      }
                    });
                  },
                  title: Text(audience),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ALLOW COMMENTS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Switch(
                    value: _allowComments,
                    onChanged: (value) => setState(() => _allowComments = value),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'EXPIRY DATE (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expiryDateController,
                readOnly: true,
                onTap: _selectExpiryDate,
                decoration: InputDecoration(
                  hintText: 'Select expiry date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _submitError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _validateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_alt, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SAVE MESSAGE',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Normal':
        return Colors.grey;
      case 'Important':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
