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
import 'group_messages_edit_page.dart';

class GroupMessagesPage extends StatefulWidget {
  const GroupMessagesPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
    this.isViewOnly = false,
  });

  final String groupId;
  final String groupName;
  final String groupYear;
  final bool isViewOnly;

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

  bool get _canCommentOnMessage {
    final userId = _currentUserId;
    return _currentUserIsStudent && userId != null && userId.trim().isNotEmpty;
  }

  String? get _currentUserId => context.read<AppState>().currentUserId;

  String get _currentUserRole => context.read<AppState>().currentUserRole?.trim() ?? '';

  String get _currentUserName => context.read<AppState>().currentUserEmail ?? 'Student';
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
    final likedBy = Set<String>.from(previous.likedBy);
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
      final serverLikedBy = (result['likedBy'] is List)
          ? List<String>.from((result['likedBy'] as List).map((item) => item.toString()))
          : likedBy.toList();
      if (!mounted) return;
      setState(() {
        _messages[index] = previous.copyWith(likedBy: serverLikedBy);
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
    if (!_canCommentOnMessage) {
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
      studentName: _currentUserName,
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
        studentName: _currentUserName,
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

  String _teacherDisplayName(GroupMessage message) {
    final senderName = message.senderName.trim();
    if (senderName.isNotEmpty && senderName.toLowerCase() != 'user') {
      return senderName;
    }
    final authorRole = message.authorRole.trim();
    if (authorRole.isNotEmpty && authorRole.toLowerCase() != 'unknown') {
      return authorRole[0].toUpperCase() + authorRole.substring(1);
    }
    return 'Student';
  }

  String _commentDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Student';
    return trimmed;
  }

  String _commentInitials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'S';
    final parts = trimmed.split(RegExp(r'\s+')).where((segment) => segment.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Widget _buildCommentAvatar({required String? imageUrl, required String name}) {
    final safeImage = imageUrl ?? '';
    if (safeImage.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(safeImage),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Text(
        _commentInitials(name),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showCommentsModal(GroupMessage message) {
    final controller = _commentControllers[message.id] ??= TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        GroupMessage currentMessage = _messages.firstWhere(
          (item) => item.id == message.id,
          orElse: () => message,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            currentMessage = _messages.firstWhere(
              (item) => item.id == message.id,
              orElse: () => currentMessage,
            );

            final comments = currentMessage.comments;
            final inputText = controller.text.trim();

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Comments (${comments.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: comments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '💬 No comments yet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Be the first to comment.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCommentAvatar(
                                      imageUrl: comment.studentProfileImage,
                                      name: comment.studentName,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _commentDisplayName(comment.studentName),
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
                                );
                              },
                            ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1),
                        ),
                        color: Colors.white,
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: _canCommentOnMessage && !widget.isViewOnly
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: inputText.isEmpty
                                              ? null
                                              : (_) async {
                                                  final liveMessage = _messages.firstWhere(
                                                    (item) => item.id == message.id,
                                                    orElse: () => currentMessage,
                                                  );
                                                  await _addComment(liveMessage);
                                                  if (!mounted) return;
                                                  setModalState(() {
                                                    currentMessage = _messages.firstWhere(
                                                      (item) => item.id == message.id,
                                                      orElse: () => liveMessage,
                                                    );
                                                  });
                                                },
                                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryText),
                                          decoration: InputDecoration(
                                            hintText: 'Write a comment...',
                                            hintStyle: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.secondaryText,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                          ),
                                          minLines: 1,
                                          maxLines: 1,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: inputText.isEmpty
                                            ? null
                                            : () async {
                                                final liveMessage = _messages.firstWhere(
                                                  (item) => item.id == message.id,
                                                  orElse: () => currentMessage,
                                                );
                                                await _addComment(liveMessage);
                                                if (!mounted) return;
                                                setModalState(() {
                                                  currentMessage = _messages.firstWhere(
                                                    (item) => item.id == message.id,
                                                    orElse: () => liveMessage,
                                                  );
                                                });
                                              },
                                        icon: const Icon(Icons.send_rounded),
                                        color: inputText.isEmpty ? AppColors.secondaryText : AppColors.primary,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 18,
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Comments are available to view. Only students can comment.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          onPressed: () {
            // Use maybePop() to safely navigate back
            // If no previous route exists, this will keep the current page visible
            // instead of showing a blank screen
            navigateBack(context);
          },
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
            if (!widget.isViewOnly) ElevatedButton.icon(
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
            if (!widget.isViewOnly) ElevatedButton.icon(
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
            TeacherNameBadge(teacherName: _teacherDisplayName(message)),
            if (message.senderEmail.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${message.senderName} / ${message.senderEmail}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
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
                  onTap: widget.isViewOnly ? null : () => _toggleLike(message),
                  child: Row(
                    children: [
                      Icon(
                        message.likedBy.contains(_currentUserId ?? '') ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: message.likedBy.contains(_currentUserId ?? '') ? AppColors.primary : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Like',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondaryText),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${message.likedBy.length}',
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
