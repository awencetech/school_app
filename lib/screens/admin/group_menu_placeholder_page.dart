import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupMenuPlaceholderPage extends StatelessWidget {
  const GroupMenuPlaceholderPage({
    super.key,
    required this.title,
    required this.group,
  });

  final String title;
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 46,
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Color(0xff34395f)),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}
