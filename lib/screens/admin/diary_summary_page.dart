import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class DiarySummaryPage extends StatefulWidget {
  const DiarySummaryPage({super.key, required this.group});

  final Group group;

  @override
  State<DiarySummaryPage> createState() => _DiarySummaryPageState();
}

class _DiarySummaryPageState extends State<DiarySummaryPage> {
  static const _students = [
    ['S1197', 'SADAF FATHIMA.I'],
    ['S1289', 'MIRASHI SINGH.J'],
    ['S1319', 'VEDARSH VISAKA MOORTHY T N'],
    ['S1346', 'VAISHAVI K M'],
    ['S1378', 'Aashish Kumar M'],
    ['S1388', 'HARIPRAKASH M I'],
    ['S270', 'SURIYA VISWANATHAN K'],
    ['S875', 'SHRIDHARSHINI M'],
    ['S1654', 'HARINI N'],
    ['S1618', 'VAHINI K R'],
    ['S1670', 'SANOFAR A'],
    ['S1765', 'DWARAGA S'],
    ['S1288', 'MITHUSHI SINGH J'],
    ['S1288', 'MITHUSHI SINGH J'],
    ['S1662', 'INEIYAA V.S'],
    ['S1726', 'SAHANA SRI G'],
    ['S1603', 'RICHIKKA R'],
  ];

  int _tab = 0;
  DateTime _date = DateTime(2026, 8, 21);

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  String get _dateText =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 32,
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 17, color: Colors.white),
        ),
        title: const Text(
          'Class Students Diary',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _dateToolbar(),
            _tabs(),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _parentTab(),
                  _subjectTab(),
                  _teacherTab(),
                  _scoreTab(),
                ],
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

  Widget _dateToolbar() => SizedBox(
    height: 30,
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, right: 7),
          child: Text('Diary on:', style: TextStyle(fontSize: 9)),
        ),
        _smallButton(
          Icons.chevron_left,
          () => setState(() => _date = _date.subtract(const Duration(days: 1))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_dateText, style: const TextStyle(fontSize: 9)),
        ),
        _smallButton(
          Icons.chevron_right,
          () => setState(() => _date = _date.add(const Duration(days: 1))),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 19,
          child: OutlinedButton(
            onPressed: _chooseDate,
            style: _outlineButtonStyle,
            child: const Text('Change Date', style: TextStyle(fontSize: 7)),
          ),
        ),
      ],
    ),
  );

  Widget _smallButton(IconData icon, VoidCallback onPressed) => SizedBox(
    width: 20,
    height: 19,
    child: OutlinedButton(
      onPressed: onPressed,
      style: _outlineButtonStyle,
      child: Icon(icon, size: 13, color: const Color(0xff008ad8)),
    ),
  );

  Widget _tabs() => SizedBox(
    height: 28,
    child: Row(
      children: [
        _tabButton('Student/parent', 0),
        _tabButton('Subject', 1),
        _tabButton('Teacher', 2),
        _tabButton('GK Score', 3),
      ],
    ),
  );

  Widget _tabButton(String label, int index) => Expanded(
    child: TextButton(
      onPressed: () => setState(() => _tab = index),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: const Color(0xff0066cc),
        backgroundColor: _tab == index ? const Color(0xfff5f7f9) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9)),
    ),
  );

  Widget _parentTab() => Column(
    children: [
      _tableHeader(
        ['Id', 'Name', 'Parent', 'Student', 'Overview'],
        const [38, 150, 48, 52, 55],
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (_, index) => _parentRow(_students[index]),
        ),
      ),
    ],
  );

  Widget _parentRow(List<String> student) => _row([
    _cell(student[0], 38),
    _cell(student[1], 150),
    _dotCell(48),
    _dotCell(52),
    SizedBox(
      width: 55,
      height: 20,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: const Center(
          child: Icon(Icons.visibility, size: 12, color: Colors.blue),
        ),
      ),
    ),
  ]);

  Widget _subjectTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 1, top: 5),
        child: Row(
          children: [
            _selectBox('Select One', 61),
            const SizedBox(width: 4),
            _blueButton('Insert data'),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'List of Subjects Data entered :',
          style: TextStyle(fontSize: 10, color: Color(0xff333333)),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          'Data for Subject : Not yet selected',
          style: TextStyle(fontSize: 10, color: Color(0xff333333)),
        ),
      ),
      _tableHeader(
        [
          'Id-Name',
          'Completion of Due Assignment',
          'Performance in Class Today',
          'Note',
        ],
        const [70, 110, 135, 45],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 5, left: 1),
        child: _blueButton('Submit'),
      ),
    ],
  );

  Widget _teacherTab() => Column(
    children: [
      _tableHeader(
        ['Id-Name', 'Discipline', 'Food', ''],
        const [75, 110, 110, 30],
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (_, index) => _teacherRow(_students[index]),
        ),
      ),
    ],
  );

  Widget _teacherRow(List<String> student) => _row([
    _cell('${student[0]}-${student[1]}', 75),
    _diaryFields('Punctuality:', ['On time', 'Smart today'], 110),
    _diaryFields('Healthy:', ['Excellent', 'Excellent', 'Yes'], 110),
    const SizedBox(width: 30),
  ], height: 84);

  Widget _scoreTab() => Column(
    children: [
      _tableHeader(['Id-Name', 'Score'], const [165, 135]),
      Expanded(
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (_, index) => _row([
            _cell('${_students[index][0]}-${_students[index][1]}', 165),
            SizedBox(
              width: 135,
              height: 25,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: TextField(
                  style: const TextStyle(fontSize: 9),
                  decoration: _decoration(),
                ),
              ),
            ),
          ]),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 5),
          child: _blueButton('Submit'),
        ),
      ),
    ],
  );

  Widget _diaryFields(String label, List<String> values, double width) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 8)),
              ...values.map(
                (value) => SizedBox(
                  height: 20,
                  child: DropdownButtonFormField<String>(
                    initialValue: value,
                    isDense: true,
                    isExpanded: true,
                    iconSize: 12,
                    style: const TextStyle(fontSize: 9, color: Colors.black),
                    decoration: _decoration(),
                    items: [
                      DropdownMenuItem(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tableHeader(List<String> labels, List<double> widths) => Container(
    height: 28,
    color: const Color(0xffe9edf1),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          _cell(labels[i], widths[i], bold: true),
      ],
    ),
  );
  Widget _row(List<Widget> cells, {double height = 29}) => Container(
    height: height,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffe5e8eb))),
    ),
    child: Row(children: cells),
  );
  Widget _cell(String text, double width, {bool bold = false}) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xff23394d),
        ),
      ),
    ),
  );
  Widget _dotCell(double width) => SizedBox(
    width: width,
    child: const Center(child: Icon(Icons.circle, size: 8, color: Colors.red)),
  );
  Widget _selectBox(String value, double width) => SizedBox(
    width: width,
    height: 20,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      iconSize: 11,
      style: const TextStyle(fontSize: 8, color: Colors.black),
      decoration: _decoration(),
      items: [
        DropdownMenuItem(
          value: value,
          child: Text(value, overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (_) {},
    ),
  );
  Widget _blueButton(String label) => SizedBox(
    height: 19,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff087ff5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 7)),
    ),
  );
  InputDecoration _decoration() => const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffcfd6de)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffcfd6de)),
    ),
  );
  static final ButtonStyle _outlineButtonStyle = OutlinedButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    side: const BorderSide(color: Color(0xff00a0df)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
  );
}
