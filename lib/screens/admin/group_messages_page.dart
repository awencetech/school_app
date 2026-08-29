// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../models/group_message.dart';
import '../../services/app_state.dart';
import '../../services/group_message_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class GroupMessagesPage extends StatefulWidget {
  const GroupMessagesPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<GroupMessagesPage> createState() => _GroupMessagesPageState();
}

class _GroupMessagesPageState extends State<GroupMessagesPage> {
  final GroupMessageService _service = GroupMessageService();
  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedBottomIndex = 2;
  final Map<String, TextEditingController> _commentControllers = {};

  bool get _currentUserIsStudent {
    final role = context.read<AppState>().currentUserRole?.trim().toLowerCase() ?? '';
    return role == 'student' || role == 'students';
  }

  String? get _currentUserId => context.read<AppState>().currentUserId;

  String get _currentUserRole => context.read<AppState>().currentUserRole?.trim() ?? '';

  String? get _currentUserName => context.read<AppState>().currentUserEmail;
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
      _commentControllers.clear();
      for (final message in _messages) {
        _commentControllers[message.id] = TextEditingController();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load messages.';
      });
    }
  }

  Future<void> _toggleLike(GroupMessage message) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like messages.')),
      );
      return;
    }

    final index = _messages.indexWhere((item) => item.id == message.id);
    if (index == -1) return;

    final previous = _messages[index];
    final likedBy = Set<String>.from(previous.likedBy ?? []);
    final willLike = !likedBy.contains(userId);
    if (willLike) {
      likedBy.add(userId);
    } else {
      likedBy.remove(userId);
    }

    setState(() {
      _messages[index] = previous.copyWith(likedBy: likedBy.toList()..sort());
    });

    try {
      final result = await _service.toggleLike(
        groupId: widget.groupId,
        messageId: message.id,
        userId: userId,
      );
      final count = (result['likeCount'] is int) ? result['likeCount'] as int : likedBy.length;
      if (!mounted) return;
      setState(() {
        _messages[index] = previous.copyWith(
          likedBy: List<String>.from((result['likedBy'] is List) ? result['likedBy'] as List : likedBy.toList()),
        );
        if (count >= 0) {
          _messages[index] = _messages[index].copyWith(
            likedBy: List<String>.generate(count, (i) => (result['likedBy'] is List && i < (result['likedBy'] as List).length)
                ? (result['likedBy'] as List)[i].toString()
                : userId),
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages[index] = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update like. Please try again.')),
      );
    }
  }

  Future<void> _addComment(GroupMessage message) async {
    if (!_currentUserIsStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only students can add comments to this message.')),
      );
      return;
    }

    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a comment.')),
      );
      return;
    }

    final controller = _commentControllers[message.id];
    final input = (controller?.text ?? '').trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment first.')),
      );
      return;
    }

    final previous = message;
    final previousComments = List<GroupMessageComment>.from(message.comments);
    final optimisticComment = GroupMessageComment(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      studentId: userId,
      studentName: context.read<AppState>().currentUserEmail ?? 'Student',
      text: input,
      createdAt: DateTime.now(),
    );

    setState(() {
      final index = _messages.indexWhere((item) => item.id == message.id);
      if (index != -1) {
        _messages[index] = previous.copyWith(
          comments: [...previousComments, optimisticComment],
        );
      }
      controller?.clear();
    });

    try {
      final comment = await _service.addComment(
        groupId: widget.groupId,
        messageId: message.id,
        userId: userId,
        userRole: _currentUserRole,
        studentName: context.read<AppState>().currentUserEmail ?? 'Student',
        comment: input,
      );
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((item) => item.id == message.id);
        if (index != -1) {
          final updated = List<GroupMessageComment>.from(_messages[index].comments)
            ..removeWhere((item) => item.id == optimisticComment.id);
          updated.add(comment);
          _messages[index] = _messages[index].copyWith(comments: updated);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((item) => item.id == message.id);
        if (index != -1) {
          _messages[index] = previous.copyWith(comments: previousComments);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add comment. Please try again.')),
      );
    }
  }

  void _navigateToCreate() async {
    final group = Group(
      id: widget.groupId,
      name: widget.groupName,
      year: widget.groupYear,
    );
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.teacherEditGroupMessages,
      arguments: group,
    );
    if (result == true) {
      _loadMessages();
    }
  }

  void _navigateToEdit(GroupMessage message) async {
    final group = Group(
      id: widget.groupId,
      name: widget.groupName,
      year: widget.groupYear,
    );
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.teacherEditGroupMessages,
      arguments: {
        'group': group,
        'message': message,
      },
    );
    if (result == true) {
      _loadMessages();
    }
  }

  void _showMessageDetail(GroupMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Row(
          children: [
            Expanded(
              child: Text(
                message.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          (message.likedBy?.contains(_currentUserId ?? '') ?? false) ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Like ${message.likedBy?.length ?? 0}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Comments (${message.comments.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message Type and Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.messageType.isEmpty ? message.category : message.messageType,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(message.priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.priority,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getPriorityColor(message.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Audience
              if (message.audience.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visible To',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: message.audience
                          .map((audience) => Chip(
                                label: Text(audience),
                                labelStyle: GoogleFonts.poppins(fontSize: 11),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(message.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (message.expiryDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expires',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.expiryDate!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(GroupMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Comments (${message.comments.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    if (message.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Center(
                          child: Text(
                            'No comments yet',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      )
                    else
                      ...message.comments.map((comment) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                comment.studentName.isNotEmpty 
                                    ? comment.studentName[0].toUpperCase() 
                                    : '👤',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.studentName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDateWithTime(comment.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              if (_currentUserIsStudent)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentControllers[message.id] ??= TextEditingController(),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final input = (_commentControllers[message.id]?.text ?? '').trim();
                          if (input.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please write a comment first.')),
                            );
                            return;
                          }

                          if (!_currentUserIsStudent) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Only students can add comments.')),
                            );
                            return;
                          }

                          final userId = _currentUserId;
                          if (userId == null || userId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please log in to add a comment.')),
                            );
                            return;
                          }

                          try {
                            final comment = await _service.addComment(
                              groupId: widget.groupId,
                              messageId: message.id,
                              userId: userId,
                              userRole: _currentUserRole,
                              studentName: _currentUserName ?? 'Student',
                              comment: input,
                            );

                            if (!mounted) return;

                            final index = _messages.indexWhere((item) => item.id == message.id);
                            if (index != -1) {
                              setModalState(() {
                                _messages[index] = _messages[index].copyWith(
                                  comments: [..._messages[index].comments, comment],
                                );
                                _commentControllers[message.id]?.clear();
                              });
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Comment added successfully.')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Only students can comment on this message.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Group Messages', style: AppTextStyles.appTitle.copyWith(fontSize: 16)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Group Message Details',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.groupName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                ],
              ),
            ),
            Expanded(
              child: _content(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) => setState(() => _selectedBottomIndex = index),
      ),
    );
  }

  Widget _content() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No group messages available',
              style: GoogleFonts.poppins(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Message'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageCard(_messages[index]),
    );
  }

  Widget _buildMessageCard(GroupMessage message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.messageType.isEmpty ? message.category : message.messageType,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (message.priority != 'Normal')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(message.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message.priority,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getPriorityColor(message.priority),
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              message.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            // Message preview
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(message),
                  child: Row(
                    children: [
                      Icon(
                        (message.likedBy?.contains(_currentUserId ?? '') ?? false) ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: (message.likedBy?.contains(_currentUserId ?? '') ?? false) ? AppColors.primary : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${message.likedBy?.length ?? 0}',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(message.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.hintText,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showMessageDetail(message),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showCommentsModal(message),
              child: Text(
                '💬 Comments (${message.comments.length})',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(GroupMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Are you sure you want to delete "${message.title}"?'),
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

    try {
      await _service.deleteMessage(
        groupId: widget.groupId,
        messageId: message.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully.')),
      );
      _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete message: $e')),
      );
    }
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

  String _formatDateWithTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return _formatDate(date);
    }
  }
}
