// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_message.dart';
import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../services/class_service.dart';
import '../../services/group_service.dart';
import '../../services/staff_access_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import 'staff_write_message_page.dart';

class StaffGroupMessagesPage extends StatefulWidget {
  const StaffGroupMessagesPage({super.key, this.headerTitle = 'SAMUNI'});

  final String headerTitle;

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
  final _staffAccessService = StaffAccessService();
  late List<_StaffMessage> _messages;
  List<Group> _groups = const [];
  List<Group> _classes = const [];
  bool _targetsLoading = true;
  String? _targetsError;

  @override
  void initState() {
    super.initState();
    _messages = List.from(_defaultMessages);
    _loadAdminMessages();
    _loadAssignedTargets();
  }

  Future<void> _loadAssignedTargets() async {
    try {
      final access = await _staffAccessService.getMine();
      final allowedGroups = access.groupIds.toSet();
      final allowedClasses = access.classTeacherIds.toSet();
      final groups = await GroupService().getGroups(refresh: true);
      final classes = await ClassService().getClasses(refresh: true);
      if (!mounted) return;
      setState(() {
        _groups = groups
            .where((group) => allowedGroups.contains(_targetKey(group)))
            .toList();
        _classes = classes
            .where((group) => allowedClasses.contains(_targetKey(group)))
            .toList();
        _targetsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _targetsLoading = false;
        _targetsError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _targetKey(Group target) =>
      target.id.trim().isNotEmpty ? target.id.trim() : target.databaseId.trim();

  void _selectTarget(Group target) {
    final targetName = target.name.isEmpty ? target.id : target.name;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffMessageComposePage(
          group: StaffMessageGroup(
            targetName,
            targetName,
            'Message for $targetName',
          ),
        ),
      ),
    );
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
        title: Text(
          widget.headerTitle,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            onPressed: _openFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 12),
        children: [
          _TargetDropdownCard(
            title: 'Groups',
            subtitle: 'Send message to a group',
            icon: Icons.groups_outlined,
            targets: _groups,
            loading: _targetsLoading,
            error: _targetsError,
            emptyLabel: 'No groups available',
            onTargetSelected: _selectTarget,
          ),
          const SizedBox(height: 10),
          _TargetDropdownCard(
            title: 'Classes',
            subtitle: 'Send message to a class',
            icon: Icons.school_outlined,
            targets: _classes,
            loading: _targetsLoading,
            error: _targetsError,
            emptyLabel: 'No classes available',
            onTargetSelected: _selectTarget,
          ),
          const SizedBox(height: 14),
          const Text(
            'Messages',
            style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          ..._messages.map((message) => _MessageCard(message: message)),
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

class _TargetDropdownCard extends StatelessWidget {
  const _TargetDropdownCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.targets,
    required this.loading,
    required this.error,
    required this.emptyLabel,
    required this.onTargetSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Group> targets;
  final bool loading;
  final String? error;
  final String emptyLabel;
  final ValueChanged<Group> onTargetSelected;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: ExpansionTile(
      leading: Icon(icon, size: 25, color: const Color(0xff34395f)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (error != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              error!,
              style: const TextStyle(fontSize: 10, color: Colors.red),
            ),
          )
        else if (targets.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(emptyLabel, style: const TextStyle(fontSize: 10)),
          )
        else
          ...targets.map(
            (target) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked, size: 16),
              title: Text(
                target.name.isEmpty ? target.id : target.name,
                style: const TextStyle(fontSize: 11),
              ),
              onTap: () => onTargetSelected(target),
            ),
          ),
      ],
    ),
  );
}

enum StaffMessageTargetType { groups, classes }

class StaffMessageTargetsPage extends StatefulWidget {
  const StaffMessageTargetsPage({super.key, required this.targetType});

  final StaffMessageTargetType targetType;

  @override
  State<StaffMessageTargetsPage> createState() =>
      _StaffMessageTargetsPageState();
}

class _StaffMessageTargetsPageState extends State<StaffMessageTargetsPage> {
  final _staffAccessService = StaffAccessService();
  List<Group> _targets = const [];
  bool _loading = true;
  String? _error;

  bool get _isGroups => widget.targetType == StaffMessageTargetType.groups;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    try {
      final access = await _staffAccessService.getMine();
      final allowed = (_isGroups ? access.groupIds : access.classTeacherIds)
          .toSet();
      final dynamic result = _isGroups
          ? await GroupService().getGroups(refresh: true)
          : await ClassService().getClasses(refresh: true);
      final records = result is List
          ? result.whereType<Group>().toList()
          : const <Group>[];
      if (!mounted) return;
      setState(() {
        _targets = records
            .where((target) => allowed.contains(_targetKey(target)))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _targetKey(Group target) =>
      target.id.trim().isNotEmpty ? target.id.trim() : target.databaseId.trim();

  void _selectTarget(Group target) {
    final targetName = target.name.isEmpty ? target.id : target.name;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffMessageComposePage(
          group: StaffMessageGroup(
            targetName,
            targetName,
            'Message for $targetName',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: const Color(0xff34395f),
      elevation: 0,
      toolbarHeight: 44,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
      centerTitle: true,
      title: Text(
        _isGroups ? 'Groups' : 'Classes',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : _error != null
        ? Center(child: Text(_error!, style: const TextStyle(fontSize: 11)))
        : _targets.isEmpty
        ? Center(
            child: Text(
              _isGroups ? 'No groups available' : 'No classes available',
              style: const TextStyle(fontSize: 11),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: _targets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final target = _targets[index];
              return Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.radio_button_unchecked, size: 18),
                  title: Text(
                    target.name.isEmpty ? target.id : target.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => _selectTarget(target),
                ),
              );
            },
          ),
    bottomNavigationBar: _staffBottomNavigationBar(context),
  );

  Widget _staffBottomNavigationBar(BuildContext context) =>
      ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
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
      );
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
