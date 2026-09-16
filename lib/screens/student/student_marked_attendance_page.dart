import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student_attendance.dart';
import '../../services/app_state.dart';
import '../../services/student_attendance_service.dart';
import '../../services/student_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentMarkedAttendancePage extends StatefulWidget {
  const StudentMarkedAttendancePage({
    super.key,
    this.headerTitle = 'Attendance',
  });

  final String headerTitle;

  @override
  State<StudentMarkedAttendancePage> createState() =>
      _StudentMarkedAttendancePageState();
}

class _StudentMarkedAttendancePageState
    extends State<StudentMarkedAttendancePage> {
  final _attendanceService = StudentAttendanceService();
  final _studentService = StudentService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<StudentAttendance> _records = const [];
  StudentRecord? _student;
  bool _loading = true;
  String? _error;

  String get _studentId => context.read<AppState>().currentUserId?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_studentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No signed-in student was found.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recordsFuture = _attendanceService.getForStudent(_studentId);
      final token = context.read<AppState>().currentAuthToken;
      final profileFuture = token == null || token.isEmpty
          ? Future<StudentRecord?>.value(null)
          : _studentService
                .getCurrentProfile(token: token)
                .then<StudentRecord?>((value) => value);
      final results = await Future.wait<dynamic>([
        recordsFuture,
        profileFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _records = results[0] as List<StudentAttendance>;
        _student = results[1] as StudentRecord?;
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

  List<StudentAttendance> get _monthRecords => _records.where((record) {
    final date = DateTime.tryParse(record.attendanceDate);
    return date != null &&
        date.year == _month.year &&
        date.month == _month.month;
  }).toList();

  List<DateTime> get _months {
    final now = DateTime.now();
    return List.generate(24, (index) => DateTime(now.year, now.month - index));
  }

  int _count(String status) =>
      _monthRecords.where((record) => record.status == status).length;

  String _monthLabel(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _day(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '';
    return _dayNames[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: QuickAccessAppBar(title: widget.headerTitle),
    body: _body(),
    bottomNavigationBar: const AppBottomNavigation(),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(fontSize: 10)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final present = _count('Present');
    final absent = _count('Absent');
    final leave = _count('Leave');
    final total = present + absent + leave;
    final percentage = total == 0 ? 0 : present * 100 / total;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
        children: [
          Text(
            'Student Name: ${_student?.name.isNotEmpty == true ? _student!.name : _monthRecords.firstOrNull?.studentName ?? _studentId}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Student ID: ${_student?.studentId.isNotEmpty == true ? _student!.studentId : _studentId}',
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text(
            'Marked Attendance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff1d3557),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<DateTime>(
            initialValue:
                _months.any(
                  (item) =>
                      item.year == _month.year && item.month == _month.month,
                )
                ? _month
                : _months.first,
            decoration: const InputDecoration(
              labelText: 'Month',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _months
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      _monthLabel(item),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _month = value);
            },
          ),
          const SizedBox(height: 12),
          _summary(total, present, absent, leave, percentage.toDouble()),
          const SizedBox(height: 12),
          if (_monthRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No attendance records available',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            )
          else
            _historyTable(),
        ],
      ),
    );
  }

  Widget _summary(
    int total,
    int present,
    int absent,
    int leave,
    double percentage,
  ) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffd8dde2)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _summaryItem('Total Days', total),
            _summaryItem('Present', present),
            _summaryItem('Absent', absent),
            _summaryItem('Leave', leave),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Attendance: ${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _summaryItem(String label, int value) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xff1d3557),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 8)),
      ],
    ),
  );

  Widget _historyTable() => Table(
    border: TableBorder.all(color: const Color(0xffd8dde2), width: .6),
    columnWidths: const {
      0: FlexColumnWidth(1.4),
      1: FlexColumnWidth(1.1),
      2: FlexColumnWidth(1),
    },
    children: [
      _row(['Date', 'Day', 'Status'], true),
      ..._monthRecords.map(
        (record) => _row([
          _displayDate(record.attendanceDate),
          _day(record.attendanceDate),
          record.status,
        ], false),
      ),
    ],
  );

  TableRow _row(List<String> values, bool header) => TableRow(
    decoration: BoxDecoration(
      color: header ? const Color(0xffe5e9ed) : Colors.white,
    ),
    children: values
        .map(
          (value) => Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 9,
                fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                color: header ? const Color(0xff1d3557) : _statusColor(value),
              ),
            ),
          ),
        )
        .toList(),
  );

  Color _statusColor(String value) => value == 'Present'
      ? Colors.green.shade700
      : value == 'Absent'
      ? Colors.red.shade700
      : value == 'Leave'
      ? Colors.orange.shade800
      : const Color(0xff355c8a);
}

const _monthNames = <String>[
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
const _dayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
