import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class OnlineAssignmentPage extends StatefulWidget {
  const OnlineAssignmentPage({super.key, required this.group});

  final Group group;

  @override
  State<OnlineAssignmentPage> createState() => _OnlineAssignmentPageState();
}

class _OnlineAssignmentPageState extends State<OnlineAssignmentPage> {
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.group.name} - ${widget.group.year} - Homework, Assignments',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff1d3557),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(27, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xff0066cc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            SizedBox(
              height: 31,
              child: Row(
                children: [
                  _Tab(
                    label: 'List',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _Tab(
                    label: 'Chart',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                  _Tab(
                    label: 'Folder',
                    selected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                  _Tab(
                    label: 'Analyse',
                    selected: _selectedTab == 3,
                    onTap: () => setState(() => _selectedTab = 3),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _listTab(),
                  _chartTab(),
                  _folderTab(),
                  _analyseTab(),
                ],
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

  Widget _listTab() => const Center(
    child: Text(
      'No Data available',
      style: TextStyle(fontSize: 10, color: Color(0xff222222)),
    ),
  );

  Widget _chartTab() => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 1, top: 8),
      child: Row(
        children: [
          const Text(
            'Skyline View',
            style: TextStyle(fontSize: 10, color: Color(0xff222222)),
          ),
          const SizedBox(width: 8),
          _smallAction(Icons.refresh, 'Refresh'),
        ],
      ),
    ),
  );

  Widget _folderTab() => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 1, top: 8),
      child: Row(
        children: [
          const Text(
            'List of Resources',
            style: TextStyle(fontSize: 10, color: Color(0xff222222)),
          ),
          const SizedBox(width: 8),
          _smallAction(Icons.refresh, ''),
        ],
      ),
    ),
  );

  Widget _analyseTab() => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 1, top: 10),
      child: Row(
        children: [
          const Text(
            'Report from Date:',
            style: TextStyle(fontSize: 9, color: Color(0xff222222)),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 96,
            height: 19,
            child: TextField(
              controller: TextEditingController(text: '2026-07-22'),
              style: const TextStyle(fontSize: 8),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 3),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _smallAction(null, 'Run Report'),
          const SizedBox(width: 4),
          _smallAction(Icons.upload, ''),
        ],
      ),
    ),
  );

  Widget _smallAction(IconData? icon, String label) => SizedBox(
    height: 19,
    child: OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xff00a0df)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: icon == null
          ? Text(
              label,
              style: const TextStyle(fontSize: 7, color: Color(0xff008ad8)),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: const Color(0xff008ad8)),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Color(0xff008ad8),
                    ),
                  ),
              ],
            ),
    ),
  );
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: selected ? const Color(0xff333333) : const Color(0xff0066cc),
          ),
        ),
      ),
    );
  }
}
