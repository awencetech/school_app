import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentFeeInformationPage extends StatefulWidget {
  const StudentFeeInformationPage({super.key});

  @override
  State<StudentFeeInformationPage> createState() => _StudentFeeInformationPageState();
}

class _StudentFeeInformationPageState extends State<StudentFeeInformationPage> {
  final List<_FeeYear> _years = const [
    _FeeYear(
      year: '2021',
      outstanding: '61000',
      selected: false,
    ),
    _FeeYear(
      year: '2022',
      outstanding: '0',
      selected: true,
    ),
    _FeeYear(
      year: '2023',
      outstanding: '0',
      selected: false,
    ),
    _FeeYear(
      year: '2024',
      outstanding: '0',
      selected: false,
    ),
    _FeeYear(
      year: '2025',
      outstanding: '50000',
      selected: false,
    ),
    _FeeYear(
      year: '2026',
      outstanding: '0',
      selected: false,
    ),
  ];

  int? _selectedYearIndex;

  @override
  void initState() {
    super.initState();
    _selectedYearIndex = _years.indexWhere((year) => year.selected);
  }

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
              'Fee',
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
          Divider(height: 1, color: Colors.grey.shade300),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: _years.length,
              itemBuilder: (context, index) {
                final item = _years[index];
                final selected = index == _selectedYearIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? const Color(0xffc9d8ff)
                          : const Color(0xffd5d5d5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: selected ? const Color(0xfff5f9ff) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Details for Year:${item.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff222222),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Outstanding: ${item.outstanding}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedYearIndex = index;
                            });
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentFeeDetailPage(
                                  year: item.year,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xff3b82f6)
                                  : const Color(0xff7a7a7a),
                            ),
                            foregroundColor: selected
                                ? const Color(0xff2563eb)
                                : const Color(0xff666666),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Select'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
      floatingActionButton: null,
    );
  }
}

class _FeeYear {
  const _FeeYear({
    required this.year,
    required this.outstanding,
    required this.selected,
  });

  final String year;
  final String outstanding;
  final bool selected;
}

class StudentFeeDetailPage extends StatelessWidget {
  const StudentFeeDetailPage({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    const rows = [
      _FeeRow(
        item: 'SAMUNI: 2021 5 B',
        total: '32000',
        due: '30000',
        status: 'To be Paid',
      ),
      _FeeRow(
        item: 'SAMUNI: 2021 5 B',
        total: '15500',
        due: '15500',
        status: 'To be Paid',
      ),
      _FeeRow(
        item: 'SAMUNI: 2021 5 B',
        total: '15500',
        due: '15500',
        status: 'To be Paid',
      ),
    ];

    final totalDue = rows.fold<int>(
      0,
      (sum, row) => sum + int.parse(row.due.replaceAll(RegExp(r'[^0-9]'), '')),
    );

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
              'Fee Detail',
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
            child: Text(
              'Year: $year',
              style: const TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Total Fee to be Paid for the year: $totalDue',
              style: const TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Total Fee Outstanding: 61000',
              style: const TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Fee Updated on: 14-Mar-22',
              style: TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Text(
              'Fee paid as of Date: 2000',
              style: TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Last Payment: 02-Jun-21',
              style: TextStyle(fontSize: 11, color: Color(0xff333333)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.8),
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(1.1),
                    3: FlexColumnWidth(0.9),
                  },
                  border: TableBorder.all(color: const Color(0xffd6d6d6)),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xfff2f2f2)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Item',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Total to Pay',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Outstanding',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Status',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    ...rows.map((row) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                row.item,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                row.total,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                row.due,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox(
                                height: 24,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff1b8dff),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pay',
                                    style: TextStyle(fontSize: 9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xfff5f5f5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1b8dff),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Pay now (You selected 0 Items to pay and the amount is 0)',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => navigateBack(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff666666),
                    side: const BorderSide(color: Color(0xffbdbdbd)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Clear - To pay list',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _FeeRow {
  const _FeeRow({
    required this.item,
    required this.total,
    required this.due,
    required this.status,
  });

  final String item;
  final String total;
  final String due;
  final String status;
}
