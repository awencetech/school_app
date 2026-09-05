import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

// ============================================================================
// MOCK LESSON PLAN DATA
// ============================================================================
// This mock data is temporary and isolated for frontend development.
// Once the backend API is ready, replace this with API calls.
// See _initState() comment for INTEGRATION POINT.

class LessonPlan {
  final String id;
  final String subject;
  final String topic;
  final DateTime date;
  final String startTime; // "HH:mm" format
  final String endTime;   // "HH:mm" format
  final String teacher;
  final String room;
  final String status; // Planned, In Progress, Completed, Cancelled
  final List<String> learningObjectives;
  final String notes;

  LessonPlan({
    required this.id,
    required this.subject,
    required this.topic,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.room,
    required this.status,
    this.learningObjectives = const [],
    this.notes = '',
  });

  LessonPlan copyWith({
    String? id,
    String? subject,
    String? topic,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? teacher,
    String? room,
    String? status,
    List<String>? learningObjectives,
    String? notes,
  }) {
    return LessonPlan(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      status: status ?? this.status,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      notes: notes ?? this.notes,
    );
  }
}

// Mock data generator
List<LessonPlan> _generateMockLessonPlans() {
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

  return [
    LessonPlan(
      id: '1',
      subject: 'Mathematics',
      topic: 'Quadratic Equations',
      date: startOfWeek,
      startTime: '09:00',
      endTime: '09:45',
      teacher: 'Mr. Kumar',
      room: '204',
      status: 'Planned',
      learningObjectives: [
        'Understand quadratic formula',
        'Solve problems using factorization'
      ],
      notes: 'Bring graphing calculators',
    ),
    LessonPlan(
      id: '2',
      subject: 'English',
      topic: 'Shakespeare - Macbeth',
      date: startOfWeek,
      startTime: '10:00',
      endTime: '10:45',
      teacher: 'Ms. Smith',
      room: '301',
      status: 'In Progress',
      learningObjectives: [
        'Analyze character development',
        'Discuss themes of ambition'
      ],
    ),
    LessonPlan(
      id: '3',
      subject: 'Science',
      topic: 'Photosynthesis',
      date: startOfWeek,
      startTime: '11:00',
      endTime: '11:45',
      teacher: 'Dr. Patel',
      room: '105',
      status: 'Planned',
      learningObjectives: [
        'Understand light reactions',
        'Explain Calvin cycle'
      ],
    ),
    LessonPlan(
      id: '4',
      subject: 'History',
      topic: 'French Revolution',
      date: startOfWeek,
      startTime: '13:00',
      endTime: '13:45',
      teacher: 'Mr. Brown',
      room: '208',
      status: 'Completed',
      learningObjectives: [
        'Understand causes of revolution',
        'Analyze key events and figures'
      ],
    ),
    // Tuesday
    LessonPlan(
      id: '5',
      subject: 'Physics',
      topic: 'Motion and Forces',
      date: startOfWeek.add(const Duration(days: 1)),
      startTime: '09:00',
      endTime: '09:45',
      teacher: 'Dr. Johnson',
      room: '110',
      status: 'Planned',
      learningObjectives: [
        'Newton\'s Laws of Motion',
        'Force calculations'
      ],
    ),
    LessonPlan(
      id: '6',
      subject: 'Chemistry',
      topic: 'Organic Chemistry Basics',
      date: startOfWeek.add(const Duration(days: 1)),
      startTime: '10:00',
      endTime: '10:45',
      teacher: 'Dr. Lee',
      room: '115',
      status: 'Planned',
      learningObjectives: [
        'Introduction to carbon bonds',
        'Hydrocarbon classification'
      ],
    ),
    LessonPlan(
      id: '7',
      subject: 'Computer Science',
      topic: 'Data Structures',
      date: startOfWeek.add(const Duration(days: 1)),
      startTime: '11:00',
      endTime: '11:45',
      teacher: 'Mr. Singh',
      room: '301',
      status: 'In Progress',
      learningObjectives: [
        'Understand arrays and linked lists',
        'Implement stack operations'
      ],
    ),
    // Wednesday
    LessonPlan(
      id: '8',
      subject: 'Mathematics',
      topic: 'Trigonometry',
      date: startOfWeek.add(const Duration(days: 2)),
      startTime: '09:00',
      endTime: '09:45',
      teacher: 'Mr. Kumar',
      room: '204',
      status: 'Planned',
      learningObjectives: [
        'Sine, cosine, tangent ratios',
        'Solve trigonometric equations'
      ],
    ),
  ];
}

