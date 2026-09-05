import 'package:flutter/material.dart';

import '../../models/employee_attendance.dart';
import '../../services/employee_attendance_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class EmployeeAttendanceHistoryPage extends StatefulWidget {
  const EmployeeAttendanceHistoryPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;

  @override
  State<EmployeeAttendanceHistoryPage> createState() =>
      _EmployeeAttendanceHistoryPageState();
}

class _EmployeeAttendanceHistoryPageState
    extends State<EmployeeAttendanceHistoryPage> {
  late final Future<List<EmployeeAttendance>> _records;

  @override
  void initState() {
    super.initState();
    _records = EmployeeAttendanceService().getForEmployee(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Employee Attendance'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: FutureBuilder<List<EmployeeAttendance>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(message: snapshot.error.toString());
          }
          final records = [...snapshot.data ?? const <EmployeeAttendance>[]]
            ..sort((left, right) => right.attendanceDate.compareTo(left.attendanceDate));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              const Text(
                'Employee Attendance List',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                widget.employeeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Staff ID: ${widget.employeeId}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              if (records.isEmpty)
                Text(
                  'No attendance records found for ${widget.employeeName}',
                  style: const TextStyle(fontSize: 14),
                )
              else
                _AttendanceTable(records: records),
            ],
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.records});

  final List<EmployeeAttendance> records;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        color: const Color(0xffe5e9ed),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: const Row(
          children: [
            Expanded(flex: 2, child: Text('Date', style: _headerStyle)),
            Expanded(flex: 2, child: Text('Status', style: _headerStyle)),
            Expanded(flex: 2, child: Text('Approval', style: _headerStyle)),
            SizedBox(width: 24),
          ],
        ),
      ),
      ...records.map((record) => _AttendanceRow(record: record)),
    ],
  );

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xff263238),
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final EmployeeAttendance record;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      title: Row(
        children: [
          Expanded(flex: 2, child: Text(_date(record.attendanceDate))),
          Expanded(
            flex: 2,
            child: Text(record.present ? 'Present' : 'Absent'),
          ),
          Expanded(flex: 2, child: Text(record.status)),
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              if (record.timeRecorded != null)
                Text('Check-in: ${_formatTime(record.timeRecorded!)}'),
              if (record.subject.isNotEmpty) Text('Subject: ${record.subject}'),
              if (record.groupName.isNotEmpty) Text('Class: ${record.groupName}'),
              Text('Late: ${record.isLate ? 'Yes' : 'No'}'),
            ],
          ),
        ),
      ],
    ),
  );

  static String _date(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}-${parts[1]}-${parts[0]}' : value;
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
