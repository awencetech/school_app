import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late DateTime _weekStart;
  String _selectedDay = '';

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _dayShorts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _groupId => widget.group.id.trim().isNotEmpty
      ? widget.group.id.trim()
      : widget.group.name.trim();

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _load();
  }

  void _initializeWeek() {
    final today = DateTime.now();
    final weekdayIndex = today.weekday - 1;
    _weekStart = today.subtract(Duration(days: weekdayIndex));
    _selectedDay = _days[weekdayIndex];
  }

  Future<void> _load() async {
    try {
      final entries = await _service.getForGroup(_groupId);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
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
        title: const Text('Delete Class?'),
        content: const Text('Are you sure you want to remove this timetable entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(_groupId, entry.id);
      if (mounted) {
        setState(() => _entries.remove(entry));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));
      _selectedDay = _days[0];
    });
  }

  void _goToToday() {
    setState(() {
      _initializeWeek();
    });
  }

  void _selectDay(String day) {
    setState(() {
      _selectedDay = day;
    });
  }

  List<ClassTimetableEntry> _getEntriesForDay(String day) {
    return _entries
        .where((entry) => entry.day == day)
        .toList()
      ..sort((a, b) => _compareTime(a.startTime, b.startTime));
  }

  int _compareTime(String time1, String time2) {
    final t1 = _timeToMinutes(time1);
    final t2 = _timeToMinutes(time2);
    return t1.compareTo(t2);
  }

  int _timeToMinutes(String time) {
    final parts = time.replaceAll(RegExp(r'[APM]'), '').trim().split(':');
    var hours = int.tryParse(parts[0]) ?? 0;
    final mins = int.tryParse(parts[1]) ?? 0;
    final isPm = time.toUpperCase().contains('PM');
    if (isPm && hours != 12) hours += 12;
    if (!isPm && hours == 12) hours = 0;
    return hours * 60 + mins;
  }

  bool _isCurrentClass(ClassTimetableEntry entry) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _timeToMinutes(entry.startTime);
    final endMinutes = _timeToMinutes(entry.endTime);
    final todayDay = _days[now.weekday - 1];
    return entry.day == todayDay && nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  bool _isBreak(ClassTimetableEntry entry) {
    final subject = entry.subject.toLowerCase();
    return subject.contains('break') || 
           subject.contains('lunch') || 
           subject.contains('assembly') ||
           subject.contains('recess');
  }

  Color _getSubjectColor(String subject) {
    final hash = subject.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];
    return colors[hash.abs() % colors.length];
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('maths')) return Icons.calculate;
    if (s.contains('english') || s.contains('language')) return Icons.language;
    if (s.contains('science') || s.contains('physics') || s.contains('chemistry')) return Icons.science;
    if (s.contains('history') || s.contains('social')) return Icons.history;
    if (s.contains('computer') || s.contains('it')) return Icons.computer;
    if (s.contains('sport') || s.contains('pe') || s.contains('physical')) return Icons.sports_soccer;
    if (s.contains('art') || s.contains('drawing')) return Icons.palette;
    if (s.contains('music')) return Icons.music_note;
    if (s.contains('break') || s.contains('lunch') || s.contains('recess')) return Icons.lunch_dining;
    return Icons.book;
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
          onPressed: () => navigateBack(context),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : Column(
                children: [
                  // Class Name Header
                  Container(
                    color: AppColors.topBar.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Weekly Class Timetable',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.hintText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Week Navigation
                  _buildWeekNavigation(),

                  // Day Tabs
                  _buildDayTabs(),

                  // Main Content
                  Expanded(
                    child: _entries.isEmpty
                        ? _buildEmptyState()
                        : _buildDayContent(),
                  ),
                ],
              ),
      ),
      floatingActionButton: widget.isEdit
          ? FloatingActionButton(
              onPressed: () => _open(),
              backgroundColor: AppColors.blueButton,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _loading = true;
              });
              _load();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final startDate = _weekStart;
    final endDate = _weekStart.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');
    final weekRange = '${formatter.format(startDate)} – ${formatter.format(endDate)}, ${endDate.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeWeek(-1),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Center(
              child: Text(
                weekRange,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeWeek(1),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final dayShort = _dayShorts[index];
          final isSelected = _selectedDay == day;
          final date = _weekStart.add(Duration(days: index));
          final dateStr = date.day.toString();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _selectDay(day),
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blueButton : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? null : Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayShort,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.hintText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Classes Today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no timetable entries scheduled for this day.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.hintText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent() {
    final entriesForDay = _getEntriesForDay(_selectedDay);

    if (entriesForDay.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate daily summary
    final classEntries = entriesForDay.where((e) => !_isBreak(e)).toList();
    final firstTime = classEntries.isNotEmpty ? classEntries.first.startTime : '';
    final lastTime = classEntries.isNotEmpty ? classEntries.last.endTime : '';
    final classCount = classEntries.length;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Daily Summary
          if (classEntries.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blueButton.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.blueButton),
                  const SizedBox(width: 8),
                  Text(
                    '$classCount Class${classCount != 1 ? 'es' : ''} • $firstTime – $lastTime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),

          // Today Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 16),
              label: const Text('Today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueButton,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ),

          // Timetable Entries
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: entriesForDay.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entriesForDay[index];
              final isNow = _isCurrentClass(entry);
              final isBreak = _isBreak(entry);

              if (isBreak) {
                return _buildBreakCard(entry);
              }

              return _buildClassCard(entry, isNow);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassTimetableEntry entry, bool isNow) {
    final color = _getSubjectColor(entry.subject);
    final icon = _getSubjectIcon(entry.subject);

    return GestureDetector(
      onTap: () => _showEntryDetails(entry),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: color, width: 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isNow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.red.withValues(alpha: 0.3))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radio_button_checked, size: 12, color: Colors.red),
                    const SizedBox(width: 6),
                    const Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.subject,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.startTime} – ${entry.endTime}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.hintText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: AppColors.hintText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.teacher,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.room.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, size: 14, color: AppColors.hintText),
                            const SizedBox(width: 4),
                            Text(
                              entry.room,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.notes,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakCard(ClassTimetableEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lunch_dining, size: 16, color: AppColors.hintText),
                const SizedBox(width: 8),
                Text(
                  entry.subject.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hintText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.lunch_dining, size: 16, color: AppColors.hintText),
              ],
            ),
            Container(
              height: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.only(top: 8),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.startTime} – ${entry.endTime}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.hintText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryDetails(ClassTimetableEntry entry) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final color = _getSubjectColor(entry.subject);
        final icon = _getSubjectIcon(entry.subject);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entry.subject),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Time', '${entry.startTime} – ${entry.endTime}'),
                const SizedBox(height: 12),
                _detailRow('Teacher', entry.teacher),
                if (entry.room.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailRow('Room', entry.room),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailRow('Notes', entry.notes, maxLines: 3),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (widget.isEdit) ...[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'delete'),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, 'edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueButton,
                ),
                child: const Text('Edit', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _open(entry);
    } else if (action == 'delete') {
      await _delete(entry);
    }
  }

  Widget _detailRow(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.hintText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryText,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
