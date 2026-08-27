import 'package:flutter/material.dart';

import '../../widgets/dashboard_bottom_nav.dart';

class SchoolResourcesPage extends StatelessWidget {
  const SchoolResourcesPage({super.key});

  static const _resources = [
    [
      'Parental Acknowledgment on Student Non-Participation in School Activities Due to Absence from School',
      '27-Jun-25',
    ],
    ['Election short listed Candidates Name list AY 2026-27', '18-Jun-25'],
    ['Election Process Flow for the Academic Year 2026-27', '18-Jun-25'],
    ['F10 - F1 APP ACKNOWLEDGEMENT FORM', '01-Jun-25'],
    ['Oath Of Office for a Prefect', '19-Apr-25'],
    [
      'F46-I5 - Elect Class Prefect Nomination & Self-Declaration Form',
      '22-Aug-25',
    ],
    ['Choice Form for Academic year 2026 - 27', '03-Apr-25'],
    [
      'Incorporating the Vitamin Chart into the School Food System',
      '14-Apr-24',
    ],
    ['Foundation and Integrated NEET / JEE Program - Fee Details', '02-Mar-24'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 42,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(7, 7, 7, 5),
            child: Text('Resource List', style: TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
              itemCount: _resources.length,
              itemBuilder: (context, index) => _SchoolResourceRow(
                title: _resources[index][0],
                date: _resources[index][1],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Quick Menu'),
        ],
      ),
    );
  }
}

class _SchoolResourceRow extends StatelessWidget {
  const _SchoolResourceRow({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 47),
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(3, 4, 4, 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xff173c70)),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 6, color: Color(0xff555555)),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _ResourceAction(Icons.visibility_outlined),
              _ResourceAction(Icons.info_outline),
              _ResourceAction(Icons.delete_outline),
              _ResourceAction(Icons.edit_outlined),
              _ResourceAction(Icons.download_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Icon(icon, size: 12, color: const Color(0xff777777)),
    );
  }
}
