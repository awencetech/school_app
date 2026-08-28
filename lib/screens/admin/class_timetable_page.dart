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
                  : _buildWeeklyGrid(),
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

  Widget _buildWeeklyGrid() {
    final timeSlots =
        _entries
            .map((entry) => '${entry.startTime} - ${entry.endTime}')
            .toSet()
            .toList()
          ..sort();

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(112),
          border: TableBorder.all(color: const Color(0xffdddddd)),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xfffafafa)),
              children: [
                _gridHeader('Time', width: 86),
                for (final day in _days) _gridHeader(day),
              ],
            ),
            for (final slot in timeSlots)
              TableRow(
                children: [
                  _gridTime(slot),
                  for (final day in _days) _gridCell(day, slot),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _gridHeader(String text, {double width = 112}) {
    return SizedBox(
      width: width,
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _gridTime(String slot) {
    return SizedBox(
      width: 86,
      height: 58,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(slot, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _gridCell(String day, String slot) {
    final entries = _entries
        .where(
          (entry) =>
              entry.day == day &&
              '${entry.startTime} - ${entry.endTime}' == slot,
        )
        .toList();
    return SizedBox(
      height: 58,
      child: entries.isEmpty
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: entries
                  .map(
                    (entry) => Tooltip(
                      message: _entryTooltip(entry),
                      waitDuration: const Duration(milliseconds: 250),
                      preferBelow: false,
                      child: InkWell(
                        onTap: () => _showEntryDetails(entry),
                        child: SizedBox(
                          width: 112,
                          height: 58,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Text(
                                entry.subject,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Future<void> _showEntryDetails(ClassTimetableEntry entry) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.subject),
        content: Text(
          'Teacher: ${entry.teacher}\n'
          'Room: ${entry.room.isEmpty ? 'Not specified' : entry.room}\n'
          'Notes: ${entry.notes.isEmpty ? 'None' : entry.notes}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (widget.isEdit) ...[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'edit'),
              child: const Text('Edit'),
            ),
          ],
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _open(entry);
    } else if (action == 'delete') {
      await _delete(entry);
    }
  }

  String _entryTooltip(ClassTimetableEntry entry) {
    return 'Teacher: ${entry.teacher}\n'
        'Room: ${entry.room.isEmpty ? 'Not specified' : entry.room}\n'
        'Notes: ${entry.notes.isEmpty ? 'None' : entry.notes}';
  }
}
