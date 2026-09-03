import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

// ============================================================================
// DATA MODEL
// ============================================================================

class OnlineMeeting {
  final String id;
  final String title;
  final String subject;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String teacher;
  final String meetingLink;
  final String description;
  final String status; // Upcoming, Live Now, Completed, Cancelled

  OnlineMeeting({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.meetingLink,
    required this.description,
    required this.status,
  });

  OnlineMeeting copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? teacher,
    String? meetingLink,
    String? description,
    String? status,
  }) {
    return OnlineMeeting(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      teacher: teacher ?? this.teacher,
      meetingLink: meetingLink ?? this.meetingLink,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}

// ============================================================================
// VIDEO CONFERENCE PAGE
// ============================================================================

class OnlineClassMeetingPage extends StatefulWidget {
  final Group group;
  final bool isViewOnly;

  const OnlineClassMeetingPage({super.key, required this.group, this.isViewOnly = false});

  @override
  State<OnlineClassMeetingPage> createState() => _OnlineClassMeetingPageState();
}

class _OnlineClassMeetingPageState extends State<OnlineClassMeetingPage> {
  late List<OnlineMeeting> _allMeetings;
  String _selectedDateFilter = 'All'; // Today, Tomorrow, This Week, All
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allMeetings = _generateMockMeetings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================================
  // MOCK DATA
  // ============================================================================

  List<OnlineMeeting> _generateMockMeetings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    return [
      OnlineMeeting(
        id: '1',
        title: 'Mathematics Class',
        subject: 'Quadratic Equations',
        date: tomorrow,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 45),
        teacher: 'Mr. Kumar',
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        description: 'Solving quadratic equations using factorization and formula method.',
        status: 'Upcoming',
      ),
      OnlineMeeting(
        id: '2',
        title: 'Science Discussion',
        subject: 'Physics – Motion',
        date: tomorrow,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 45),
        teacher: 'Ms. Sharma',
        meetingLink: 'https://meet.google.com/xyz-uvwx-yz',
        description: 'Laws of motion, velocity, acceleration, and practical examples.',
        status: 'Upcoming',
      ),
      OnlineMeeting(
        id: '3',
        title: 'English Class',
        subject: 'Grammar & Writing',
        date: today,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 45),
        teacher: 'Mr. Patel',
        meetingLink: 'https://meet.google.com/pqr-stuv-wx',
        description: 'Focus on tenses, sentence structure, and creative writing techniques.',
        status: 'Completed',
      ),
      OnlineMeeting(
        id: '4',
        title: 'History Session',
        subject: 'Ancient Civilizations',
        date: dayAfter,
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 45),
        teacher: 'Dr. Singh',
        meetingLink: 'https://meet.google.com/mno-pqrs-tuv',
        description: 'Exploration of ancient Egyptian, Greek, and Roman civilizations.',
        status: 'Upcoming',
      ),
      OnlineMeeting(
        id: '5',
        title: 'Computer Science Lab',
        subject: 'Python Programming',
        date: dayAfter,
        startTime: const TimeOfDay(hour: 13, minute: 30),
        endTime: const TimeOfDay(hour: 14, minute: 30),
        teacher: 'Ms. Verma',
        meetingLink: 'https://meet.google.com/abc-xyzk-lmn',
        description: 'Hands-on coding session on Python fundamentals and data structures.',
        status: 'Upcoming',
      ),
    ];
  }

  // ============================================================================
  // FILTERS AND SEARCH
  // ============================================================================

  List<OnlineMeeting> _getFilteredMeetings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    List<OnlineMeeting> filtered = _allMeetings;

    // Apply date filter
    if (_selectedDateFilter == 'Today') {
      filtered = filtered.where((m) => _isSameDay(m.date, today)).toList();
    } else if (_selectedDateFilter == 'Tomorrow') {
      filtered = filtered.where((m) => _isSameDay(m.date, tomorrow)).toList();
    } else if (_selectedDateFilter == 'This Week') {
      filtered = filtered.where((m) => m.date.isAfter(today) && m.date.isBefore(weekEnd.add(const Duration(days: 1)))).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((m) => m.title.toLowerCase().contains(query) || m.subject.toLowerCase().contains(query) || m.teacher.toLowerCase().contains(query)).toList();
    }

    // Sort by date and time
    filtered.sort((a, b) {
      if (a.date != b.date) return a.date.compareTo(b.date);
      return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
    });

    return filtered;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  int _getUpcomingCount() => _allMeetings.where((m) => m.status == 'Upcoming').length;

  int _getLiveNowCount() => _allMeetings.where((m) => m.status == 'Live Now').length;

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _openAddDialog() async {
    final result = await showDialog<OnlineMeeting>(
      context: context,
      builder: (context) => _AddMeetingDialog(initialDate: DateTime.now()),
    );
    if (result != null) {
      setState(() => _allMeetings.add(result));
    }
  }

  void _openEditDialog(OnlineMeeting meeting) async {
    final result = await showDialog<OnlineMeeting>(
      context: context,
      builder: (context) => _EditMeetingDialog(meeting: meeting),
    );
    if (result != null) {
      setState(() {
        final index = _allMeetings.indexWhere((m) => m.id == meeting.id);
        if (index >= 0) _allMeetings[index] = result;
      });
    }
  }

  void _deleteMeeting(OnlineMeeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting?'),
        content: const Text('Are you sure you want to delete this meeting?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _allMeetings.removeWhere((m) => m.id == meeting.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyMeetingLink(String link) {
    // In a real app, use: await Clipboard.setData(ClipboardData(text: link));
    // For now, just show feedback
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link copied to clipboard'), duration: Duration(seconds: 2)));
  }

  void _joinMeeting(String? link) {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link is not available.')));
      return;
    }
    // In a real app, use: await launchUrl(Uri.parse(link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening meeting: $link')));
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final filteredMeetings = _getFilteredMeetings();
    final upcomingCount = _getUpcomingCount();
    final liveNowCount = _getLiveNowCount();

    return Scaffold(
      backgroundColor: const Color(0xfff4f5f8),
      appBar: AppBar(
        backgroundColor: const Color(0xff363b60),
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video Conference', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(widget.group.name, style: const TextStyle(color: Color(0xffb8bcc8), fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 22, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Class Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Online Class & Meeting', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('Class: ${widget.group.name}', style: const TextStyle(fontSize: 12, color: Color(0xff4a4a4a)))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text('Teacher: Current Teacher', style: const TextStyle(fontSize: 12, color: Color(0xff4a4a4a)))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(color: const Color(0xfff4f5f8), borderRadius: BorderRadius.circular(4)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Upcoming Meetings', style: TextStyle(fontSize: 10, color: Color(0xff7a7a7a), fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('$upcomingCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xff363b60))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(color: const Color(0xfff4f5f8), borderRadius: BorderRadius.circular(4)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Live Now', style: TextStyle(fontSize: 10, color: Color(0xff7a7a7a), fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('$liveNowCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xffef4444))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: '🔍 Search meetings...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xff7a7a7a)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Date Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Today', 'Tomorrow', 'This Week', 'All'].map((filter) {
                      final isSelected = _selectedDateFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) => setState(() => _selectedDateFilter = filter),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xff2baac8),
                          labelStyle: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xff363b60), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                          side: BorderSide(color: isSelected ? const Color(0xff2baac8) : const Color(0xffe4e6eb)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Meetings List
                filteredMeetings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.video_call_outlined, size: 48, color: const Color(0xffc5cad1)),
                              const SizedBox(height: 12),
                              const Text('No Online Classes Yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xff363b60))),
                              const SizedBox(height: 6),
                              const Text('Schedule an online class or meeting for this group.', style: TextStyle(fontSize: 12, color: Color(0xff7a7a7a))),
                              const SizedBox(height: 16),
                              if (!widget.isViewOnly) ElevatedButton.icon(
                                onPressed: _openAddDialog,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Schedule Meeting'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: filteredMeetings.map((meeting) => _buildMeetingCard(meeting)).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: widget.isViewOnly ? null : FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: const Color(0xff2baac8),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Schedule Meeting'),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }

  Widget _buildMeetingCard(OnlineMeeting meeting) {
    final statusColor = meeting.status == 'Upcoming'
        ? const Color(0xff3b82f6)
        : meeting.status == 'Live Now'
            ? const Color(0xffef4444)
            : meeting.status == 'Completed'
                ? const Color(0xff10b981)
                : const Color(0xff6b7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meeting.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff222222))),
                          const SizedBox(height: 2),
                          Text(meeting.subject, style: const TextStyle(fontSize: 12, color: Color(0xff7a7a7a))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(meeting.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xff7a7a7a)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(DateFormat('MMM d, yyyy').format(meeting.date), style: const TextStyle(fontSize: 11, color: Color(0xff4a4a4a)))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 14, color: Color(0xff7a7a7a)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${meeting.startTime.format(context)} – ${meeting.endTime.format(context)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xff4a4a4a)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xff7a7a7a)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(meeting.teacher, style: const TextStyle(fontSize: 11, color: Color(0xff4a4a4a)))),
                  ],
                ),
                if (meeting.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(meeting.description, style: const TextStyle(fontSize: 11, color: Color(0xff7a7a7a)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffe4e6eb)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!widget.isViewOnly) Expanded(
                  child: TextButton.icon(
                    onPressed: () => _joinMeeting(meeting.meetingLink),
                    icon: const Icon(Icons.video_call, size: 14),
                    label: const Text('Join', style: TextStyle(fontSize: 11)),
                  ),
                ),
                if (!widget.isViewOnly) Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openEditDialog(meeting),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _copyMeetingLink(meeting.meetingLink),
                    icon: const Icon(Icons.link, size: 14),
                    label: const Text('Copy', style: TextStyle(fontSize: 11)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteMeeting(meeting),
                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ADD MEETING DIALOG
// ============================================================================

class _AddMeetingDialog extends StatefulWidget {
  final DateTime initialDate;

  const _AddMeetingDialog({required this.initialDate});

  @override
  State<_AddMeetingDialog> createState() => _AddMeetingDialogState();
}

class _AddMeetingDialogState extends State<_AddMeetingDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _linkController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'Upcoming';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = const TimeOfDay(hour: 10, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 45);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _teacherController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) {
      setState(() {
      isStart ? _startTime = picked : _endTime = picked;
    });
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter meeting title')));
      return false;
    }
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject')));
      return false;
    }
    if (_teacherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter teacher name')));
      return false;
    }
    return true;
  }

  void _saveMeeting() {
    if (!_validateForm()) return;

    final newMeeting = OnlineMeeting(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      teacher: _teacherController.text.trim(),
      meetingLink: _linkController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
    );

    Navigator.pop(context, newMeeting);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Meeting'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Meeting Title *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: _selectDate, child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Start Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(true), child: Text(_startTime.format(context))))),
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('End Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(false), child: Text(_endTime.format(context))))),
              ],
            ),
            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Teacher *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _linkController, decoration: const InputDecoration(labelText: 'Meeting Link', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Upcoming'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Upcoming', 'Live Now', 'Completed', 'Cancelled'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveMeeting, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), child: const Text('Schedule Meeting')),
      ],
    );
  }
}

