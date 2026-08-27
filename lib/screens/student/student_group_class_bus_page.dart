import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentGroupClassBusPage extends StatelessWidget {
  const StudentGroupClassBusPage({super.key});

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
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Groups/Classes of MOHAMED TAJDEEHEN R',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(
                    Icons.close,
                    size: 19,
                    color: Color(0xff333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Groups/Classes of Student MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 11, color: Color(0xff444444)),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.studentMoreOptions),
              child: const SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_bus_filled,
                      size: 28,
                      color: Colors.black,
                    ),
                    SizedBox(height: 3),
                    Text(
                      '10 C Grade 10 C -\n2026-27 (2026)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7,
                        height: 1.15,
                        color: Color(0xff777777),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
