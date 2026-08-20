import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class OnlineAssessmentPage extends StatefulWidget {
  const OnlineAssessmentPage({super.key, required this.group});

  final Group group;

  @override
  State<OnlineAssessmentPage> createState() => _OnlineAssessmentPageState();
}

class _OnlineAssessmentPageState extends State<OnlineAssessmentPage> {
  int _selectedTab = 0;

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
          onPressed: () => Navigator.of(context).maybePop(),
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
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 27,
              child: Padding(
                padding: const EdgeInsets.only(left: 7, top: 7),
                child: Text(
                  '${widget.group.name} - ${widget.group.year} - Assessments, Quizzes',
                  style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            SizedBox(
              height: 31,
              child: Row(
                children: [
                  _Tab(label: 'List', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  _Tab(label: 'Chart', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                  _Tab(label: 'Folder', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                  _Tab(label: 'Analyse', selected: _selectedTab == 3, onTap: () => setState(() => _selectedTab = 3)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            const Expanded(
              child: Center(
                child: Text(
                  'No Data available',
                  style: TextStyle(fontSize: 10, color: Color(0xff222222)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: selected ? Border.all(color: const Color(0xffd9e2ec)) : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xff333333) : const Color(0xff0066cc))),
      ),
    );
  }
}
