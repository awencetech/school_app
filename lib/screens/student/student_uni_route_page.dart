// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentUniRoutePage extends StatefulWidget {
  const StudentUniRoutePage({super.key, this.routeName = 'UNI-Route-Z2'});

  final String routeName;

  @override
  State<StudentUniRoutePage> createState() => _StudentUniRoutePageState();
}

class _StudentUniRoutePageState extends State<StudentUniRoutePage> {
  bool _showRoutes = false;

  static const _passengers = [
    ['MOHAMED RILWAN A (S2129)', '8 A'],
    ['S.G.KAAVIYAN (S2197)', '5 B'],
    ['Sushanth Leo (S2384)', ''],
    ['SAESHA.V (S1013)', '7 A'],
    ['SADEEP.S (S1111)', '7 C'],
    ['SANJANA.G.S (S1194)', '9 C'],
    ['VJESSICA ALICE (S31)', '10 B'],
    ['VIKRAM SALM(S393)', '9 B'],
    ['DHANUSH.V.V (S40)', '10 C'],
    ['A.P.SRINAYA (S422)', '9 C'],
    ['S.JAYASHENA (S578)', '10 B'],
    ['KSHIRAJA K (S5865)', '9 I'],
    ['KRISHIKA M.K (S882)', '7 A'],
    ['DHARSHAN D (S890)', '10 B'],
    ['ADHVIK M (S1685)', '5 B'],
    ['MOHAMED AZEEMSHA A (S1746)', '10 C'],
    ['Deshna B (S1827)', '6 I'],
    ['Pujithika Kali (S2387)', '6 I'],
    ['DEEPAK SARAN (S2399)', '6 C'],
    ['THIRUKUMARAN MS(S1024)', '11 A'],
    ['HARICHANDRAKKS.S(S11)', '10 A'],
    ['PIYUSH GAUR R(S1154)', '11 B'],
    ['SANJAY NACHIAPPAN M(S1191)', '10 C'],
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
          onPressed: () => navigateBack(context),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, 7, 4, 4),
              child: Text(
                '${widget.routeName} Track the Vehicle',
                style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showRoutes) _routeDetails() else _passengerList(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: Row(
                      children: [
                        _tab(
                          'Routes',
                          true,
                          () => setState(() => _showRoutes = true),
                        ),
                        _tab(
                          'Details',
                          false,
                          () => setState(() => _showRoutes = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _routeDetails() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information about UNI Route Z2 2026 (SAMUNI-2026-UNI-Route-Z2)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 18),
          Text(
            '🚌 Z Series — Direct Shuttle Routes — Transport',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14),
          Text(
            'Usage Guidelines',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            '1. Route Nature:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0xffffc77d),
            ),
          ),
          Text(
            '   Z Series routes are dedicated Shuttle services operating directly from Nehru Nagar Campus to Universal Campus, with no intermediate stops.',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            '2. ⏰ Departure & Travel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0xffffc77d),
            ),
          ),
          Text(
            '   • The bus departs sharply at 8:10 AM from Nehru Nagar Campus\n   • No waiting or delay will be permitted under any circumstances\n   • No stops will be made once the vehicle departs\n   • Travel time is optimized for the route',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            '8. 🛡 Supervision & Safety',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0xffffc77d),
            ),
          ),
          Text(
            '   • Each Z Series bus will be managed by assigned Chaperones\n   • Chaperones are responsible for:\n      o Student discipline\n      o Safe boarding and deboarding\n      o Attendance monitoring',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            '9. ⚠ Strict Compliance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0xffffc77d),
            ),
          ),
          Text(
            '   • Z Series is a regulated, time-bound ferry service\n   • Any deviation, request for stoppage, or misuse will not be entertained',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            '10. 📞 Support Contact:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              backgroundColor: Color(0xffffc77d),
            ),
          ),
          Text(
            '   a. Chaperone ( Z2 Route ) - Call Transport Officer 1\n   b. Transport Officer 2 - Call Transport Officer 2\n   c. Admin Manager - Call Admin Manager\n   d. Dean - Call Dean',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _passengerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Text(
            'Bus passengers Working date is 2026-08-27',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          color: const Color(0xffe5e9ed),
          padding: const EdgeInsets.all(4),
          child: const Text('Student List', style: TextStyle(fontSize: 8)),
        ),
        ..._passengers.map(
          (passenger) => _passengerRow(passenger[0], passenger[1]),
        ),
      ],
    );
  }

  Widget _passengerRow(String name, String className) {
    return Container(
      height: 25,
      decoration: const BoxDecoration(
        color: Color(0xfff3f3f3),
        border: Border(bottom: BorderSide(color: Color(0xffd8dde1))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Color(0xffffa500),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 7, color: Color(0xff355c8a)),
            ),
          ),
          SizedBox(
            width: 105,
            child: Row(
              children: [
                _actionButton('Pick', () => _showPickupDialog(name)),
                const SizedBox(width: 3),
                _actionButton('Drop', () => _showDropDialog(name)),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(className, style: const TextStyle(fontSize: 7)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed) => SizedBox(
    height: 18,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        side: const BorderSide(color: Color(0xff00a4d6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 7, color: Color(0xff008dcc)),
      ),
    ),
  );

  Widget _tab(String label, bool selected, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      backgroundColor: selected ? Colors.white : const Color(0xfff5f7f9),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: Size.zero,
      side: const BorderSide(color: Color(0xffdddddd)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 9, color: Color(0xff087ff5)),
    ),
  );

  Future<void> _showPickupDialog(String name) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PickupDialog(name: name),
    );
  }

  Future<void> _showDropDialog(String name) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DropDialog(name: name),
    );
  }
}

