import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class StaffOverviewDashboardPage extends StatefulWidget {
  const StaffOverviewDashboardPage({super.key});

  @override
  State<StaffOverviewDashboardPage> createState() =>
      _StaffOverviewDashboardPageState();
}

class _StaffOverviewDashboardPageState
    extends State<StaffOverviewDashboardPage> {
  bool _showAdminDashboard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        toolbarHeight: 42,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(3, 7, 3, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Educational Tour | Pondicherry - Mahabalipuram - Chennai | 27-30 Aug',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: Color(0xff222222)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Tab(
                  label: 'User Dash',
                  selected: !_showAdminDashboard,
                  onTap: () => setState(() => _showAdminDashboard = false),
                ),
                _Tab(
                  label: 'Admin Dash',
                  selected: _showAdminDashboard,
                  onTap: () => setState(() => _showAdminDashboard = true),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _showAdminDashboard
                ? const _AdminDashboardContent()
                : const _UserDashboardContent(),
          ],
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Quick Menu',
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xfff1f1f1) : Colors.white,
          border: Border.all(color: const Color(0xffdddddd)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Color(0xff1d3557)),
        ),
      ),
    );
  }
}

class _UserDashboardContent extends StatelessWidget {
  const _UserDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: 'New Messages 114',
      lines: [
        '27-Aug-26 - from Employee Leaves to Approve',
        '27-Aug-26 - from Employee Leaves to Approve',
        '26-Aug-26 - from Priyavandhana_B from Sri Aurobindo Mira Universal School',
        '26-Aug-26 - from System from School',
        '26-Aug-26 - from Priyavandhana_B from Sri Aurobindo Mira Universal School',
        '26-Aug-26 - from Priyavandhana_B from Sri Aurobindo Mira Universal School',
        '26-Aug-26 - from JEWILLPAUL from Parent of JEWILLIN PAUL GIDEONS in 12 B Grade 12 B - 2026-27 (2026)',
        '25-Aug-26 - from Gurunagesh_S Teacher of 10 C Grade 10 C - 2026-27 (2026)',
        '24-Aug-26 - from imayavarman from Parent of IMAYAVARMAN.K in 1 B Grade 1 B - 2026-27 (2026)',
        '25-Aug-26 - from Priyavandhana_B from Sri Aurobindo Mira Universal School',
      ],
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: '6 Approve Student Leave',
          lines: [
            'SAMUNI-2026-11-B : 1',
            'SAMUNI-2026-09-C : 1',
            'SAMUNI-2026-UNI-Route-Z1 : 1',
            'SAMUNI-2026-4-A : 1',
            'SAMUNI-2026-12-C : 1',
            'SAMUNI-2026-Gr12_Special_Class&Tuition_Class-A : 1',
            '* Action Required Click here',
          ],
        ),
        SizedBox(height: 6),
        _Section(title: 'Admission Applications 27', lines: ['27']),
        SizedBox(height: 6),
        _Section(
          title: '1027 Request to Complete',
          lines: ['Clarification : 946', 'In Progress : 81'],
        ),
        SizedBox(height: 6),
        _Section(
          title: '242 Approve Employee Leave',
          lines: ['* Action Required Click here to approve requests'],
        ),
        SizedBox(height: 6),
        _TrendTable(),
        SizedBox(height: 8),
        Text(
          'Note: Above report is based on data as of yesterday night',
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: Color(0xff355c8a),
          ),
        ),
        SizedBox(height: 10),
        Center(
          child: Text(
            'Absence Trend',
            style: TextStyle(fontSize: 10, color: Color(0xff555555)),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xffeeeeee),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xff222222),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Text(
                      line,
                      style: const TextStyle(
                        fontSize: 8,
                        height: 1.35,
                        color: Color(0xff355c8a),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTable extends StatelessWidget {
  const _TrendTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['20260826', '86', '0', '0'],
      ['20260825', '781', '0', '0'],
      ['20260824', '781', '0', '0'],
      ['20260823', '85', '0', '0'],
      ['20260822', '133', '0', '0'],
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xffeeeeee),
            padding: const EdgeInsets.all(4),
            child: const Text(
              'Messages Trend',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const _TrendRow(
            values: ['Date', 'Msgs', 'SMS', 'Notifications'],
            header: true,
          ),
          ...rows.map((row) => _TrendRow(values: row)),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.values, this.header = false});

  final List<String> values;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header ? const Color(0xffe5e9ed) : const Color(0xfff5f5f5),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: values
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
