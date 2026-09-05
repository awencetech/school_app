import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../models/group_event.dart';
import '../../routes/app_routes.dart';
import '../../services/group_event_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/slug_generator.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/dashboard_bottom_nav.dart';

enum _CalendarView { month, week, day }

class FutureEventCalendarPage extends StatefulWidget {
  const FutureEventCalendarPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isEdit = false,
    this.isStaffView = false,
  });

  final String groupId;
  final String groupName;
  final bool isEdit;
  final bool isStaffView;

  @override
  State<FutureEventCalendarPage> createState() =>
      _FutureEventCalendarPageState();
}

class _FutureEventCalendarPageState extends State<FutureEventCalendarPage> {
  final GroupEventService _eventService = GroupEventService();
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  List<GroupEvent> _events = [];
  _CalendarView _view = _CalendarView.month;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedBottomIndex = 2;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      widget.isStaffView
          ? AppRoutes.staffDashboard
          : AppRoutes.teacherGroupClasses,
      arguments: Group(id: widget.groupId, name: widget.groupName),
    );
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _displayedMonth = DateTime(today.year, today.month);
    _selectedDate = DateUtils.dateOnly(today);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final events = await _eventService.getEventsForGroup(widget.groupId);
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'Unable to load events.';
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
      _selectedDate = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(today.year, today.month);
      _selectedDate = DateUtils.dateOnly(today);
    });
  }

  List<GroupEvent> _eventsForDate(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return _events.where((event) {
      final start = DateUtils.dateOnly(event.startDate);
      final end = DateUtils.dateOnly(event.endDate ?? event.startDate);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  List<DateTime> _monthDates() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstCell = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(
      42,
      (index) => DateUtils.dateOnly(firstCell.add(Duration(days: index))),
    );
  }

  List<DateTime> _weekDates() {
    final first = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    return List.generate(
      7,
      (index) => DateUtils.dateOnly(first.add(Duration(days: index))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Future Events', style: AppTextStyles.appTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isEdit) ...[
              Text(
                '${widget.groupName} Upcoming Events!',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 5),
              _buildCalendarToolbar(),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (widget.isEdit)
              _buildEditContent()
            else if (_view == _CalendarView.day)
              _buildDayView()
            else ...[
              _buildCalendarGrid(
                dates: _view == _CalendarView.month
                    ? _monthDates()
                    : _weekDates(),
              ),
              if (_events.isEmpty) _buildMessage('No upcoming events'),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.isStaffView
          ? ReusableBottomNavigationBar(
              currentIndex: _selectedBottomIndex,
              onItemSelected: (index) {
                if (index == 4) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.main,
                    (route) => false,
                  );
                  return;
                }
                setState(() => _selectedBottomIndex = index);
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
                BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
                BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
              ],
            )
          : AdminBottomNavigationBar(
              currentIndex: _selectedBottomIndex,
              onItemSelected: (index) => setState(() => _selectedBottomIndex = index),
            ),
    );
  }

  Widget _buildCalendarToolbar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CompactToolbarButton(
          label: 'month',
          selected: _view == _CalendarView.month,
          onTap: () => setState(() => _view = _CalendarView.month),
        ),
        _CompactToolbarButton(
          label: 'week',
          selected: _view == _CalendarView.week,
          onTap: () => setState(() => _view = _CalendarView.week),
        ),
        _CompactToolbarButton(
          label: 'day',
          selected: _view == _CalendarView.day,
          onTap: () => setState(() => _view = _CalendarView.day),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            _monthTitle(_displayedMonth),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const Spacer(),
        _CompactToolbarButton(label: 'today', onTap: _goToToday),
        _CompactToolbarButton(
          label: '<',
          onTap: () => _changeMonth(-1),
          width: 25,
        ),
        _CompactToolbarButton(
          label: '>',
          onTap: () => _changeMonth(1),
          width: 25,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid({required List<DateTime> dates}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        children: [
          Row(
            children: _weekdayNames
                .map(
                  (name) => Expanded(child: Center(child: _weekdayLabel(name))),
                )
                .toList(),
          ),
          const Divider(height: 1, color: Color(0xFFD9D9D9)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 70,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              return _buildDateCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final events = _eventsForDate(date);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isOutsideMonth = date.month != _displayedMonth.month;
    final visibleEvents = events.take(2).toList();

    return InkWell(
      onTap: () => setState(() => _selectedDate = date),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blueButton.withValues(alpha: 0.12)
              : AppColors.white,
          border: Border.all(
            color: isToday ? AppColors.orangeButton : AppColors.border,
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                '${date.day}',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isOutsideMonth
                      ? AppColors.hintText
                      : AppColors.primaryText,
                ),
              ),
            ),
            ...visibleEvents.map(_eventChip),
            if (events.length > visibleEvents.length)
              Text(
                '+${events.length - visibleEvents.length} more',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventChip(GroupEvent event) {
    return InkWell(
      onTap: () => _showEventDetails(event),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: _eventColor(event).withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 7,
            fontWeight: FontWeight.w600,
            color: _eventTextColor(event),
            backgroundColor: _eventColor(event),
          ),
        ),
      ),
    );
  }

  Future<void> _showEventDetails(GroupEvent event) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        title: Row(
          children: [
            const Expanded(child: Text('Calendar Event Detail')),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _eventTextColor(event),
                  backgroundColor: _eventColor(event),
                ),
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Description:'),
                const SizedBox(height: 3),
                Text(event.description),
              ],
              const SizedBox(height: 12),
              _detailRow('Start Date', _formatEventDate(event.startDate)),
              _detailRow(
                'End Date',
                _formatEventDate(event.endDate ?? event.startDate),
              ),
              if (event.startTime != null)
                _detailRow('Start Time', event.startTime!),
              if (event.endTime != null)
                _detailRow('End Time', event.endTime!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }

  String _formatEventDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildDayView() {
    final events = _eventsForDate(_selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _dateTitle(_selectedDate),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          _buildMessage('No events scheduled for this day.')
        else
          ...events.map(
            (event) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.event, color: AppColors.orangeButton),
                title: Text(event.title),
                subtitle: Text(_eventDetails(event)),
              ),
            ),
          ),
      ],
    );
  }

  Color _eventColor(GroupEvent event) {
    final value = event.color.replaceFirst('#', '');
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.yellowButton : Color(0xFF000000 | parsed);
  }

  Color _eventTextColor(GroupEvent event) {
    final color = _eventColor(event);
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  Widget _buildEditContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openEventForm(),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Add event'),
          ),
        ),
        const SizedBox(height: 10),
        if (_events.isEmpty) _buildMessage('No upcoming events'),
        ..._events.map(
          (event) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: Border(left: BorderSide(color: _eventColor(event), width: 4)),
            child: ListTile(
              title: Text(
                event.title,
                style: TextStyle(
                  color: _eventTextColor(event),
                  backgroundColor: _eventColor(event),
                ),
              ),
              subtitle: Text(
                '${_dateTitle(event.startDate)}\n${_eventDetails(event)}',
              ),
              isThreeLine: true,
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Edit event',
                    onPressed: () => _openEventForm(event),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete event',
                    onPressed: () => _deleteEvent(event),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEventForm([GroupEvent? event]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _GroupEventForm(
          service: _eventService,
          groupId: widget.groupId,
          groupName: widget.groupName,
          event: event,
        ),
      ),
    );
    if (saved == true && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.teacherFutureEventCalendar,
        arguments: Group(id: widget.groupId, name: widget.groupName),
      );
    }
  }

  Future<void> _deleteEvent(GroupEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Delete "${event.title}"?'),
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
      await _eventService.deleteEvent(event);
      if (mounted) _loadEvents();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete event: $error')),
        );
      }
    }
  }

  Widget _buildMessage(String message, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isError ? Colors.red : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          _buildMessage(_errorMessage!, isError: true),
          TextButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _eventDetails(GroupEvent event) {
    final time = [
      event.startTime,
      event.endTime,
    ].whereType<String>().join(' - ');
    if (time.isNotEmpty && event.description.isNotEmpty) {
      return '$time\n${event.description}';
    }
    if (time.isNotEmpty) {
      return time;
    }
    return event.description.isNotEmpty ? event.description : 'All day';
  }

  String _monthTitle(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  String _dateTitle(DateTime date) =>
      '${_weekdayNames[date.weekday % 7]}, ${_monthTitle(date)} ${date.day}';

  Widget _weekdayLabel(String name) {
    return Text(
      name,
      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600),
    );
  }

  static const _weekdayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}

