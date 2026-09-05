import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  int _selectedTab = 0;

  static const _absenceRows = [
    ['2026-08-12', '10 C', 'All Day', 'Classroom'],
    ['2026-05-30', '10 C', 'All Day', 'Classroom'],
    ['2026-05-15', '10 C', 'All Day', 'Classroom'],
    ['2026-02-25', '9 C', 'All Day', 'Classroom'],
    ['2026-02-24', '9 C', 'All Day', 'Classroom'],
    ['2026-02-13', '9 C', 'All Day', 'Classroom'],
    ['2025-12-20', '9 C', 'All Day', 'Classroom'],
    ['2025-11-06', '9 C', 'All Day', 'Classroom'],
    ['2025-10-25', '9 C', 'All Day', 'Classroom'],
    ['2025-09-24', '9 C', 'All Day', 'Classroom'],
  ];

  static const _leaveRequests = [
    _LeaveRequest(
      '10 C - 2026',
      '15-May-26',
      '15-May-26',
      'not attended',
      'not attended',
    ),
    _LeaveRequest(
      '8 B - 2024',
      '09-Dec-24',
      '10-Dec-24',
      'Going to attend my mothers PhD viva presentation',
      'APPROVED MAM',
    ),
    _LeaveRequest(
      '8 B - 2024',
      '17-Oct-24',
      '19-Oct-24',
      'Fever',
      'APPROVED MAM',
    ),
    _LeaveRequest(
      'UNI_Route_Z2 - 2023',
      '30-Jul-24',
      '30-Jul-24',
      'Mother is not well and I am taking care of her',
      'not attended',
    ),
    _LeaveRequest(
      '8 B - 2024',
      '19-Jun-24',
      '20-Jun-24',
      'Fever and stomach pain',
      'APPROVED MAM',
    ),
    _LeaveRequest('6 B - 2022', '02-Mar-23', '03-Mar-23', 'Fever', 'NOTED MAM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 43,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 7),
            child: Text(
              'Attendance, Absence, Apply for Leave',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 5),
            child: Text(
              'For MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              _Tab(
                label: 'Absence',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _Tab(
                label: 'Apply',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _Tab(
                label: 'Analytics',
                selected: _selectedTab == 2,
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedTab == 0
                ? _absenceView()
                : _selectedTab == 1
                ? _leaveView()
                : _analyticsView(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _absenceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Absence Details',
            style: TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const Text(
            'Shows latest 10 records (Click on Analytics for more details)',
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: Color(0xff1d3557),
            ),
          ),
          const SizedBox(height: 5),
          _absenceTable(_absenceRows),
        ],
      ),
    );
  }

  Widget _leaveView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Leave Request',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff1d3557),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 19,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: Color(0xff16a6b7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text(
                    'Apply Leave',
                    style: TextStyle(fontSize: 7, color: Color(0xff16a6b7)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ..._leaveRequests.map(_leaveCard),
        ],
      ),
    );
  }

  Widget _analyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(3, 5, 3, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 225,
            child: CustomPaint(painter: _AttendanceChartPainter()),
          ),
          const Text(
            'Absence Details',
            style: TextStyle(fontSize: 10, color: Color(0xff555555)),
          ),
          const Text(
            'Shows latest 100 records only',
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: Color(0xff555555),
            ),
          ),
          const SizedBox(height: 5),
          _absenceTable(_absenceRows),
        ],
      ),
    );
  }

  Widget _absenceTable(List<List<String>> rows) {
    return Table(
      border: TableBorder.all(color: const Color(0xffd8dde2), width: .6),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.25),
      },
      children: [
        _tableRow(['Date', 'Class', 'Subject', 'Class Type'], true),
        ...rows.map((row) => _tableRow(row, false)),
      ],
    );
  }

  TableRow _tableRow(List<String> values, bool header) => TableRow(
    decoration: BoxDecoration(
      color: header ? const Color(0xffe5e9ed) : Colors.white,
    ),
    children: values
        .map(
          (value) => Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 7,
                fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xff355c8a),
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _leaveCard(_LeaveRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            'Created on ${request.created}',
            style: const TextStyle(fontSize: 8),
          ),
          Text(
            'From: ${request.from} to ${request.to}',
            style: const TextStyle(fontSize: 8),
          ),
          Text(
            'Reason: ${request.reason}',
            style: const TextStyle(fontSize: 8),
          ),
          Text(
            'Acknowledge note: ${request.note}',
            style: const TextStyle(fontSize: 8),
          ),
          Row(
            children: [
              Text('Status: approved', style: const TextStyle(fontSize: 8)),
              const SizedBox(width: 3),
              const Icon(Icons.circle, size: 8, color: Color(0xff62d878)),
              const Spacer(),
              const Text(
                'Comment   Delete',
                style: TextStyle(fontSize: 8, color: Color(0xff087ff5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      width: label == 'Analytics' ? 72 : 66,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Colors.white : const Color(0xfff7f7f7),
        border: Border.all(color: const Color(0xffdddddd)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: selected ? const Color(0xff333333) : const Color(0xff087ff5),
        ),
      ),
    ),
  );
}

class _LeaveRequest {
  const _LeaveRequest(this.title, this.from, this.to, this.reason, this.note);

  final String title;
  final String created = '15-May-26';
  final String from;
  final String to;
  final String reason;
  final String note;
}

class _AttendanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0xff555555)
      ..strokeWidth = .8;
    final bar = Paint()..color = const Color(0xff287bb4);
    canvas.drawLine(const Offset(16, 8), Offset(16, size.height - 30), axis);
    canvas.drawLine(
      Offset(16, size.height - 30),
      Offset(size.width - 28, size.height - 30),
      axis,
    );
    for (var i = 0; i <= 10; i++) {
      final y = size.height - 30 - (i * (size.height - 45) / 10);
      canvas.drawLine(Offset(13, y), Offset(19, y), axis);
      final painter = TextPainter(
        text: TextSpan(
          text: '${i}0',
          style: const TextStyle(fontSize: 7, color: Color(0xff555555)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - 4));
    }
    canvas.drawRect(Rect.fromLTWH(82, size.height - 30 - 138, 64, 138), bar);
    canvas.drawRect(
      Rect.fromLTWH(150, size.height - 30 - 4, 64, 4),
      Paint()..color = const Color(0xfff58220),
    );
    final label = TextPainter(
      text: const TextSpan(
        text: 'C All Day Classroom',
        style: TextStyle(fontSize: 7, color: Color(0xff333333)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(115, size.height - 24);
    canvas.rotate(-1.57);
    label.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
