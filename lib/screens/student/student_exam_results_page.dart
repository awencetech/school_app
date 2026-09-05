import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentExamResultsPage extends StatelessWidget {
  const StudentExamResultsPage({super.key});

  static const _exams = [
    _ExamResult(
      '10-C - Objective Type test - 1 - 5 (2026-27)',
      'Objective Type test - 1 - 5 (2026-27)',
      '19-Aug-26',
    ),
    _ExamResult(
      '10-C - CYCLE TEST - 1-5 2026-27',
      'Cycle Test 1-5 2026-27',
      '19-Aug-26',
    ),
    _ExamResult(
      '10-C - I MID TERM EXAMINATION(2026-27)',
      'MID TERM EXAMINATION(2026-27)',
      '30-Jul-26',
    ),
    _ExamResult(
      '10-C - Objective Type test - 1 - 4 (2026-27)',
      'Objective Type test - 1 - 4 (2026-27)',
      '05-Jul-26',
    ),
    _ExamResult(
      '10-C - CYCLE TEST - 1-4 (2026-27)',
      'Cycle Test 1-4 (2026-27)',
      '30-Jun-26',
    ),
    _ExamResult(
      '10-C - CYCLE TEST - 1 (2026-27)',
      'Cycle Test - 1 (2026-27)',
      '09-May-26',
    ),
    _ExamResult(
      '9-C - TERM SERIES (2025-26)',
      'Term Series (2025-26)',
      '23-Mar-26',
    ),
    _ExamResult(
      '9-C - TERMINAL III EXAMINATION (2025-26)',
      'Terminal III Examination (2025-26)',
      '22-Mar-26',
    ),
    _ExamResult('9-C - MID TERM III', 'Mid Term III', '23-Mar-26'),
    _ExamResult(
      '9-C - TERM SERIES 2025-26',
      'Term Series 2025-26',
      '14-Jan-26',
    ),
    _ExamResult('9-C - TERMINAL-2 2025-26', 'Terminal-2 2025-26', '14-Jan-26'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
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
            padding: EdgeInsets.fromLTRB(3, 8, 3, 7),
            child: Text(
              'Scores, Results',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              itemCount: _exams.length,
              itemBuilder: (context, index) => _ExamCard(result: _exams[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.result});

  final _ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd2d2d2)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(fontSize: 10, color: Color(0xff222222)),
          ),
          Text(
            'Year: 2026 Type:${result.type}',
            style: const TextStyle(fontSize: 7, color: Color(0xff355c8a)),
          ),
          Text(
            'Created on ${result.createdOn}',
            style: const TextStyle(fontSize: 7, color: Color(0xff355c8a)),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 7,
              children: [
                _ActionLink(
                  icon: Icons.check_box_outline_blank,
                  label: 'Select',
                  onTap: () {},
                ),
                _ActionLink(icon: Icons.print, label: 'Print', onTap: () {}),
                _ActionLink(icon: Icons.print, label: 'Print', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xff888888)),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Color(0xff777777)),
          ),
        ],
      ),
    );
  }
}

class _ExamResult {
  const _ExamResult(this.title, this.type, this.createdOn);

  final String title;
  final String type;
  final String createdOn;
}
