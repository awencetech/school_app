// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_message.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class StaffGroupMessagesPage extends StatefulWidget {
  const StaffGroupMessagesPage({super.key});

  @override
  State<StaffGroupMessagesPage> createState() => _StaffGroupMessagesPageState();
}

class _StaffGroupMessagesPageState extends State<StaffGroupMessagesPage> {
  String _selectedFilter = 'Clear Filters';

  static const _filters = [
    'Clear Filters',
    'School',
    'My Posts',
    'Student',
    'Class/Group',
    'Approved by me',
    'Msg for Management',
    'Msg from Parents',
    'Msg from Students',
    'Search String',
  ];

  static const _defaultMessages = <_StaffMessage>[];
  final _adminMessageService = AdminMessageService();
  late List<_StaffMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(_defaultMessages);
    _loadAdminMessages();
  }

  Future<void> _loadAdminMessages() async {
    try {
      final role = context.read<AppState>().currentUserRole?.toLowerCase();
      if (role != 'staff' && role != 'teacher') {
        return;
      }
      final messages = await _adminMessageService.getMessagesForRole('staff');
      if (!mounted) return;
      setState(() {
        _messages = messages.map(_toStaffMessage).toList();
      });
    } catch (_) {}
  }

  _StaffMessage _toStaffMessage(AdminMessage message) => _StaffMessage(
    '${message.messageType.toUpperCase()}  ${message.subject}',
    'From: ${message.senderName}\n${message.message}',
    message.groupName,
  );

  Future<void> _openFilter() async {
    var selected = _selectedFilter;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(12, 8, 5, 0),
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter Message',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by', style: TextStyle(fontSize: 10)),
                const SizedBox(height: 3),
                ..._filters.map(
                  (filter) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    title: Text(filter, style: const TextStyle(fontSize: 10)),
                    value: filter,
                    groupValue: selected,
                    onChanged: (value) => setDialogState(
                      () => selected = value ?? 'Clear Filters',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff087ff5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text('Filter', style: TextStyle(fontSize: 9)),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('Close', style: TextStyle(fontSize: 7)),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _selectedFilter = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
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
        actions: [
          IconButton(
            onPressed: _openFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, 7, 4, 4),
              child: Text(
                'Messages',
                style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _MessageCard(message: _messages[index]),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final _StaffMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xffeeeeee),
                child: Icon(
                  Icons.person_outline,
                  size: 25,
                  color: Color(0xffcccccc),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${message.title}\n${message.details}',
                  style: const TextStyle(
                    fontSize: 8,
                    height: 1.25,
                    color: Color(0xff123b65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.absentId,
            style: const TextStyle(fontSize: 10, color: Color(0xff123b65)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite, size: 10, color: Color(0xffaaaaaa)),
                Text(
                  ' Like',
                  style: TextStyle(fontSize: 8, color: Color(0xff888888)),
                ),
                SizedBox(width: 6),
                Icon(Icons.visibility, size: 10, color: Color(0xffaaaaaa)),
                Text(
                  ' Viewed',
                  style: TextStyle(fontSize: 8, color: Color(0xff888888)),
                ),
                SizedBox(width: 6),
                Icon(Icons.access_time, size: 10, color: Color(0xffaaaaaa)),
                Text(
                  ' Remind',
                  style: TextStyle(fontSize: 8, color: Color(0xff888888)),
                ),
                SizedBox(width: 6),
                Icon(Icons.forum, size: 10, color: Color(0xffaaaaaa)),
                Text(
                  ' Post Comment',
                  style: TextStyle(fontSize: 8, color: Color(0xff888888)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 21,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontSize: 8),
                    decoration: const InputDecoration(
                      hintText: 'Write Comment...',
                      hintStyle: TextStyle(fontSize: 8),
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 21),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('Post!', style: TextStyle(fontSize: 7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMessage {
  const _StaffMessage(this.title, this.details, this.absentId);

  final String title;
  final String details;
  final String absentId;
}
