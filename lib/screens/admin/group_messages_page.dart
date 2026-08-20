// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/group_message.dart';
import '../../services/app_state.dart';
import '../../services/group_message_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';

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
  List<GroupMessage> _allMessages = [];
  List<GroupMessage> _visibleMessages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Clear Filters';
  String _searchText = '';
  int _selectedBottomIndex = 2;

  static const _filters = [
    'Clear Filters',
    'School',
    'My Posts',
    'Student',
    'Class/Group',
    'Approved by me',
    'Msg for Management',
    'Msg from Parents',
    'Msg for Students',
    'Search String',
  ];

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
        _allMessages = messages;
        _isLoading = false;
      });
      _applyFilter();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load messages.';
      });
    }
  }

  void _applyFilter() {
    final currentUserId = context.read<AppState>().currentUserId ?? '';
    final query = _searchText.trim().toLowerCase();
    final filtered = _allMessages.where((message) {
      final role = message.authorRole.toLowerCase();
      final category = message.category.toLowerCase();
      final target = message.target.toLowerCase();
      switch (_selectedFilter) {
        case 'School':
          return category.contains('school');
        case 'My Posts':
          return message.authorId == currentUserId;
        case 'Student':
          return role.contains('student') || category.contains('student');
        case 'Class/Group':
          return message.groupId == widget.groupId || category.contains('class') || category.contains('group');
        case 'Approved by me':
          return message.approved && message.approvedById == currentUserId;
        case 'Msg for Management':
          return target.contains('management') || category.contains('management');
        case 'Msg from Parents':
          return role.contains('parent') || category.contains('parent');
        case 'Msg for Students':
          return target.contains('student') || category.contains('student');
        case 'Search String':
          return query.isEmpty || _searchableText(message).contains(query);
        default:
          return true;
      }
    }).toList();
    if (mounted) setState(() => _visibleMessages = filtered);
  }

  String _searchableText(GroupMessage message) => [
        message.title,
        message.content,
        message.authorId,
        message.authorRole,
        message.category,
        message.target,
      ].join(' ').toLowerCase();

  Future<void> _openFilter() async {
    var selected = _selectedFilter;
    var search = _searchText;
    final searchController = TextEditingController(text: search);
    final result = await showDialog<_MessageFilterResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            title: Row(children: [
              Expanded(child: Text('Filter Message', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600))),
              IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
            ]),
            content: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Filter by', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ..._filters.map((filter) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(filter, style: GoogleFonts.poppins(fontSize: 12)),
                      value: filter,
                      groupValue: selected,
                      onChanged: (value) => setDialogState(() => selected = value ?? 'Clear Filters'),
                    )),
                if (selected == 'Search String') ...[
                  const SizedBox(height: 4),
                  TextField(
                    autofocus: true,
                    controller: searchController,
                    onChanged: (value) => search = value,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Search messages...'),
                  ),
                ],
              ]),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(_MessageFilterResult(selected, search)),
                  child: const Text('Filter'),
                ),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
    if (!mounted || result == null) return;
    setState(() {
      _selectedFilter = result.filter;
      _searchText = result.filter == 'Clear Filters' ? '' : result.search;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Messages', style: AppTextStyles.appTitle.copyWith(fontSize: 16)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter messages',
            onPressed: _openFilter,
            icon: const Icon(Icons.filter_list, color: AppColors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${widget.groupName} - ${widget.groupYear}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Divider(height: 1),
            ]),
          ),
          Expanded(child: _content()),
        ]),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) => setState(() => _selectedBottomIndex = index),
      ),
    );
  }

  Widget _content() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)),
        TextButton.icon(onPressed: _loadMessages, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
    }
    if (_visibleMessages.isEmpty) return Center(child: Text('No Data available', style: GoogleFonts.poppins(color: AppColors.secondaryText)));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
      itemCount: _visibleMessages.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) => _messageTile(_visibleMessages[index]),
    );
  }

  Widget _messageTile(GroupMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(message.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.secondaryText)),
        const SizedBox(height: 5),
        Text('${message.authorId}  |  ${_formatDate(message.createdAt)}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.hintText)),
      ]),
    );
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _MessageFilterResult {
  const _MessageFilterResult(this.filter, this.search);
  final String filter;
  final String search;
}
