import 'package:flutter/material.dart';

import '../../models/one_on_one_meeting.dart';
import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/one_on_one_meeting_service.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class OneOnOneStaffMeetingsPage extends StatefulWidget {
  const OneOnOneStaffMeetingsPage({super.key});

  @override
  State<OneOnOneStaffMeetingsPage> createState() =>
      _OneOnOneStaffMeetingsPageState();
}

class _OneOnOneStaffMeetingsPageState extends State<OneOnOneStaffMeetingsPage> {
  final _staffService = StaffService();
  final _meetingService = OneOnOneMeetingService();
  List<StaffInfo> _staff = const [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final staff = await _staffService.getStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
        _page = 0;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _setup(StaffInfo staff, [OneOnOneMeeting? meeting]) async {
    final saved = await showDialog<OneOnOneMeeting>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetupMeetingDialog(staff: staff, meeting: meeting),
    );
    if (saved == null) return;
    try {
      await _meetingService.save(saved);
      if (mounted) {
        _message(
          meeting == null
              ? 'Meeting added successfully.'
              : 'Meeting updated successfully.',
        );
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _history(StaffInfo staff) async {
    await showDialog<void>(
      context: context,
      builder: (_) => MeetingHistoryDialog(
        staff: staff,
        service: _meetingService,
        onEdit: _setup,
      ),
    );
  }

  void _message(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final start = _page * _pageSize;
    final visible = _staff.skip(start).take(_pageSize).toList();
    final pageCount = (_staff.length / _pageSize).ceil();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('One on One Meetings'),
        actions: [
          IconButton(
            onPressed: _loadStaff,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 700 ? 16.0 : 32.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
                children: [
                  const Text(
                    'Staff List and Meetings',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    _StateMessage(message: _error!, action: _loadStaff)
                  else if (_staff.isEmpty)
                    const _StateMessage(message: 'No staff members found.')
                  else
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _StaffTableHeader(
                            actionWidth: constraints.maxWidth < 500 ? 145 : 210,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          ...visible.map(
                            (staff) => _StaffRow(
                              actionWidth: constraints.maxWidth < 500
                                  ? 145
                                  : 210,
                              staff: staff,
                              onSet: () => _setup(staff),
                              onView: () => _history(staff),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loading && _error == null && _staff.isNotEmpty)
                    _Pagination(
                      page: _page,
                      pageCount: pageCount,
                      onChanged: (page) => setState(() => _page = page),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminDashboard,
              (route) => false,
            );
          }
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          }
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.actionWidth,
    required this.staff,
    required this.onSet,
    required this.onView,
  });
  final double actionWidth;
  final StaffInfo staff;
  final VoidCallback onSet;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${staff.name} - ${staff.employeeId}',
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: actionWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: OutlinedButton(
                  onPressed: onSet,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Set'),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: TextButton(
                  onPressed: onView,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('View'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StaffTableHeader extends StatelessWidget {
  const _StaffTableHeader({required this.actionWidth, required this.color});
  final double actionWidth;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Staff Name / Meeting',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: actionWidth,
          child: const Text(
            'Action',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 0 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (var index = 0; index < pageCount; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text('${index + 1}'),
              selected: index == page,
              onSelected: (_) => onChanged(index),
            ),
          ),
        IconButton(
          onPressed: page + 1 < pageCount ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.action});
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class SetupMeetingDialog extends StatefulWidget {
  const SetupMeetingDialog({super.key, required this.staff, this.meeting});
  final StaffInfo staff;
  final OneOnOneMeeting? meeting;

  @override
  State<SetupMeetingDialog> createState() => _SetupMeetingDialogState();
}

class _SetupMeetingDialogState extends State<SetupMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _start;
  late DateTime? _end;
  TimeOfDay? _meetingTime;
  late final TextEditingController _info;
  late final TextEditingController _url;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final meeting = widget.meeting;
    _start = meeting?.startDateTime;
    _end = meeting?.endDateTime;
    _meetingTime = meeting == null ? null : _parseTime(meeting.meetingTime);
    _info = TextEditingController(text: meeting?.meetingInfo ?? '');
    _url = TextEditingController(text: meeting?.meetingUrl ?? '');
  }

  @override
  void dispose() {
    _info.dispose();
    _url.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    if (match.group(3)?.toUpperCase() == 'PM' && hour < 12) hour += 12;
    if (match.group(3)?.toUpperCase() == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeText(TimeOfDay value) => value.format(context);
  String _dateText(DateTime? value) => value == null
      ? 'Select date and time'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${TimeOfDay.fromDateTime(value).format(context)}';

  Future<void> _pickStart() async {
    final value = await _pickDateTime(_start ?? DateTime.now());
    if (value != null) setState(() => _start = value);
  }

  Future<void> _pickEnd() async {
    final value = await _pickDateTime(_end ?? _start ?? DateTime.now());
    if (value != null) setState(() => _end = value);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return time == null
        ? null
        : DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_start == null || _end == null || _meetingTime == null) {
      _showError('Start, end, and meeting time are required.');
      return;
    }
    if (!_end!.isAfter(_start!)) {
      _showError('End date/time must be later than start date/time.');
      return;
    }
    final url = _url.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
      _showError('Enter a valid meeting URL.');
      return;
    }
    setState(() => _submitting = true);
    final old = widget.meeting;
    Navigator.pop(
      context,
      OneOnOneMeeting(
        id: old?.id,
        staffId: widget.staff.employeeId,
        staffName: widget.staff.name,
        startDateTime: _start!,
        endDateTime: _end!,
        meetingTime: _timeText(_meetingTime!),
        meetingInfo: _info.text.trim(),
        meetingUrl: url,
        createdAt: old?.createdAt,
        updatedAt: old?.updatedAt,
      ),
    );
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.meeting != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(editing ? 'Edit Meeting' : 'Setup Meeting')),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are setting up a meeting for:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  widget.staff.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text('Staff ID: ${widget.staff.employeeId}'),
                const SizedBox(height: 18),
                _picker('Start Date/Time', _dateText(_start), _pickStart),
                _picker('End Date/Time', _dateText(_end), _pickEnd),
                _picker(
                  'Time of Meeting',
                  _meetingTime == null
                      ? 'Select time'
                      : _timeText(_meetingTime!),
                  () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: _meetingTime ?? TimeOfDay.now(),
                    );
                    if (value != null) setState(() => _meetingTime = value);
                  },
                ),
                TextFormField(
                  controller: _info,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Info (How and where)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Meeting info is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Meeting URL link for Voice/Video Conference',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  _info.clear();
                  _url.clear();
                  setState(() {
                    _start = null;
                    _end = null;
                    _meetingTime = null;
                  });
                },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editing ? 'Update' : 'Insert'),
        ),
      ],
    );
  }