// ============================================================================
// EDIT MEETING DIALOG
// ============================================================================

class _EditMeetingDialog extends StatefulWidget {
  final OnlineMeeting meeting;

  const _EditMeetingDialog({required this.meeting});

  @override
  State<_EditMeetingDialog> createState() => _EditMeetingDialogState();
}

class _EditMeetingDialogState extends State<_EditMeetingDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _linkController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _status;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.meeting.date;
    _startTime = widget.meeting.startTime;
    _endTime = widget.meeting.endTime;
    _titleController.text = widget.meeting.title;
    _subjectController.text = widget.meeting.subject;
    _teacherController.text = widget.meeting.teacher;
    _linkController.text = widget.meeting.meetingLink;
    _descriptionController.text = widget.meeting.description;
    _status = widget.meeting.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _teacherController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) {
      setState(() {
      isStart ? _startTime = picked : _endTime = picked;
    });
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter meeting title')));
      return false;
    }
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject')));
      return false;
    }
    if (_teacherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter teacher name')));
      return false;
    }
    return true;
  }

  void _saveMeeting() {
    if (!_validateForm()) return;

    final updatedMeeting = widget.meeting.copyWith(
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      date: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      teacher: _teacherController.text.trim(),
      meetingLink: _linkController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
    );

    Navigator.pop(context, updatedMeeting);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Meeting'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Meeting Title *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: _selectDate, child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('Start Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(true), child: Text(_startTime.format(context))))),
                Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('End Time', style: TextStyle(fontSize: 12)), trailing: TextButton(onPressed: () => _selectTime(false), child: Text(_endTime.format(context))))),
              ],
            ),
            TextField(controller: _teacherController, decoration: const InputDecoration(labelText: 'Teacher *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _linkController, decoration: const InputDecoration(labelText: 'Meeting Link', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              onChanged: (value) => setState(() => _status = value ?? 'Upcoming'),
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Upcoming', 'Live Now', 'Completed', 'Cancelled'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveMeeting, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2baac8)), child: const Text('Save Changes')),
      ],
    );
  }
}
