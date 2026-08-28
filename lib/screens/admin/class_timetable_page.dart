import 'package:flutter/material.dart';
import '../../models/class_timetable.dart';
import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../services/class_timetable_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassTimetablePage extends StatefulWidget {
  const ClassTimetablePage({
    super.key,
    required this.group,
    this.isEdit = false,
  });
  final Group group;
  final bool isEdit;
  @override
  State<ClassTimetablePage> createState() => _ClassTimetablePageState();
}

class _ClassTimetablePageState extends State<ClassTimetablePage> {
  final _service = ClassTimetableService();
  List<ClassTimetableEntry> _entries = [];
  String? _error;
  bool _loading = true;
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String get _groupId => widget.group.id.trim().isNotEmpty
      ? widget.group.id.trim()
      : widget.group.name.trim();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _service.getForGroup(_groupId);
      if (mounted)
        setState(() {
          _entries = entries;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _open([ClassTimetableEntry? entry]) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.teacherClassTimetableAdd,
      arguments: entry == null
          ? widget.group
          : {'group': widget.group, 'entry': entry},
    );
    if (changed == true) _load();
  }

  Future<void> _delete(ClassTimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete timetable entry?'),
        content: Text(entry.subject),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(_groupId, entry.id);
      if (mounted) setState(() => _entries.remove(entry));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'Class Timetable',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.group.name} Class Timetable',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  if (widget.isEdit)
                    ElevatedButton.icon(
                      onPressed: () => _open(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueButton,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No Data available',
                        style: TextStyle(fontSize: 10),
                      ),
                    )
                  : ListView(
                      children: [for (final day in _days) ..._daySection(day)],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  List<Widget> _daySection(String day) {
    final entries = _entries.where((entry) => entry.day == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (entries.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 5),
        child: Text(
          day,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      ...entries.map(
        (entry) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          elevation: 0,
          color: const Color(0xfff4f5f8),
          child: ListTile(
            title: Text(
              '${entry.startTime} - ${entry.endTime}\n${entry.subject}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Teacher: ${entry.teacher}${entry.room.isEmpty ? '' : '\nRoom: ${entry.room}'}${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
            ),
            trailing: widget.isEdit
                ? PopupMenuButton<String>(
                    onSelected: (value) =>
                        value == 'edit' ? _open(entry) : _delete(entry),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                : null,
          ),
        ),
      ),
    ];
  }
}
