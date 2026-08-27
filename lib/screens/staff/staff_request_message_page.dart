import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class StaffRequestMessagePage extends StatefulWidget {
  const StaffRequestMessagePage({super.key});

  @override
  State<StaffRequestMessagePage> createState() =>
      _StaffRequestMessagePageState();
}

class _StaffRequestMessagePageState extends State<StaffRequestMessagePage> {
  bool _includeCompleted = false;
  final _searchController = TextEditingController();

  static const _activeRequests = [
    _Request(
      '2026-08-27 - IH6C',
      'uniform default',
      'Other Created on Aug 27, 2026 7:45 AM',
      false,
    ),
    _Request(
      '2026-08-26 - D87UE',
      'Leave request',
      'Other Created on Aug 26, 2026 10:59 PM',
      false,
    ),
    _Request(
      '2026-08-25 - NW740',
      'Complaint Regarding AC Not Working Properly in School Bus',
      'Other Created on Aug 25, 2026 5:39 PM',
      false,
    ),
    _Request(
      '2026-08-25 - H1BM',
      'Type: Enroll Created on Aug 25, 2026 12:27 PM',
      '',
      false,
    ),
    _Request(
      '2026-08-25 - K3T76',
      'Type: Enroll Created on Aug 25, 2026 12:25 PM',
      '',
      false,
    ),
  ];

  static const _completedRequests = [
    _Request(
      '2026-08-25 - VRFU1',
      'I am suffering from severe throat pain and need to visit a doctor for a medical consultation. Therefore, I kindly request permission to leave school at 3:30 PM today.',
      'Other Created on Aug 25, 2026 8:07 AM',
      true,
    ),
    _Request(
      '2026-08-24 - 5ILS',
      'AC is not coming in bus',
      'Other Created on Aug 24, 2026 5:27 PM',
      true,
    ),
    _Request(
      '2026-08-24 - BAZ8L',
      'Type: Other Created on Aug 24, 2026 2:27 PM',
      '',
      true,
    ),
    _Request(
      '2026-08-24 - Q4Z5',
      'Type: Other Created on Aug 24, 2026 12:27 PM',
      '',
      true,
    ),
    _Request(
      '2026-08-24 - PMK2',
      'Regarding pondicherry trip',
      'Other Created on Aug 24, 2026 12:09 PM',
      true,
    ),
    _Request(
      '2026-08-24 - 3M9K2',
      'Regarding track pant instead of jeans',
      'Other Created on Aug 24, 2026 7:43 AM',
      true,
    ),
    _Request(
      '2026-08-21 - 6ZOAI',
      'Type: Other Created on Aug 21, 2026 12:36 PM',
      '',
      true,
    ),
    _Request(
      '2026-08-21 - KE3SJ',
      'Type: Other Created on Aug 21, 2026 9:50 AM',
      '',
      true,
    ),
    _Request(
      '2026-08-20 - 032G5',
      'Type: Other Created on Aug 20, 2026 7:24 PM',
      '',
      true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Request> get _requests => [
    ..._activeRequests,
    if (_includeCompleted) ..._completedRequests,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 7, 4, 0),
            child: Row(
              children: [
                const Text(
                  'Request List',
                  style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 24),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 10, color: Color(0xff087ff5)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffdddddd)),
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 7, 27, 3),
            child: Row(
              children: [
                SizedBox(
                  height: 18,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _includeCompleted = !_includeCompleted),
                    icon: Icon(
                      _includeCompleted
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      size: 9,
                    ),
                    label: Text(
                      _includeCompleted
                          ? 'Exclude Completed'
                          : 'Include Completed',
                      style: const TextStyle(fontSize: 8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a6b7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 18,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 8),
                      decoration: const InputDecoration(
                        hintText: 'Search Text...',
                        hintStyle: TextStyle(fontSize: 8),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _smallButton('Search', const Color(0xff16a6b7)),
                const SizedBox(width: 4),
                _smallButton('Reset', const Color(0xffed3b5a)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'St Dt: 2026-07-27',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.edit, size: 10, color: Color(0xff666666)),
                SizedBox(width: 19),
                Text(
                  'En Dt: 2026-08-27',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.edit, size: 10, color: Color(0xff666666)),
              ],
            ),
          ),
          if (_includeCompleted)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 3, bottom: 2),
                child: Text('< Page 1 of 9 >', style: TextStyle(fontSize: 9)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [_tableHeader(), ..._requests.map(_requestRow)],
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

  Widget _smallButton(String label, Color color) => SizedBox(
    height: 18,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 7)),
    ),
  );

  Widget _tableHeader() => Container(
    height: 18,
    color: const Color(0xffe5e9ed),
    child: const Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 3),
            child: Text('Request', style: TextStyle(fontSize: 8)),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text('Status', style: TextStyle(fontSize: 8)),
        ),
      ],
    ),
  );

  Widget _requestRow(_Request request) => Container(
    constraints: const BoxConstraints(minHeight: 33),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffe1e1e1))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
            child: Text(
              '${request.code}\n${request.description}${request.created.isEmpty ? '' : '\n${request.created}'}',
              style: const TextStyle(
                fontSize: 7,
                height: 1.2,
                color: Color(0xff355c8a),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: request.completed
                      ? const Color(0xff078b21)
                      : const Color(0xffffa500),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 17,
                color: const Color(0xff16a6b7),
                child: const Icon(
                  Icons.chevron_right,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Request {
  const _Request(this.code, this.description, this.created, this.completed);

  final String code;
  final String description;
  final String created;
  final bool completed;
}
