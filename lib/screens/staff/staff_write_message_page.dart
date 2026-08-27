import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class StaffWriteMessagePage extends StatelessWidget {
  const StaffWriteMessagePage({super.key});

  static const _userGroups = [
    _MessageGroup(
      'UNI Route Z1',
      'UNI Route Z1\n2025(2025)',
      'MOHAMED TAJDEEHEN R in UNI Route Z1 2025(2025)',
    ),
  ];

  static const _studentGroups = [
    _MessageGroup(
      '10 C Grade 10 C',
      '10 C Grade 10 C -\n2026-27 (2026)',
      'MOHAMED AZEEMSHA A in 10 C Grade 10 C - 2026-27 (2026)',
    ),
    _MessageGroup(
      'UNI-Route Z2',
      'UNI-Route Z2\nUN Route 2026-27',
      'Parent of MOHAMED AZEEMSHA A in UNI-Route-Z2 UNI Route Z2 2026(2026)',
    ),
    _MessageGroup(
      'SP7 UNI - Route',
      'SP7 UNI - Route\nS7 - 2025(2026)',
      'MOHAMED AZEEMSHA A in SP7 UNI - Route SP7 - 2025(2026)',
    ),
  ];

  void _selectGroup(BuildContext context, _MessageGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _StaffMessageComposePage(group: group)),
    );
  }

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
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 17, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Write Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff444444),
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
                  const SizedBox(height: 5),
                  const Text(
                    'First Select a group or class to Write a Message',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groups/Classes of MOHAMED TAJDEEHEN R',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 4),
                  _GroupRow(
                    groups: _userGroups,
                    onTap: (group) => _selectGroup(context, group),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groups/Classes of Student MOHAMED AZEEMSHA A',
                    style: TextStyle(fontSize: 11, color: Color(0xff444444)),
                  ),
                  const SizedBox(height: 4),
                  _GroupRow(
                    groups: _studentGroups,
                    onTap: (group) => _selectGroup(context, group),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _MessageGroup {
  const _MessageGroup(this.title, this.subtitle, this.messageHeading);

  final String title;
  final String subtitle;
  final String messageHeading;
}

class _StaffMessageComposePage extends StatefulWidget {
  const _StaffMessageComposePage({required this.group});

  final _MessageGroup group;

  @override
  State<_StaffMessageComposePage> createState() =>
      _StaffMessageComposePageState();
}

class _StaffMessageComposePageState extends State<_StaffMessageComposePage> {
  String _selectedMessageType = '(Select One)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
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
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Write Message',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 9),
            Text(
              widget.group.messageHeading,
              style: const TextStyle(fontSize: 11, height: 1.25),
            ),
            const Text(
              'Message for',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedMessageType,
              isExpanded: true,
              iconSize: 15,
              style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  borderSide: BorderSide(color: Color(0xffcccccc)),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: '(Select One)',
                  child: Text('(Select One)'),
                ),
                DropdownMenuItem(value: 'School', child: Text('School')),
                DropdownMenuItem(value: 'Class/es', child: Text('Class/es')),
                DropdownMenuItem(value: 'Teacher/s', child: Text('Teacher/s')),
                DropdownMenuItem(value: 'Student/s', child: Text('Student/s')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMessageType = value);
                }
              },
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 19,
                width: 29,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xff087ff5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text('Send', style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
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

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.groups, required this.onTap});

  final List<_MessageGroup> groups;
  final ValueChanged<_MessageGroup> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups
          .map(
            (group) => SizedBox(
              width: 72,
              child: InkWell(
                onTap: () => onTap(group),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.directions_bus_filled,
                        size: 28,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7,
                          height: 1.15,
                          color: Color(0xff777777),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
