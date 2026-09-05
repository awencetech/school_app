import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentPtmPage extends StatelessWidget {
  const StudentPtmPage({super.key});

  static const _meetings = [
    _Ptm(
      'SCHOOL SUPPLIES STALL 2026-27 - STALL ID - I',
      '07-Apr-26',
      '08-Apr-26',
    ),
    _Ptm(
      'Finnish Team - On Site Visit - “OPPI Connect: A Journey of Learning”',
      '15-Apr-26',
      '16-Apr-26',
    ),
    _Ptm('Graduation Day Gr 5 & 8', '24-Apr-26', '24-Apr-26'),
    _Ptm('Graduation Day UKG & Gr 3', '25-Apr-26', '25-Apr-26'),
    _Ptm(
      'AUROBIVE SUMMER CAMP 2026 _ VALEDICTORY CEREMONY',
      '15-May-26',
      '16-May-26',
    ),
    _Ptm('POP 3 - SS STALL -01.06.2026', '01-Jun-26', '02-Jun-26'),
    _Ptm('POP 4 - SS STALL -01.06.2026', '01-Jun-26', '02-Jun-26'),
    _Ptm('Parent Orientation Program 5', '13-Jun-26', '13-Jun-26'),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(3, 8, 3, 6),
            child: Text(
              'PTM List',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(3, 6, 3, 7),
            child: Text(
              'Update records for a PTM',
              style: TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: Color(0xff1d3557),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _meetings.length,
              itemBuilder: (context, index) =>
                  _PtmCard(meeting: _meetings[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _PtmCard extends StatelessWidget {
  const _PtmCard({required this.meeting});

  final _Ptm meeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd2d2d2)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meeting.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xff222222)),
          ),
          Text(
            'Start Dt: ${meeting.start}\nEnd Dt: ${meeting.end}\nStatus: Shown',
            style: const TextStyle(
              fontSize: 7,
              height: 1.2,
              color: Color(0xff355c8a),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    size: 10,
                    color: Color(0xff777777),
                  ),
                  Text(
                    ' Select',
                    style: TextStyle(fontSize: 8, color: Color(0xff777777)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ptm {
  const _Ptm(this.title, this.start, this.end);

  final String title;
  final String start;
  final String end;
}