class _PickupDialog extends StatelessWidget {
  const _PickupDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pickup/Drop Register', style: TextStyle(fontSize: 13)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('For $name', style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 12),
        const Text('Wearing Mask', style: TextStyle(fontSize: 10)),
        const Row(
          children: [
            Radio(value: true, groupValue: true, onChanged: null),
            Text('Yes', style: TextStyle(fontSize: 9)),
            Radio(value: false, groupValue: true, onChanged: null),
            Text('No', style: TextStyle(fontSize: 9)),
          ],
        ),
        const Text('Temperature', style: TextStyle(fontSize: 10)),
        const TextField(
          decoration: InputDecoration(
            hintText: '98.2',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Feeling Healthy no visible sign of illness',
          style: TextStyle(fontSize: 10),
        ),
        const Row(
          children: [
            Radio(value: true, groupValue: true, onChanged: null),
            Text('Yes', style: TextStyle(fontSize: 9)),
            Radio(value: false, groupValue: true, onChanged: null),
            Text('No', style: TextStyle(fontSize: 9)),
          ],
        ),
        const Text('Comments', style: TextStyle(fontSize: 10)),
        const TextField(
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Record Pickup', style: TextStyle(fontSize: 9)),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close', style: TextStyle(fontSize: 9)),
      ),
    ],
  );
}

class _DropDialog extends StatelessWidget {
  const _DropDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pickup/Drop Register', style: TextStyle(fontSize: 13)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$name Picked Up By', style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: 'Select person who picked',
          items: const [
            DropdownMenuItem(
              value: 'Select person who picked',
              child: Text('Select person who picked'),
            ),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Person who Picked if Other or Relative',
          style: TextStyle(fontSize: 10),
        ),
        const TextField(
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'List of people who can pick the student',
          style: TextStyle(fontSize: 9),
        ),
        const Text('---None defined---', style: TextStyle(fontSize: 9)),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Record Drop', style: TextStyle(fontSize: 9)),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close', style: TextStyle(fontSize: 9)),
      ),
    ],
  );
}