class _GroupEventForm extends StatefulWidget {
  const _GroupEventForm({
    required this.service,
    required this.groupId,
    required this.groupName,
    this.event,
  });

  final GroupEventService service;
  final String groupId;
  final String groupName;
  final GroupEvent? event;

  @override
  State<_GroupEventForm> createState() => _GroupEventFormState();
}

class _GroupEventFormState extends State<_GroupEventForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late DateTime _date;
  late String _color;
  String? _selectedGroupId;
  List<Group> _groups = [];
  bool _groupsLoading = true;
  bool _saving = false;
  String? _error;

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(
        AppRoutes.teacherFutureEventCalendar,
        arguments: Group(id: widget.groupId, name: widget.groupName),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _startTimeController = TextEditingController(text: event?.startTime ?? '');
    _endTimeController = TextEditingController(text: event?.endTime ?? '');
    _date = event?.startDate ?? DateUtils.dateOnly(DateTime.now());
    _color = event?.color ?? '#FF9800';
    _selectedGroupId = widget.groupId;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await GroupService().getGroups();
      if (!mounted) return;
      Group? matchingGroup;
      for (final group in groups) {
        final groupEventId = group.id.toUpperCase().startsWith('SAMUNI-2022-')
            ? group.id
            : generateGroupDatabaseId(group.name);
        if (groupEventId == widget.groupId ||
          group.id == widget.groupId ||
            group.name.trim() == widget.groupName.trim()) {
          matchingGroup = group;
          break;
        }
      }
      setState(() {
        _groups = groups;
        _selectedGroupId = matchingGroup == null
            ? _selectedGroupId
            : _eventGroupId(matchingGroup);
        _groupsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _groupsLoading = false);
    }
  }

  String _eventGroupId(Group group) {
    final id = group.id.trim();
    if (id.toUpperCase().startsWith('SAMUNI-2022-')) return id;
    return generateGroupDatabaseId(group.name.isEmpty ? id : group.name);
  }

  String? _dropdownGroupId() {
    for (final group in _groups) {
      if (_eventGroupId(group) == _selectedGroupId) return _selectedGroupId;
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = DateUtils.dateOnly(selected));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final groupId = _selectedGroupId;
    if (groupId == null || groupId.isEmpty || groupId == 'SAMUNI-2022-Unknown') {
      setState(() => _error = 'Select a group before saving the event.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final event = GroupEvent(
      id: widget.event?.id ?? '',
      groupId: groupId,
      title: title,
      startDate: _date,
      endDate: _date,
      startTime: _emptyToNull(_startTimeController.text),
      endTime: _emptyToNull(_endTimeController.text),
      description: _descriptionController.text.trim(),
      createdBy: widget.event?.createdBy ?? '',
      color: _color,
    );
    try {
      if (widget.event == null) {
        await widget.service.createEvent(event);
      } else {
        await widget.service.updateEvent(event);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save event: $error';
        });
      }
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(isEditing ? 'Edit Event' : 'Add Event', style: AppTextStyles.appTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _dropdownGroupId(),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select group'),
              items: _groups
                  .map(
                    (group) => DropdownMenuItem<String>(
                      value: _eventGroupId(group),
                      child: Text(group.name),
                    ),
                  )
                  .toList(),
              onChanged: _groupsLoading
                  ? null
                  : (value) => setState(() => _selectedGroupId = value),
            ),
            const SizedBox(height: 12),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _formatDate(_date)),
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_month)),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _startTimeController, decoration: const InputDecoration(labelText: 'Start time'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _endTimeController, decoration: const InputDecoration(labelText: 'End time'))),
              ],
            ),
            const SizedBox(height: 16),
            Text('Event Color', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((color) {
                final selected = _color == color;
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.primaryText : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
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

  Color _parseColor(String value) {
    final parsed = int.tryParse(value.replaceFirst('#', ''), radix: 16);
    return parsed == null ? AppColors.yellowButton : Color(0xFF000000 | parsed);
  }

  static const _colorOptions = [
    '#FF9800',
    '#2196F3',
    '#4CAF50',
    '#E91E63',
    '#9C27B0',
    '#607D8B',
  ];
}

class _CompactToolbarButton extends StatelessWidget {
  const _CompactToolbarButton({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 19,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? const Color(0xFFD6D6D6)
              : const Color(0xFFEFEFEF),
          foregroundColor: AppColors.primaryText,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFFBDBDBD)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