  Widget _picker(String label, String value, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const Icon(Icons.schedule),
          ],
        ),
      ),
    ),
  );
}

class MeetingHistoryDialog extends StatefulWidget {
  const MeetingHistoryDialog({
    super.key,
    required this.staff,
    required this.service,
    required this.onEdit,
  });
  final StaffInfo staff;
  final OneOnOneMeetingService service;
  final Future<void> Function(StaffInfo staff, OneOnOneMeeting meeting) onEdit;

  @override
  State<MeetingHistoryDialog> createState() => _MeetingHistoryDialogState();
}

class _MeetingHistoryDialogState extends State<MeetingHistoryDialog> {
  late Future<List<OneOnOneMeeting>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _future = widget.service.getAllForStaff(widget.staff.employeeId);

  Future<void> _delete(OneOnOneMeeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meeting?'),
        content: const Text('This meeting will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || meeting.id == null) return;
    await widget.service.delete(meeting.id!);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Meeting Info History')),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: FutureBuilder<List<OneOnOneMeeting>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              );
            }
            final meetings = snapshot.data ?? const <OneOnOneMeeting>[];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${widget.staff.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('ID: ${widget.staff.employeeId}'),
                  const Divider(height: 24),
                  if (meetings.isEmpty)
                    const Text(
                      'No meeting history available for this staff member.',
                    )
                  else
                    ...meetings.map(
                      (meeting) => _HistoryCard(
                        meeting: meeting,
                        onEdit: () async {
                          await widget.onEdit(widget.staff, meeting);
                          if (mounted) setState(_reload);
                        },
                        onDelete: () => _delete(meeting),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.meeting,
    required this.onEdit,
    required this.onDelete,
  });
  final OneOnOneMeeting meeting;
  final VoidCallback onDelete;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final status = meeting.endDateTime.isBefore(DateTime.now())
        ? 'Completed'
        : (meeting.startDateTime.isBefore(DateTime.now())
              ? 'Ongoing'
              : 'Upcoming');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: status == 'Completed' ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ],
            ),
            Text('Start: ${_date(meeting.startDateTime, context)}'),
            Text('End: ${_date(meeting.endDateTime, context)}'),
            Text('Time of Meeting: ${meeting.meetingTime}'),
            const SizedBox(height: 6),
            Text('Meeting Info: ${meeting.meetingInfo}'),
            if (meeting.meetingUrl.isNotEmpty)
              SelectableText('Meeting Link: ${meeting.meetingUrl}'),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value, BuildContext context) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year} ${TimeOfDay.fromDateTime(value).format(context)}';
}
