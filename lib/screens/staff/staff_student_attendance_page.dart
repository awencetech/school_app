import 'package:flutter/material.dart';

import '../../models/student_attendance.dart';
import '../../services/student_attendance_service.dart';
import '../../services/student_service.dart';

class StaffStudentAttendancePage extends StatefulWidget {
  const StaffStudentAttendancePage({super.key});

  @override
  State<StaffStudentAttendancePage> createState() =>
      _StaffStudentAttendancePageState();
}

class _StaffStudentAttendancePageState
    extends State<StaffStudentAttendancePage> {
  final _attendanceService = StudentAttendanceService();
  final _studentService = StudentService();
  final _searchController = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime _fromDate = DateTime(2020, 1, 1);
  DateTime _toDate = DateTime.now();
  List<StudentRecord> _students = const [];
  List<StudentAttendance> _records = const [];
  Map<String, String> _statuses = {};
  String _reportStatus = 'All';
  int _tab = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _key(StudentRecord student) => student.studentId.trim().isNotEmpty
      ? student.studentId.trim()
      : student.admissionNumber.trim();

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

  Future<void> _loadRoster() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _studentService.getStudents();
      if (!mounted) return;
      setState(() => _students = students);
      await _loadDate();
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _loadDate() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final records = await _attendanceService.getForDate(_date);
      final statuses = <String, String>{};
      for (final record in records) {
        if (record.status != 'Pending') {
          statuses[record.studentId] = record.status;
        }
      }
      if (mounted) {
        setState(() {
          _records = records;
          _statuses = statuses;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _loadDate();
    }
  }

  Future<void> _saveAttendance() async {
    final missing = _students
        .where((student) => !_statuses.containsKey(_key(student)))
        .length;
    if (missing > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mark attendance for all students first ($missing remaining).',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      for (final student in _students) {
        final status = _statuses[_key(student)]!;
        await _attendanceService.save(
          StudentAttendance(
            studentId: _key(student),
            studentName: student.name,
            admissionNumber: student.admissionNumber,
            className: student.className,
            section: student.section,
            attendanceDate: _dateOnly(_date),
            subject: 'All Day',
            classType: 'Classroom',
            reason: '',
            status: status,
            present: status == 'Present',
          ),
        );
      }
      await _loadDate();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved successfully.')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final records = await _attendanceService.getReport(
        fromDate: _dateOnly(_fromDate),
        toDate: _dateOnly(_toDate),
        status: _reportStatus,
      );
      if (mounted)
        setState(() {
          _records = records;
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

  Future<void> _pickReportDate(bool from) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from)
        _fromDate = picked;
      else
        _toDate = picked;
    });
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: _tabButton('Attendance', 0)),
          Expanded(child: _tabButton('Report', 1)),
        ],
      ),
      Expanded(child: _tab == 0 ? _attendanceView() : _reportView()),
    ],
  );

  Widget _tabButton(String label, int tab) => TextButton(
    onPressed: () {
      setState(() => _tab = tab);
      if (tab == 1) _loadReport();
    },
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: _tab == tab ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );

  Widget _attendanceView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return _stateBox(_error!, () {
        _error = null;
        _loadRoster();
      });
    return RefreshIndicator(
      onRefresh: _loadRoster,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
        children: [
          Row(
            children: [
              const Text(
                'Date:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  _displayDate(_date),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_students.isEmpty) _stateBox('No students found.', null),
          ..._students.map(_studentRow),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _saveAttendance,
            icon: const Icon(Icons.save, size: 16),
            label: Text(_saving ? 'Saving...' : 'Save Attendance'),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(StudentRecord student) {
    final key = _key(student);
    final selected = _statuses[key];
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name.isEmpty ? key : student.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              '${student.studentId.isEmpty ? student.admissionNumber : student.studentId}${student.className.isEmpty ? '' : '  |  ${student.className} ${student.section}'}',
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 4,
              children: ['Present', 'Absent', 'Leave']
                  .map(
                    (status) => ChoiceChip(
                      label: Text(status, style: const TextStyle(fontSize: 9)),
                      selected: selected == status,
                      onSelected: (_) =>
                          setState(() => _statuses[key] = status),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _records.where((record) {
      if (query.isEmpty) {
        return true;
      }
      return record.studentName.toLowerCase().contains(query) ||
          record.studentId.toLowerCase().contains(query) ||
          record.admissionNumber.toLowerCase().contains(query);
    }).toList();
    final present = filtered
        .where((record) => record.status == 'Present')
        .length;
    final absent = filtered.where((record) => record.status == 'Absent').length;
    final leave = filtered.where((record) => record.status == 'Leave').length;
    final total = present + absent + leave;
    final grouped = <String, List<StudentAttendance>>{};
    for (final record in filtered) {
      grouped.putIfAbsent(record.studentId, () => []).add(record);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _dateButton(
                'From',
                _fromDate,
                () => _pickReportDate(true),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _dateButton('To', _toDate, () => _pickReportDate(false)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _reportStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: ['All', 'Present', 'Absent', 'Leave']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _reportStatus = value ?? 'All');
            _loadReport();
          },
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Search student',
            prefixIcon: Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _stat('Total', total),
            _stat('Present', present),
            _stat('Absent', absent),
            _stat('Leave', leave),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Average Attendance: ${total == 0 ? '0' : (present * 100 / total).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        if (filtered.isEmpty)
          _stateBox('No attendance records available', null),
        ...grouped.entries.map((entry) {
          final records = entry.value;
          final student = records.first;
          final studentPresent = records
              .where((record) => record.status == 'Present')
              .length;
          final studentAbsent = records
              .where((record) => record.status == 'Absent')
              .length;
          final studentLeave = records
              .where((record) => record.status == 'Leave')
              .length;
          final marked = studentPresent + studentAbsent + studentLeave;
          final percentage = marked == 0 ? 0 : studentPresent * 100 / marked;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              student.studentName.isEmpty
                  ? student.studentId
                  : student.studentName,
              style: const TextStyle(fontSize: 10),
            ),
            subtitle: Text(
              'Present: $studentPresent  Absent: $studentAbsent  Leave: $studentLeave',
              style: const TextStyle(fontSize: 9),
            ),
            trailing: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          );
        }),
      ],
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        child: Text(
          '$label: ${_displayDate(date)}',
          style: const TextStyle(fontSize: 9),
        ),
      );
  Widget _stat(String label, int value) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        Text(label, style: const TextStyle(fontSize: 8)),
      ],
    ),
  );
  Color _statusColor(String status) => status == 'Present'
      ? Colors.green
      : status == 'Absent'
      ? Colors.red
      : Colors.orange;
  Widget _stateBox(String message, VoidCallback? retry) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(message, style: const TextStyle(fontSize: 10)),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}
