import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentMedicalPage extends StatefulWidget {
  const StudentMedicalPage({super.key});

  @override
  State<StudentMedicalPage> createState() => _StudentMedicalPageState();
}

class _StudentMedicalPageState extends State<StudentMedicalPage> {
  int _selectedTab = 0;

  static const _testRecords = [
    _TestRecord(
      date: '2026-08-26',
      height: 'N/A',
      weight: 'N/A',
      bmi: 'N/A',
      vision: '(L): (R):',
      dental: '',
      allergy: '',
      doctorNote: 'Eye Camp Conducted by Agarwal\'s Eye Hospital on 08.08.2026, the report has been loaded for your reference.',
      ophthalmologyReport: 'Ophthalmology Report-Mohamed Azeemsha A-08.08.2026.pdf',
    ),
    _TestRecord(
      date: '2025-11-25',
      height: 'N/A',
      weight: 'N/A',
      bmi: 'N/A',
      vision: '(L): (R):',
      dental: '',
      allergy: '',
      doctorNote: 'Testing report loaded for your reference.',
      ophthalmologyReport: 'Ophthalmology Report-Mohamed Azeemsha A-31.07.2025.pdf',
    ),
    _TestRecord(
      date: '2024-04-24',
      height: '145 cm',
      weight: '43.4 kg',
      bmi: 'N/A',
      vision: '(L): (R):',
      dental: '',
      allergy: '',
      doctorNote: '',
      ophthalmologyReport: '',
    ),
  ];

  static const _eventRecords = [
    _EventRecord(
      date: '2026-06-06',
      className: '10-C(2026)',
      description: 'Headache',
      symptoms: 'Head',
      specialNeeds: '',
      doctorNote: '',
    ),
    _EventRecord(
      date: '2025-11-25',
      className: '10-C(2026)',
      description: 'Fever',
      symptoms: 'High fever',
      specialNeeds: '',
      doctorNote: '',
    ),
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
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              'Medical',
              style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text(
              'For MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd9d9d9)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentMedicalSummaryPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  foregroundColor: const Color(0xff1d3557),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Medical Information ....',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd8d8d8)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: _selectedTab == 0
                          ? const Color(0xfff5f5f5)
                          : Colors.white,
                      alignment: Alignment.center,
                      child: const Text(
                        'Events',
                        style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: _selectedTab == 1
                          ? const Color(0xfff5f5f5)
                          : Colors.white,
                      alignment: Alignment.center,
                      child: const Text(
                        'Tests',
                        style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedTab == 0 ? _buildEventsView() : _buildTestsView(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildEventsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      children: [
        const Text(
          'Medical Events',
          style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
        ),
        const SizedBox(height: 8),
        ..._eventRecords.map((event) => _EventCard(event: event)),
      ],
    );
  }

  Widget _buildTestsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      children: [
        const Text(
          'Medical Test Info - Latest 5',
          style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
        ),
        const SizedBox(height: 8),
        ..._testRecords.map((record) => _TestCard(record: record)),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final _EventRecord event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd9d9d9)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported Date: ${event.date}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Class: ${event.className}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Description: ${event.description}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Symptoms Reported: ${event.symptoms}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Special Needs known: ${event.specialNeeds.isNotEmpty ? event.specialNeeds : 'N/A'}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.record});

  final _TestRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd9d9d9)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observation Date : ${record.date}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Height (cm) : ${record.height}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'Weight (kg) : ${record.weight}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'BMI (approx) : ${record.bmi}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'Vision (L) : (R): ${record.vision}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'Dental hygiene : ${record.dental}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'Allergy / Other Health condition : ${record.allergy}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          if (record.doctorNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Doctor\'s note : ${record.doctorNote}',
              style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
          ],
          if (record.ophthalmologyReport.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.ophthalmologyReport,
                    style: const TextStyle(fontSize: 9, color: Color(0xff1d3557)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class StudentMedicalSummaryPage extends StatelessWidget {
  const StudentMedicalSummaryPage({super.key});

  static const _summaryItems = [
    _SummaryItem(
      date: '2026-08-08',
      dental: 'Dental:',
      allergy: 'Allergy:',
      doctorNote: 'Eye Camp Conducted by Agarwal\'s Eye Hospital on 08.08.2026, the report has been loaded for your reference.',
      reportName: 'Ophthalmology Report-Mohamed Azeemsha A-08.08.2026.pdf',
    ),
    _SummaryItem(
      date: '2025-07-31',
      dental: 'Dental:',
      allergy: 'Allergy:',
      doctorNote: 'Eye Camp Conducted by Agarwal\'s Eye Hospital on 31.07.2025, the report has been loaded for your reference.',
      reportName: 'Ophthalmology Report-Mohamed Azeemsha A-31.07.2025.pdf',
    ),
    _SummaryItem(
      date: '2024-04-22',
      dental: 'Dental:',
      allergy: 'Allergy:',
      doctorNote: '',
      reportName: '',
    ),
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
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              'Summary of Medical Records',
              style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              children: [
                ..._summaryItems.map((item) => _SummaryCard(item: item)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd9d9d9)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observation Date: ${item.date}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          const SizedBox(height: 4),
          Text(
            'Dental: ${item.dental}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          Text(
            'Allergy: ${item.allergy}',
            style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
          ),
          if (item.doctorNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Doctor\'s note: ${item.doctorNote}',
              style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
          ],
          if (item.reportName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.reportName,
                    style: const TextStyle(fontSize: 9, color: Color(0xff1d3557)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TestRecord {
  const _TestRecord({
    required this.date,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.vision,
    required this.dental,
    required this.allergy,
    required this.doctorNote,
    required this.ophthalmologyReport,
  });

  final String date;
  final String height;
  final String weight;
  final String bmi;
  final String vision;
  final String dental;
  final String allergy;
  final String doctorNote;
  final String ophthalmologyReport;
}

class _EventRecord {
  const _EventRecord({
    required this.date,
    required this.className,
    required this.description,
    required this.symptoms,
    required this.specialNeeds,
    required this.doctorNote,
  });

  final String date;
  final String className;
  final String description;
  final String symptoms;
  final String specialNeeds;
  final String doctorNote;
}

class _SummaryItem {
  const _SummaryItem({
    required this.date,
    required this.dental,
    required this.allergy,
    required this.doctorNote,
    required this.reportName,
  });

  final String date;
  final String dental;
  final String allergy;
  final String doctorNote;
  final String reportName;
}
