import 'package:flutter/material.dart';

import '../../models/one_on_one_meeting.dart';
import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/one_on_one_meeting_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import 'one_on_one_staff_meetings_page.dart';

class OneOnOneMeetingInfoPage extends StatefulWidget {
  const OneOnOneMeetingInfoPage({super.key, required this.staff});

  final StaffInfo staff;

  @override
  State<OneOnOneMeetingInfoPage> createState() =>
      _OneOnOneMeetingInfoPageState();
}

class _OneOnOneMeetingInfoPageState extends State<OneOnOneMeetingInfoPage> {
  final _service = OneOnOneMeetingService();
  List<OneOnOneMeeting> _meetings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meetings = await _service.getAllForStaff(widget.staff.employeeId);
      if (!mounted) return;
      setState(() {
        _meetings = meetings;
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

  Future<void> _edit(OneOnOneMeeting meeting) async {
    final updated = await showDialog<OneOnOneMeeting>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetupMeetingDialog(staff: widget.staff, meeting: meeting),
    );
    if (updated == null) return;
    try {
      await _service.save(updated);
      await _loadHistory();
      if (mounted) _message('Meeting updated successfully.');
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

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
    try {
      await _service.delete(meeting.id!);
      await _loadHistory();
      if (mounted) _message('Meeting deleted successfully.');
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Meeting Info History'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 700 ? 16.0 : 32.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
                children: [
                  Text(
                    widget.staff.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Staff ID: ${widget.staff.employeeId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 28),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    _HistoryState(message: _error!, action: _loadHistory)
                  else if (_meetings.isEmpty)
                    const _HistoryState(
                      message:
                          'No meeting history available for this staff member.',
                    )
                  else
                    ..._meetings.map(
                      (meeting) => _MeetingHistoryCard(
                        meeting: meeting,
                        onEdit: () => _edit(meeting),
                        onDelete: () => _delete(meeting),
                      ),
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

class _MeetingHistoryCard extends StatelessWidget {
  const _MeetingHistoryCard({
    required this.meeting,
    required this.onEdit,
    required this.onDelete,
  });

  final OneOnOneMeeting meeting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = meeting.endDateTime.isBefore(DateTime.now())
        ? 'Completed'
        : (meeting.startDateTime.isBefore(DateTime.now())
              ? 'Ongoing'
              : 'Upcoming');
    final statusColor = status == 'Completed'
        ? Colors.grey.shade700
        : Colors.green.shade700;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
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
            Text('Start: ${_dateTime(meeting.startDateTime, context)}'),
            Text('End: ${_dateTime(meeting.endDateTime, context)}'),
            Text('Time of Meeting: ${meeting.meetingTime}'),
            const SizedBox(height: 8),
            Text('Meeting Info: ${meeting.meetingInfo}'),
            if (meeting.meetingUrl.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText('Meeting Link: ${meeting.meetingUrl}'),
            ],
          ],
        ),
      ),
    );
  }

  String _dateTime(DateTime value, BuildContext context) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year} ${TimeOfDay.fromDateTime(value).format(context)}';
}

class _HistoryState extends StatelessWidget {
  const _HistoryState({required this.message, this.action});

  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.history, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