class ClassPlannerPage extends StatefulWidget {
  const ClassPlannerPage({super.key, required this.group, this.isViewOnly = false});

  final Group group;
  final bool isViewOnly;

  @override
  State<ClassPlannerPage> createState() => _ClassPlannerPageState();
}

class _ClassPlannerPageState extends State<ClassPlannerPage> {
  late List<LessonPlan> _allLessonPlans;
  late DateTime _weekStart;
  late String _selectedDay;
  String _filterStatus = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // INTEGRATION POINT: To connect real API:
    // Replace next line with: _allLessonPlans = await LessonPlanService().getForGroup(widget.group.id);
    _allLessonPlans = _generateMockLessonPlans();
    _initializeWeek();
  }

  void _initializeWeek() {
    final today = DateTime.now();
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _selectedDay = _getWeekdayName(today.weekday);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getWeekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  int _getWeekdayIndex(String name) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names.indexOf(name);
  }

  DateTime _getSelectedDate() {
    final index = _getWeekdayIndex(_selectedDay);
    return _weekStart.add(Duration(days: index));
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * offset));
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

  List<LessonPlan> _getFilteredPlans() {
    final selectedDate = _getSelectedDate();
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var filtered = _allLessonPlans.where((plan) {
      final planDate = DateTime(plan.date.year, plan.date.month, plan.date.day);
      if (planDate.isBefore(startOfDay) || planDate.isAfter(endOfDay.subtract(const Duration(seconds: 1)))) {
        return false;
      }
      if (_filterStatus != 'All' && plan.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final lower = _searchQuery.toLowerCase();
        if (!plan.subject.toLowerCase().contains(lower) &&
            !plan.topic.toLowerCase().contains(lower)) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
    return filtered;
  }

  List<LessonPlan> _getTodaySummaryPlans() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _allLessonPlans
        .where((plan) {
          final planDate = DateTime(plan.date.year, plan.date.month, plan.date.day);
          return planDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              planDate.isBefore(endOfDay);
        })
        .toList();
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _isCurrentLesson(LessonPlan plan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = DateTime(plan.date.year, plan.date.month, plan.date.day);

    if (!planDate.isAtSameMomentAs(today)) return false;

    final startMinutes = _timeToMinutes(plan.startTime);
    final endMinutes = _timeToMinutes(plan.endTime);
    final nowMinutes = now.hour * 60 + now.minute;

    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  void _openAddDialog() async {
    final result = await showDialog<LessonPlan>(
      context: context,
      builder: (context) => _AddLessonPlanDialog(initialDate: _getSelectedDate()),
    );
    if (result != null) {
      setState(() => _allLessonPlans.add(result));
    }
  }

  void _openEditDialog(LessonPlan plan) async {
    final result = await showDialog<LessonPlan>(
      context: context,
      builder: (context) => _EditLessonPlanDialog(plan: plan),
    );
    if (result != null) {
      setState(() {
        final index = _allLessonPlans.indexWhere((p) => p.id == plan.id);
        if (index >= 0) _allLessonPlans[index] = result;
      });
    }
  }

  void _deletePlan(LessonPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson Plan?'),
        content: const Text('Are you sure you want to delete this lesson plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) setState(() => _allLessonPlans.removeWhere((p) => p.id == plan.id));
  }

  void _showLessonDetails(LessonPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lesson Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Subject:', plan.subject),
              _DetailRow('Topic:', plan.topic),
              _DetailRow('Date:', DateFormat('MMM dd, yyyy').format(plan.date)),
              _DetailRow('Time:', '${plan.startTime} – ${plan.endTime}'),
              _DetailRow('Teacher:', plan.teacher),
              _DetailRow('Room:', plan.room),
              _DetailRow('Status:', plan.status),
              if (plan.learningObjectives.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Learning Objectives:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...plan.learningObjectives.map((obj) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text('• $obj', style: const TextStyle(fontSize: 13)),
                )),
              ],
              if (plan.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailRow('Notes:', plan.notes),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (!widget.isViewOnly) ...[
            TextButton(onPressed: () { Navigator.pop(context); _openEditDialog(plan); }, child: const Text('Edit')),
            TextButton(onPressed: () { Navigator.pop(context); _deletePlan(plan); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planned': return Colors.blue;
      case 'In Progress': return Colors.amber;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerSubtitle = [
      if (widget.group.type.isNotEmpty && widget.group.type != 'Other') widget.group.type,
      if (widget.group.code.isNotEmpty) widget.group.code,
      if (widget.group.year.isNotEmpty) widget.group.year,
    ].join(' • ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff363B60),
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Planner', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            if (headerSubtitle.isNotEmpty)
              Text(headerSubtitle, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeWeek(-1), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
                GestureDetector(
                  onTap: _goToToday,
                  child: Column(
                    children: [
                      Text('This Week', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryText)),
                      Text(DateFormat('MMM d – ').format(_weekStart) + DateFormat('MMM d').format(_weekStart.add(const Duration(days: 6))), style: GoogleFonts.poppins(fontSize: 10, color: AppColors.secondaryText)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeWeek(1), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Day Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(7, (index) {
                final date = _weekStart.add(Duration(days: index));
                final dayName = _getWeekdayName(date.weekday);
                final isSelected = dayName == _selectedDay;
                final isToday = DateTime.now().day == date.day && DateTime.now().month == date.month && DateTime.now().year == date.year;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => _selectDay(dayName),
                    child: Container(
                      width: 56,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.blueButton : (isToday ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected ? Border.all(color: AppColors.blueButton, width: 1.5) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dayName, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.primaryText)),
                          const SizedBox(height: 4),
                          Text(date.day.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.primaryText)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),

          // Today Summary Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTodaySummary(),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: '🔍 Search lessons...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xffE4E6EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Planned', 'In Progress', 'Completed', 'Cancelled'].map((status) {
                      final isSelected = _filterStatus == status;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _filterStatus = status),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.blueButton,
                          labelStyle: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : AppColors.secondaryText),
                          side: BorderSide(color: isSelected ? AppColors.blueButton : const Color(0xffE4E6EB)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lesson Plans List
          Expanded(child: _buildLessonsList()),
        ],
      ),
      floatingActionButton: widget.isViewOnly ? null : FloatingActionButton(backgroundColor: AppColors.blueButton, onPressed: _openAddDialog, child: const Icon(Icons.add, color: Colors.white)),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }

  Widget _buildTodaySummary() {
    final todayPlans = _getTodaySummaryPlans();
    final completed = todayPlans.where((p) => p.status == 'Completed').length;
    final inProgress = todayPlans.where((p) => p.status == 'In Progress').length;
    final upcoming = todayPlans.where((p) => p.status == 'Planned').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Plan", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(count: todayPlans.length, label: 'Lessons'),
              _SummaryItem(count: completed, label: 'Completed'),
              _SummaryItem(count: inProgress, label: 'In Progress'),
              _SummaryItem(count: upcoming, label: 'Upcoming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    final plans = _getFilteredPlans();

    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text('No Lesson Plans Yet', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
              const SizedBox(height: 8),
              Text('Create a lesson plan for this day\nto organize your classes.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondaryText)),
              const SizedBox(height: 24),
              if (!widget.isViewOnly) ElevatedButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add),
                label: Text('+ Add Lesson Plan', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueButton, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isCurrent = _isCurrentLesson(plan);
        final statusColor = _getStatusColor(plan.status);

        return GestureDetector(
          onTap: () => _showLessonDetails(plan),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffE4E6EB)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(plan.subject, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text('● NOW', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(plan.topic, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(plan.status, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.hintText),
                    const SizedBox(width: 6),
                    Text('${plan.startTime} – ${plan.endTime}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${plan.teacher} • ${plan.room}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.hintText)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;

  const _SummaryItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count.toString(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blueButton)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.secondaryText)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ADD LESSON PLAN DIALOG
// ============================================================================

class _AddLessonPlanDialog extends StatefulWidget {
  final DateTime initialDate;

  const _AddLessonPlanDialog({required this.initialDate});

  @override
  State<_AddLessonPlanDialog> createState() => _AddLessonPlanDialogState();
}

class _AddLessonPlanDialogState extends State<_AddLessonPlanDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'Planned';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 9, minute: 45);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    _objectivesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setState(() { isStart ? _startTime = picked : _endTime = picked; });
  }

  bool _validateForm() {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject')));
      return false;
    }
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter topic')));
      return false;
    }
    if (_teacherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter teacher name')));
      return false;
    }
    return true;
  }

  void _savePlan() {
    if (!_validateForm()) return;

    final objectives = _objectivesController.text.split('\n').map((obj) => obj.trim()).where((obj) => obj.isNotEmpty).toList();

    final newPlan = LessonPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _subjectController.text.trim(),
      topic: _topicController.text.trim(),
      date: _selectedDate,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      teacher: _teacherController.text.trim(),
      room: _roomController.text.trim(),
      status: _status,
      learningObjectives: objectives,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, newPlan);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Lesson Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: _selectDate, child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)))),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Topic *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Start Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(true), child: Text(_formatTime(_startTime))))),
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('End Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(false), child: Text(_formatTime(_endTime))))),
              ],
            ),
            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Teacher *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _objectivesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Learning Objectives (one per line)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Planned'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Planned', 'In Progress', 'Completed', 'Cancelled'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _savePlan, style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueButton), child: const Text('Save Plan')),
      ],
    );
  }
}

