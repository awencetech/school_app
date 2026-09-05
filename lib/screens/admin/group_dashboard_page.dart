import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupDashboardPage extends StatelessWidget {
  const GroupDashboardPage({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text(
          'Today in Class',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dashboard for ${group.name} for Today', style: const TextStyle(fontSize: 11, color: Color(0xff1d3557))),
              const SizedBox(height: 7),
              const _DashboardPanel(
                title: 'Student/s applied for Leave Today',
                lines: ['Nobody on leave'],
              ),
              const SizedBox(height: 7),
              const _DashboardPanel(
                title: 'Student Count',
                lines: ['Total: 17', 'Male:4 Female:13'],
              ),
              const SizedBox(height: 7),
              const _DashboardPanel(
                title: "HW/Today's Update Status",
                lines: ['None so far'],
              ),
              const SizedBox(height: 7),
              const _DashboardPanel(
                title: 'Attendance Status',
                lines: ['None Taken today'],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.only(left: 4, top: 5),
            color: const Color(0xffeeeeee),
            child: Text(title, style: const TextStyle(fontSize: 10, color: Color(0xff222222))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map((line) => Text(line, style: const TextStyle(fontSize: 8, height: 1.15, color: Color(0xff355c8a))))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
