import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassFeeDetailsPage extends StatelessWidget {
  const ClassFeeDetailsPage({super.key, required this.group});

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
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 3, 6),
              child: Text(
                '${group.name} - ${group.year} - Fee Status for the Class',
                style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            const Padding(
              padding: EdgeInsets.fromLTRB(3, 7, 3, 0),
              child: Text(
                'Studentwise Fee Status for the Current Academic Year for the Class ......',
                style: TextStyle(
                  fontSize: 8,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff333333),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Fee Management Report - Classwise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff222222),
                    ),
                  ),
                  Text(
                    'School ID: ${group.name}',
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                  ),
                  const Text(
                    'As of Date: Mon Aug 24 2026 15:29:42 GMT+0530\n(India Standard Time)',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                  Text(
                    'Year: ${group.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.only(left: 25),
              child: Text(
                'Detail Report Classwise',
                style: TextStyle(fontSize: 11, color: Color(0xff222222)),
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