// ============================================================================
// EDIT LESSON PLAN DIALOG
// ============================================================================

class _EditLessonPlanDialog extends StatefulWidget {
  final LessonPlan plan;

  const _EditLessonPlanDialog({required this.plan});

  @override
  State<_EditLessonPlanDialog> createState() => _EditLessonPlanDialogState();
}

class _EditLessonPlanDialogState extends State<_EditLessonPlanDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _notesController = TextEditingController();
  late String _status;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.plan.date;
    _startTime = _parseTime(widget.plan.startTime);
    _endTime = _parseTime(widget.plan.endTime);
    _subjectController.text = widget.plan.subject;
    _topicController.text = widget.plan.topic;
    _teacherController.text = widget.plan.teacher;
    _roomController.text = widget.plan.room;
    _objectivesController.text = widget.plan.learningObjectives.join('\n');
    _notesController.text = widget.plan.notes;
    _status = widget.plan.status;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    _objectivesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setState(() { isStart ? _startTime = picked : _endTime = picked; });
  }

  bool _validateForm() {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject')));
      return false;
    }
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter topic')));
      return false;
    }
    if (_teacherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter teacher name')));
      return false;
    }
    return true;
  }

  void _savePlan() {
    if (!_validateForm()) return;

    final objectives = _objectivesController.text.split('\n').map((obj) => obj.trim()).where((obj) => obj.isNotEmpty).toList();

    final updatedPlan = widget.plan.copyWith(
      subject: _subjectController.text.trim(),
      topic: _topicController.text.trim(),
      date: _selectedDate,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      teacher: _teacherController.text.trim(),
      room: _roomController.text.trim(),
      status: _status,
      learningObjectives: objectives,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, updatedPlan);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Lesson Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: _selectDate, child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)))),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Topic *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Start Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(true), child: Text(_formatTime(_startTime))))),
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('End Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(false), child: Text(_formatTime(_endTime))))),
              ],
            ),
            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Teacher *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _roomController, decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _objectivesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Learning Objectives (one per line)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Planned'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Planned', 'In Progress', 'Completed', 'Cancelled'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _savePlan, style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueButton), child: const Text('Save Changes')),
      ],
    );
  }
}
