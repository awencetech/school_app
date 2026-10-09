import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/admin_message.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';
import '../../widgets/staff_footer.dart';

class MessageModel {
  MessageModel({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.createdDate,
    required this.createdTime,
    required this.message,
    required this.profileImage,
    required this.isViewed,
    required this.category,
    this.groupName = 'All Groups',
    this.recipientLabel = '',
  });

  final String id;
  final String title;
  final String teacherName;
  final String createdDate;
  final String createdTime;
  final String message;
  final String? profileImage;
  final bool isViewed;
  final String category;
  final String groupName;
  final String recipientLabel;
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, this.quickAccessTitle});

  final String? quickAccessTitle;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<MessageModel> _allMessages = [];
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _loadError;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final Map<String, TextEditingController> _commentControllers = {};
  final _adminMessageService = AdminMessageService();

  @override
  void initState() {
    super.initState();
    _allMessages = const [];
    _loadAdminMessages();
  }

  Future<void> _loadAdminMessages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final role =
          context.read<AppState>().currentUserRole?.trim().toLowerCase() ?? '';
      if (role != 'student' &&
          role != 'staff' &&
          role != 'teacher' &&
          role != 'admin' &&
          role != 'administrator') {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final isStudentQuickAccess = widget.quickAccessTitle == 'Messages';
      final adminMessages = isStudentQuickAccess
          ? await _adminMessageService.getStudentMessages()
          : await _adminMessageService.getMessagesForRole(role);
      if (!mounted) return;
      final liveMessages = adminMessages
          .map(isStudentQuickAccess ? _toStudentMessageModel : _toMessageModel)
          .toList();
      setState(() {
        _allMessages = liveMessages;
        _messages = List.from(liveMessages);
        _isLoading = false;
        for (final message in liveMessages) {
          _commentControllers[message.id] = TextEditingController();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Unable to load messages. Please try again.';
          _allMessages = [];
          _messages = [];
        });
      }
    }
  }

  MessageModel _toMessageModel(AdminMessage message) {
    final date = message.createdAt;
    return MessageModel(
      id: 'admin-${message.id}',
      title: message.subject,
      teacherName:
          'From: ${message.senderName}${message.senderRole.isEmpty ? '' : ' (${_displayRole(message.senderRole)})'}',
      createdDate: date == null
          ? ''
          : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}',
      createdTime: '',
      message: message.message,
      profileImage: null,
      isViewed: message.read,
      category: message.messageType,
      groupName: message.groupName,
      recipientLabel: message.recipientTypes
          .map((type) => type == 'students' ? 'Students' : 'Staff / Teachers')
          .join(', '),
    );
  }

  MessageModel _toStudentMessageModel(AdminMessage message) {
    final date = message.createdAt;
    return MessageModel(
      id: 'student-${message.id}',
      title: message.subject,
      teacherName:
          'From: ${message.senderName}${message.senderRole.isEmpty ? '' : ' (${_displayRole(message.senderRole)})'}',
      createdDate: date == null
          ? ''
          : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}',
      createdTime: date == null
          ? ''
          : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      message: message.message,
      profileImage: null,
      isViewed: message.read,
      category: message.messageType,
      groupName: message.groupName,
      recipientLabel: message.groupName,
    );
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  String _displayRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'student' || normalized == 'students') return 'Student';
    if (normalized == 'staff' || normalized == 'teacher') return 'Staff';
    if (normalized == 'admin' || normalized == 'administrator') return 'Admin';
    return role;
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      _messages = _allMessages.where((message) {
        final matchesFilter =
            _selectedFilter == 'All' ||
            message.category.toLowerCase() == _selectedFilter.toLowerCase();
        final matchesSearch =
            query.isEmpty ||
            message.title.toLowerCase().contains(query) ||
            message.teacherName.toLowerCase().contains(query) ||
            message.message.toLowerCase().contains(query) ||
            message.category.toLowerCase().contains(query) ||
            message.recipientLabel.toLowerCase().contains(query) ||
            message.groupName.toLowerCase().contains(query);
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  Future<void> _refreshMessages() async {
    await _loadAdminMessages();
  }

  Widget _statusList(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(child: child),
      ),
    ],
  );

  Future<void> _openSearch() async {
    final result = await showSearch<String>(
      context: context,
      delegate: _MessagesSearchDelegate(_allMessages),
    );
    if (!mounted || result == null || result.isEmpty) return;
    setState(() {
      _searchQuery = result;
      _applyFilters();
    });
  }

  void _postComment(String id) {
    final controller = _commentControllers[id];
    final comment = (controller?.text ?? '').trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment first')),
      );
      return;
    }
    controller?.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment Posted')));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.topBar;
    final bgColor = const Color(0xFFF7F8FC);
    final greyText = const Color(0xFF757575);
    final routeName = ModalRoute.of(context)?.settings.name;
    final isStudentMessages = routeName == AppRoutes.studentDashboardMessages;
    final isStaffMessages = routeName == AppRoutes.staffDashboardMessages;
    final isAdminMessages = routeName == AppRoutes.adminQuickMessages;

    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: widget.quickAccessTitle != null
            ? QuickAccessAppBar(
                title: widget.quickAccessTitle!,
                actions: [
                  IconButton(
                    onPressed: _openSearch,
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onSelected: (value) {
                      setState(() {
                        _selectedFilter = value;
                        _applyFilters();
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'All', child: Text('All')),
                      PopupMenuItem(value: 'Homework', child: Text('Homework')),
                      PopupMenuItem(value: 'General', child: Text('General')),
                    ],
                  ),
                ],
              )
            : AppBar(
                backgroundColor: primaryColor,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => navigateBack(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _openSearch,
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onSelected: (value) {
                      setState(() {
                        _selectedFilter = value;
                        _applyFilters();
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'All', child: Text('All')),
                      PopupMenuItem(value: 'Homework', child: Text('Homework')),
                      PopupMenuItem(value: 'Circular', child: Text('Circular')),
                      PopupMenuItem(value: 'Events', child: Text('Events')),
                      PopupMenuItem(
                        value: 'Attendance',
                        child: Text('Attendance'),
                      ),
                      PopupMenuItem(value: 'Fees', child: Text('Fees')),
                      PopupMenuItem(value: 'Exam', child: Text('Exam')),
                      PopupMenuItem(
                        value: 'Announcements',
                        child: Text('Announcements'),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
        body: RefreshIndicator(
          onRefresh: _refreshMessages,
          color: primaryColor,
          child: _isLoading
              ? _statusList(const CircularProgressIndicator())
              : _loadError != null
              ? _statusList(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loadError!, style: TextStyle(color: greyText)),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _loadAdminMessages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _messages.isEmpty
              ? _statusList(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 56, color: greyText),
                      const SizedBox(height: 12),
                      Text(
                        'No messages available',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final controller = _commentControllers[message.id]!;
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 250 + (index * 80)),
                      opacity: 1,
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFEDEFF6),
                                    child:
                                        message.profileImage == null ||
                                            message.profileImage!.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFF2F3352),
                                          )
                                        : ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: message.profileImage!,
                                              fit: BoxFit.cover,
                                              width: 48,
                                              height: 48,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: const Color(
                                                      0xFFEDEFF6,
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.person,
                                                        color: Color(
                                                          0xFF2F3352,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.category,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          message.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Created on: ${message.createdDate}\n${message.createdTime}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: greyText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Message From\n${message.teacherName}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          message.message,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF444444),
                                          ),
                                        ),
                                        if (message
                                            .recipientLabel
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sent to: ${message.recipientLabel}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: greyText,
                                            ),
                                          ),
                                          Text(
                                            'Class: ${message.groupName}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: greyText,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  _StatusIcon(
                                    label: 'Like',
                                    icon: Icons.thumb_up_alt_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusIcon(
                                    label: message.isViewed ? 'Viewed' : 'New',
                                    icon: Icons.visibility_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusIcon(
                                    label: 'Remind',
                                    icon: Icons.alarm_add_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusIcon(
                                    label: 'Comment',
                                    icon: Icons.comment_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: 'Write Comment...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: greyText,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E5E5),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E5E5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () => _postComment(message.id),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Post',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: isStudentMessages
            ? ReusableBottomNavigationBar(
                currentIndex: 0,
                onItemSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.studentDashboard,
                      (route) => false,
                    );
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'User',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info),
                    label: 'Help',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.help),
                    label: 'Support',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.logout),
                    label: 'Logout',
                  ),
                ],
              )
            : isStaffMessages
            ? StaffFooter(
                currentIndex: 0,
                onItemSelected: (index) async {
                  if (index == 0) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.staffDashboard,
                      (route) => false,
                    );
                  } else if (index == 4) {
                    await context.read<AppState>().logout();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                  }
                },
              )
            : isAdminMessages
            ? AdminBottomNavigationBar(
                currentIndex: 0,
                onItemSelected: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.adminDashboard,
                      (route) => false,
                    );
                  }
                },
              )
            : null,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF757575)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MessagesSearchDelegate extends SearchDelegate<String> {
  _MessagesSearchDelegate(this.messages);

  final List<MessageModel> messages;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildMatches();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildMatches();
  }

  Widget _buildMatches() {
    final matches = messages.where((message) {
      final q = query.toLowerCase();
      return q.isEmpty ||
          message.title.toLowerCase().contains(q) ||
          message.teacherName.toLowerCase().contains(q) ||
          message.message.toLowerCase().contains(q);
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No results',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF757575),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final message = matches[index];
        return ListTile(
          title: Text(
            message.title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            message.teacherName,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          onTap: () => close(context, message.title),
        );
      },
    );
  }
}
