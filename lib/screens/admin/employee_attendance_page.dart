import 'package:flutter/material.dart';

import '../../models/employee_attendance.dart';
import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import 'employee_attendance_history_page.dart';
import '../../services/employee_attendance_service.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  final _staffService = StaffService();
  final _attendanceService = EmployeeAttendanceService();
  final _searchController = TextEditingController();
  DateTime _workingDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();
  List<StaffInfo> _staff = const [];
  List<EmployeeAttendance> _dayRecords = const [];
  List<EmployeeAttendance> _allRecords = const [];
  List<EmployeeAttendance> _pending = const [];
  Map<String, dynamic> _summary = const {};
  int _tab = 0;
  bool _loading = true;
  String? _error;

  String get _dateKey => _workingDate.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _staffService.getStaff(),
        _attendanceService.getAll(date: _dateKey),
        _attendanceService.getAll(),
        _attendanceService.getPending(_dateKey),
        _attendanceService.getSummary(_dateKey),
      ]);
      if (!mounted) return;
      setState(() {
        _staff = results[0] as List<StaffInfo>;
        _dayRecords = results[1] as List<EmployeeAttendance>;
        _allRecords = results[2] as List<EmployeeAttendance>;
        _pending = results[3] as List<EmployeeAttendance>;
        _summary = results[4] as Map<String, dynamic>;
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

  Future<void> _selectDate(DateTime value) async {
    setState(() {
      _workingDate = DateTime(value.year, value.month, value.day);
      _displayedMonth = DateTime(value.year, value.month, 1);
    });
    await _load();
  }

  Future<void> _approve(EmployeeAttendance record) async {
    if (record.id == null) return;
    try {
      await _attendanceService.approve(record.id!);
      await _load();
      if (mounted) _message('Attendance approved successfully.');
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _showLate() async {
    try {
      final records = await _attendanceService.getLate(_dateKey);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => _LateDialog(records: records, date: _dateKey),
      );
    } catch (error) {
      if (mounted) {
        _message(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Employee Attendance'),
        actions: [
          IconButton(
            onPressed: _load,
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
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Details')),
                      ButtonSegment(value: 1, label: Text('Report')),
                      ButtonSegment(value: 2, label: Text('List')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    _StateMessage(message: _error!, action: _load)
                  else if (_tab == 0)
                    _DetailsTab(
                      workingDate: _workingDate,
                      displayedMonth: _displayedMonth,
                      records: _dayRecords,
                      pending: _pending,
                      staff: _staff,
                      summary: _summary,
                      onDateSelected: _selectDate,
                      onMonthChanged: (month) =>
                          setState(() => _displayedMonth = month),
                      onApprove: _approve,
                      onRecalculate: _load,
                      onLate: _showLate,
                    )
                  else if (_tab == 1)
                    _ReportTab(records: _allRecords, staff: _staff)
                  else
                    _ListTab(
                      records: _allRecords,
                      controller: _searchController,
                      onChanged: () => setState(() {}),
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

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.workingDate,
    required this.displayedMonth,
    required this.records,
    required this.pending,
    required this.staff,
    required this.summary,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onApprove,
    required this.onRecalculate,
    required this.onLate,
  });
  final DateTime workingDate;
  final DateTime displayedMonth;
  final List<EmployeeAttendance> records;
  final List<EmployeeAttendance> pending;
  final List<StaffInfo> staff;
  final Map<String, dynamic> summary;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<EmployeeAttendance> onApprove;
  final VoidCallback onRecalculate;
  final VoidCallback onLate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Date is ${_date(workingDate)} for Attendance Status.',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Change date by clicking on a date on the calendar.'),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => onMonthChanged(
                      DateTime(displayedMonth.year, displayedMonth.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _monthName(displayedMonth),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onMonthChanged(
                      DateTime(displayedMonth.year, displayedMonth.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              CalendarDatePicker(
                initialDate: workingDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                currentDate: DateTime.now(),
                onDateChanged: onDateSelected,
              ),
              TextButton(
                onPressed: () => onDateSelected(DateTime.now()),
                child: const Text('Today'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'Attendance Summary',
          actions: [
            OutlinedButton.icon(
              onPressed: onRecalculate,
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate'),
            ),
            FilledButton.icon(
              onPressed: onLate,
              icon: const Icon(Icons.schedule),
              label: const Text('Click to late Attendance'),
            ),
          ],
        ),
        _SummaryCard(date: workingDate, summary: summary),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Attendance to be approved for ${_date(workingDate)}',
        ),
        if (pending.isEmpty)
          const _StateMessage(message: 'No attendance pending approval.')
        else
          ...pending.map(
            (record) => _PendingCard(
              record: record,
              onApprove: () => onApprove(record),
            ),
          ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'Employee Attendance List'),
        if (staff.isEmpty)
          const _StateMessage(message: 'No employees found.')
        else
          ...staff.map(
            (employee) => _EmployeeDayCard(
              employee: employee,
              record: records.cast<EmployeeAttendance?>().firstWhere(
                (record) => record?.employeeId == employee.employeeId,
                orElse: () => null,
              ),
              onTap: () => Navigator.of(context).pushNamed(
                '${AppRoutes.adminEmployeeAttendance}/${_employeePathSegment(employee.name, employee.employeeId)}',
                arguments: {
                  'employeeId': employee.employeeId,
                  'employeeName': employee.name,
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.date, required this.summary});
  final DateTime date;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 28,
        runSpacing: 12,
        children: [
          _Metric(label: 'Date', value: _date(date)),
          _Metric(label: 'Total', value: '${summary['total'] ?? 0}'),
          _Metric(label: 'Present', value: '${summary['present'] ?? 0}'),
          _Metric(label: 'Absent', value: '${summary['absent'] ?? 0}'),
          _Metric(label: 'Pending', value: '${summary['pending'] ?? 0}'),
          _Metric(label: 'Late', value: '${summary['late'] ?? 0}'),
        ],
      ),
    ),
  );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.record, required this.onApprove});
  final EmployeeAttendance record;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final distance = record.distance == null ? '' : '${record.distance} km';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${record.teacherId} | ${record.employeeId}\n${record.employeeName}\n${record.attendanceType} $distance',
              ),
            ),
            Text(_time(record.timeRecorded, context)),
            const SizedBox(width: 8),
            FilledButton(onPressed: onApprove, child: const Text('Approve')),
          ],
        ),
      ),
    );
  }
}

class _EmployeeDayCard extends StatelessWidget {
  const _EmployeeDayCard({
    required this.employee,
    required this.record,
    required this.onTap,
  });
  final StaffInfo employee;
  final EmployeeAttendance? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.chevron_right, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('${employee.employeeId}\n${employee.name}')),
            Text(
              employee.employeeCategory.isEmpty
                  ? employee.designation
                  : employee.employeeCategory,
            ),
            const SizedBox(width: 16),
            _Pill(
              label: record == null
                  ? 'No'
                  : (record!.approved ? 'Yes' : 'Pending'),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: record == null
                  ? 'NA'
                  : (record!.selfAttendance ? 'Yes' : 'No'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _employeePathSegment(String name, String employeeId) {
  final source = name.trim().isEmpty ? employeeId : name.trim();
  final slug = source
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? Uri.encodeComponent(employeeId) : slug;
}

class _EmployeeAttendanceDetailsDialog extends StatefulWidget {
  const _EmployeeAttendanceDetailsDialog({
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;

  @override
  State<_EmployeeAttendanceDetailsDialog> createState() =>
      _EmployeeAttendanceDetailsDialogState();
}

class _EmployeeAttendanceDetailsDialogState
    extends State<_EmployeeAttendanceDetailsDialog> {
  final _service = EmployeeAttendanceService();
  late Future<List<EmployeeAttendance>> _records;

  @override
  void initState() {
    super.initState();
    _records = _service.getForEmployee(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.employeeName} Attendance'),
    content: SizedBox(
      width: 680,
      child: FutureBuilder<List<EmployeeAttendance>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 120,
              child: Center(child: Text(snapshot.error.toString())),
            );
          }
          final records = snapshot.data ?? const <EmployeeAttendance>[];
          if (records.isEmpty) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: Text('No attendance records found for this employee.'),
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            itemCount: records.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = records[index];
              final group = record.groupName.isEmpty
                  ? 'Class not specified'
                  : record.groupName;
              final subject = record.subject.isEmpty
                  ? 'Subject not specified'
                  : record.subject;
              return ListTile(
                dense: true,
                title: Text('${record.attendanceDate} | ${record.status}'),
                subtitle: Text(
                  '$group | $subject\n'
                  'Check-in: ${_time(record.timeRecorded, context)} | '
                  'Attendance: ${record.present ? 'Present' : 'Absent'} | '
                  'Late: ${record.isLate ? 'Yes' : 'No'}',
                ),
              );
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back'),
      ),
    ],
  );
}

class _ReportTab extends StatefulWidget {
  const _ReportTab({required this.records, required this.staff});
  final List<EmployeeAttendance> records;
  final List<StaffInfo> staff;

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();
  String? _employeeId;

  @override
  Widget build(BuildContext context) {
    final records = widget.records.where((record) {
      final date = DateTime.tryParse(record.attendanceDate);
      return date != null &&
          !date.isBefore(DateTime(_start.year, _start.month, _start.day)) &&
          !date.isAfter(DateTime(_end.year, _end.month, _end.day)) &&
          (_employeeId == null || record.employeeId == _employeeId);
    }).toList();
    final totalDays = _end.difference(_start).inDays + 1;
    final present = records
        .where((record) => record.approved && record.present)
        .length;
    final late = records.where((record) => record.isLate).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Attendance Report'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _dateButton(
              'Start Date',
              _start,
              (date) => setState(() => _start = date),
            ),
            _dateButton(
              'End Date',
              _end,
              (date) => setState(() => _end = date),
            ),
            DropdownButton<String>(
              value: _employeeId,
              hint: const Text('All employees'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All employees'),
                ),
                ...widget.staff.map(
                  (staff) => DropdownMenuItem(
                    value: staff.employeeId,
                    child: Text(staff.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _employeeId = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                _Metric(label: 'Working Days', value: '$totalDays'),
                _Metric(label: 'Present Days', value: '$present'),
                _Metric(
                  label: 'Absent Days',
                  value: '${(totalDays - present).clamp(0, totalDays)}',
                ),
                _Metric(label: 'Late Days', value: '$late'),
                _Metric(
                  label: 'Attendance %',
                  value: totalDays == 0
                      ? '0%'
                      : '${(present / totalDays * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateButton(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) => OutlinedButton(
    onPressed: () async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDate: value,
      );
      if (date != null) onChanged(date);
    },
    child: Text('$label: ${_date(value)}'),
  );
}

class _ListTab extends StatelessWidget {
  const _ListTab({
    required this.records,
    required this.controller,
    required this.onChanged,
  });
  final List<EmployeeAttendance> records;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final query = controller.text.toLowerCase();
    final filtered = records
        .where(
          (record) =>
              '${record.employeeName} ${record.employeeId} ${record.status}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'All Employee Attendance Records'),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search name, employee ID, or status',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const _StateMessage(message: 'No attendance records found.')
        else
          ...filtered.map(
            (record) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${record.employeeName} - ${record.employeeId}'),
                subtitle: Text(
                  '${record.groupName.isEmpty ? 'Class not specified' : record.groupName} | ${record.subject.isEmpty ? 'Subject not specified' : record.subject} | ${record.attendanceDate} ${_time(record.timeRecorded, context)} | ${record.attendanceType}',
                ),
                trailing: _Pill(label: record.status),
              ),
            ),
          ),
      ],
    );
  }
}

class _LateDialog extends StatelessWidget {
  const _LateDialog({required this.records, required this.date});
  final List<EmployeeAttendance> records;
  final String date;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Late Attendance - $date'),
    content: SizedBox(
      width: 620,
      child: records.isEmpty
          ? const Text('No late attendance records.')
          : ListView(
              shrinkWrap: true,
              children: records
                  .map(
                    (record) => ListTile(
                      title: Text(
                        '${record.employeeName} - ${record.employeeId}',
                      ),
                      subtitle: Text(
                        'Recorded: ${_time(record.timeRecorded, context)}',
                      ),
                      trailing: const Text('Late'),
                    ),
                  )
                  .toList(),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final titleWidget = Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
      final content = constraints.maxWidth < 600
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleWidget,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: titleWidget),
                ...actions,
              ],
            );
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: content,
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.action});
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.event_busy, size: 44, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _monthName(DateTime value) =>
    '${_months[value.month - 1]} ${value.year}';
String _time(DateTime? value, BuildContext context) => value == null
    ? 'Not recorded'
    : TimeOfDay.fromDateTime(value).format(context);
const _months = [
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
