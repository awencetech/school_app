import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group_event.dart';
import '../../services/group_event_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';

enum _CalendarView { month, week, day }

class FutureEventCalendarPage extends StatefulWidget {
  const FutureEventCalendarPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
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
      bottomNavigationBar: AdminBottomNavigationBar(
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
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.yellowButton.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        event.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

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
