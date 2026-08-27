import 'package:flutter/material.dart';

import '../../widgets/staff_footer.dart';

class StaffMeetingPage extends StatelessWidget {
  const StaffMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MeetingAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 29,
            child: Padding(
              padding: EdgeInsets.only(left: 2, top: 8),
              child: Text('Meetings Info', style: TextStyle(fontSize: 11)),
            ),
          ),
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 3, top: 6),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MeetingInfoHistoryPage(),
                  ),
                ),
                icon: const Icon(Icons.note_alt_outlined, size: 9),
                label: const Text(
                  'View Meeting Notes',
                  style: TextStyle(fontSize: 7),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff008dcc),
                  side: const BorderSide(color: Color(0xff00a4d6)),
                  minimumSize: const Size(79, 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class MeetingInfoHistoryPage extends StatelessWidget {
  const MeetingInfoHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MeetingAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 45,
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Meeting Info History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.only(right: 12),
                  constraints: const BoxConstraints.tightFor(width: 30),
                  icon: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 28, top: 14),
            child: Text(
              'Name: MOHAMED TAJ DHEEN R (Id:SAMNTS56)',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _MeetingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MeetingAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 39,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
      title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(39);
}
