import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/admin_message.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_bottom_nav.dart';
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
  const MessagesPage({super.key});

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
    _allMessages = _buildDemoMessages();
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
      final role = context.read<AppState>().currentUserRole?.trim().toLowerCase() ?? '';
      if (role != 'student' && role != 'staff' && role != 'teacher' && role != 'admin' && role != 'administrator') {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final adminMessages = await _adminMessageService.getMessagesForRole(role);
      if (!mounted) return;
      final liveMessages = adminMessages.map(_toMessageModel).toList();
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
      teacherName: 'From: ${message.senderName}',
      createdDate: date == null
          ? ''
          : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}',
      createdTime: '',
      message: message.message,
      profileImage: null,
      isViewed: false,
      category: message.messageType,
      groupName: message.groupName,
      recipientLabel: message.recipientTypes
          .map((type) => type == 'students' ? 'Students' : 'Staff / Teachers')
          .join(', '),
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

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<MessageModel> _buildDemoMessages() {
    return [];
    /* return [
      MessageModel(
        id: '1',
        title: 'Homework - Mathematics',
        teacherName: 'Mr. Arun Kumar',
        createdDate: 'Aug 07, 2026',
        createdTime: '12:41 PM',
        message:
            'Complete Exercise 5 from Mathematics textbook and submit it tomorrow.',
        profileImage: null,
        isViewed: true,
        category: 'Homework',
      ),
      MessageModel(
        id: '2',
        title: 'Science Homework',
        teacherName: 'Mrs. Priya',
        createdDate: 'Aug 07, 2026',
        createdTime: '11:20 AM',
        message:
            'Submit the science project before Monday and bring the materials.',
        profileImage: null,
        isViewed: false,
        category: 'Homework',
      ),
      MessageModel(
        id: '3',
        title: 'English Assignment',
        teacherName: 'Ms. Saira',
        createdDate: 'Aug 06, 2026',
        createdTime: '04:05 PM',
        message:
            'Write a short essay on your favorite place and bring it to class.',
        profileImage: null,
        isViewed: true,
        category: 'Homework',
      ),
      MessageModel(
        id: '4',
        title: 'PTM Announcement',
        teacherName: 'Principal',
        createdDate: 'Aug 06, 2026',
        createdTime: '03:15 PM',
        message: 'Parent Teacher Meeting is scheduled on Friday at 10:00 AM.',
        profileImage: null,
        isViewed: true,
        category: 'Announcements',
      ),
      MessageModel(
        id: '5',
        title: 'Holiday Notice',
        teacherName: 'System',
        createdDate: 'Aug 05, 2026',
        createdTime: '09:30 AM',
        message:
            'The school will remain closed on Monday due to the public holiday.',
        profileImage: null,
        isViewed: false,
        category: 'Events',
      ),
      MessageModel(
        id: '6',
        title: 'Sports Day Circular',
        teacherName: 'Class Teacher',
        createdDate: 'Aug 05, 2026',
        createdTime: '08:15 AM',
        message:
            'Sports Day practice starts from August 15 and all students must attend.',
        profileImage: null,
        isViewed: false,
        category: 'Circular',
      ),
      MessageModel(
        id: '7',
        title: 'Attendance Alert',
        teacherName: 'Mr. Rahul',
        createdDate: 'Aug 04, 2026',
        createdTime: '01:40 PM',
        message:
            'Please ensure you attend the morning assembly and maintain attendance.',
        profileImage: null,
        isViewed: true,
        category: 'Attendance',
      ),
      MessageModel(
        id: '8',
        title: 'Fee Reminder',
        teacherName: 'Accounts',
        createdDate: 'Aug 04, 2026',
        createdTime: '10:10 AM',
        message:
            'School fee payment is due this week and late charges may apply.',
        profileImage: null,
        isViewed: false,
        category: 'Fees',
      ),
      MessageModel(
        id: '9',
        title: 'Exam Timetable',
        teacherName: 'Exam Cell',
        createdDate: 'Aug 03, 2026',
        createdTime: '05:20 PM',
        message:
            'The annual exam timetable has been updated and shared with all classes.',
        profileImage: null,
        isViewed: true,
        category: 'Exam',
      ),
      MessageModel(
        id: '10',
        title: 'Project Submission',
        teacherName: 'Ms. Rani',
        createdDate: 'Aug 03, 2026',
        createdTime: '03:50 PM',
        message:
            'Please upload your project submission before Wednesday evening.',
        profileImage: null,
        isViewed: false,
        category: 'Homework',
      ),
      MessageModel(
        id: '11',
        title: 'Independence Day Rehearsal',
        teacherName: 'Music Teacher',
        createdDate: 'Aug 02, 2026',
        createdTime: '02:25 PM',
        message:
            'The rehearsal for Independence Day will be held tomorrow morning.',
        profileImage: null,
        isViewed: true,
        category: 'Events',
      ),
      MessageModel(
        id: '12',
        title: 'Hindi Homework',
        teacherName: 'Mr. Verma',
        createdDate: 'Aug 02, 2026',
        createdTime: '11:55 AM',
        message: 'Read Chapter 4 and complete the notes for tomorrow’s class.',
        profileImage: null,
        isViewed: false,
        category: 'Homework',
      ),
      MessageModel(
        id: '13',
        title: 'Library Reminder',
        teacherName: 'Librarian',
        createdDate: 'Aug 01, 2026',
        createdTime: '04:10 PM',
        message: 'Please return the borrowed books before the end of the week.',
        profileImage: null,
        isViewed: true,
        category: 'Announcements',
      ),
      MessageModel(
        id: '14',
        title: 'Transport Update',
        teacherName: 'Transport Office',
        createdDate: 'Jul 31, 2026',
        createdTime: '09:00 AM',
        message: 'The bus timing has been revised for the next two days.',
        profileImage: null,
        isViewed: false,
        category: 'Circular',
      ),
      MessageModel(
        id: '15',
        title: 'Lab Practical Notice',
        teacherName: 'Science Dept',
        createdDate: 'Jul 30, 2026',
        createdTime: '12:35 PM',
        message:
            'Bring your lab record book for the practical session on Friday.',
        profileImage: null,
        isViewed: true,
        category: 'Announcements',
      ),
    ]; */
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
    final isStaffMessages =
        ModalRoute.of(context)?.settings.name ==
        AppRoutes.staffDashboardMessages;

    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => navigateBack(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                PopupMenuItem(value: 'Attendance', child: Text('Attendance')),
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
              icon: const Icon(Icons.notifications_none, color: Colors.white),
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
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                  const SizedBox(width: 12),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          'Created on: ${message.createdDate}\n${message.createdTime}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: greyText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Message From\n${message.teacherName}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          message.message,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF444444),
                                          ),
                                        ),
                                        if (message.recipientLabel.isNotEmpty) ...[
                                          const SizedBox(height: 6),
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _StatusIcon(
                                    label: 'Like',
                                    icon: Icons.thumb_up_alt_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusIcon(
                                    label: message.isViewed ? 'Viewed' : 'New',
                                    icon: Icons.visibility_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusIcon(
                                    label: 'Remind',
                                    icon: Icons.alarm_add_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                  _StatusIcon(
                                    label: 'Comment',
                                    icon: Icons.comment_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
                                              vertical: 12,
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
                                        vertical: 12,
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
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.main,
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
