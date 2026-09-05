import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/staff_footer.dart';

class StaffSwipeAttendancePage extends StatefulWidget {
  const StaffSwipeAttendancePage({super.key});

  @override
  State<StaffSwipeAttendancePage> createState() =>
      _StaffSwipeAttendancePageState();
}

class _StaffSwipeAttendancePageState extends State<StaffSwipeAttendancePage> {
  Future<void> _registerAttendance() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _RegisterAttendanceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 45,
        elevation: 0,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: Text('My Attendance', style: TextStyle(fontSize: 11)),
                ),
                TextButton(
                  onPressed: _registerAttendance,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Register Attendance',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 66,
            child: Column(
              children: [
                const SizedBox(height: 9),
                const Text(
                  'Click to register Attendance',
                  style: TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 7),
                InkWell(
                  onTap: _registerAttendance,
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xffbd1d0a),
                    child: Icon(Icons.check_box, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const _AttendanceTable(
            title: 'My Attendance(Last 100)',
            columns: [
              'Date',
              'Recorded At',
              'Type',
              'Approved',
              'GPS',
              'Distance(K)',
              'Action',
            ],
          ),
          const _AttendanceTable(
            title: 'My Attendance(Last 100)',
            columns: ['Date', 'Recorded At', 'Present', 'Type'],
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.title, required this.columns});

  final String title;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 7, top: 5),
          child: Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xff172d50)),
          ),
        ),
        SizedBox(
          height: 19,
          child: Row(
            children: columns
                .map(
                  (column) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        column,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(fontSize: 7),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _RegisterAttendanceDialog extends StatefulWidget {
  const _RegisterAttendanceDialog();

  @override
  State<_RegisterAttendanceDialog> createState() =>
      _RegisterAttendanceDialogState();
}

class _RegisterAttendanceDialogState extends State<_RegisterAttendanceDialog> {
  String? _attendanceType;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}, '
        '${now.year} ${_time(now)}';
    const options = [
      'On Site',
      'Work from Home',
      'Training',
      'Office Work',
      'Other',
    ];

    return AlertDialog(
      title: const Center(
        child: Text('Register your Attendance', style: TextStyle(fontSize: 14)),
      ),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your attendance will be taken with date-time as $date',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 6),
            const Text(
              'You should do this from mobile. You should also give permission to allow GPS access otherwise attendance will not be registered',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 7),
            RadioGroup<String>(
              groupValue: _attendanceType,
              onChanged: (value) => setState(() => _attendanceType = value),
              child: Column(
                children: options
                    .map(
                      (option) => SizedBox(
                        height: 24,
                        child: RadioListTile<String>(
                          value: option,
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _attendanceType == null
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text(
            'Yes, register attendance',
            style: TextStyle(fontSize: 9),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 9)),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }

  String _weekday(int value) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value - 1];
  String _month(int value) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][value - 1];
  String _time(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    return '${hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
