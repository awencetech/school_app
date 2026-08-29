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
    this.message,
  });

  final String groupId;
  final String groupName;
  final String groupYear;
  final GroupMessage? message;

  @override
  State<GroupMessagesEditPage> createState() => _GroupMessagesEditPageState();
}

class _GroupMessagesEditPageState extends State<GroupMessagesEditPage> {
  final GroupMessageService _service = GroupMessageService();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TextEditingController _expiryDateController;
  String _selectedMessageType = 'General';
  String _selectedPriority = 'Normal';
  Set<String> _selectedAudience = {};
  String? _titleError;
  String? _messageError;
  String? _submitError;
  bool _isSaving = false;
  bool _isEdit = false;

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
  void initState() {
    super.initState();
    _isEdit = widget.message != null;
    if (_isEdit) {
      _titleController = TextEditingController(text: widget.message!.title);
      _messageController = TextEditingController(text: widget.message!.content);
      _expiryDateController = TextEditingController(text: widget.message!.expiryDate ?? '');
      _selectedMessageType = widget.message!.messageType.isEmpty
          ? widget.message!.category
          : widget.message!.messageType;
      _selectedPriority = widget.message!.priority;
      _selectedAudience = Set<String>.from(widget.message!.audience);
    } else {
      _titleController = TextEditingController();
      _messageController = TextEditingController();
      _expiryDateController = TextEditingController();
    }
  }

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
      if (_isEdit) {
        await _service.updateMessage(
          groupId: widget.groupId,
          messageId: widget.message!.id,
          title: _titleController.text.trim(),
          messageType: _selectedMessageType,
          message: _messageController.text.trim(),
          priority: _selectedPriority,
          audience: _selectedAudience.toList(),
          expiryDate: _expiryDateController.text.trim().isEmpty
              ? null
              : _expiryDateController.text.trim(),
        );
      } else {
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
          expiryDate: _expiryDateController.text.trim().isEmpty
              ? null
              : _expiryDateController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Message updated successfully.' : 'Message created successfully.'),
        ),
      );
      Navigator.of(context).pop(true); // Return true to signal refresh
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = 'Unable to save message: $error';
      });
    }
  }

  Future<void> _deleteMessage() async {
    if (!_isEdit) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _service.deleteMessage(
        groupId: widget.groupId,
        messageId: widget.message!.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully.')),
      );
      Navigator.of(context).pop(true); // Return true to signal refresh
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = 'Unable to delete message: $error';
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _expiryDateController.text = selectedDate.toString().split(' ')[0];
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
          'Group Message',
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
        actions: [
          if (!_isEdit)
            IconButton(
              onPressed: _isSaving ? null : _validateAndSave,
              icon: const Icon(Icons.add, color: AppColors.white),
              tooltip: 'Add message',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Group Message' : 'Create Group Message',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.groupName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),
              // Title Field
              Text(
                'Message Title',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
              // Message Field
              Text(
                'Message',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
              // Message Type
              Text(
                'Message Type',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                    onSelected: (selected) {
                      setState(() {
                        _selectedMessageType = type;
                      });
                    },
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
              // Priority
              Text(
                'Priority',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
                    onSelected: (selected) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
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
              // Audience
              Text(
                'Message Visibility',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
              // Expiry Date
              Text(
                'Expiry Date (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
              // Error message
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
              // Save Button
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Message' : 'Add Message',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _deleteMessage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Delete Message',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
