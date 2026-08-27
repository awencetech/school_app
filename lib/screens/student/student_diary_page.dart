// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentDiaryPage extends StatefulWidget {
  const StudentDiaryPage({super.key});

  @override
  State<StudentDiaryPage> createState() => _StudentDiaryPageState();
}

class _StudentDiaryPageState extends State<StudentDiaryPage> {
  DateTime _date = DateTime(2026, 8, 27);

  String get _dateText =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _changeDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _openParentEntry() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _ParentEntryPage()));
  }

  void _openStudentEntry() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _StudentEntryPage()));
  }

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 7),
            child: Text(
              'Student Diary Entry',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 7, 4, 5),
            child: Text(
              'For MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          _dateToolbar(),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 5, 4, 4),
            child: Text(
              'Area',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xff333333),
              ),
            ),
          ),
          _entryRow('Parent Entry', _openParentEntry),
          _entryRow('Student Entry', _openStudentEntry),
          _entryRow('Teacher Entry', null),
          _entryRow('GK Score Entry', null),
          _entryRow('Subject Feedback Entry', null),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 2),
            child: Text(
              'Diary for Diary Entry for SAMUNI-S1746 on 2026-08-27',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Text('No details present', style: TextStyle(fontSize: 8)),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _dateToolbar() => Container(
    height: 29,
    color: const Color(0xfff1f3f5),
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, right: 5),
          child: Text(
            'Diary on:',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ),
        _dateButton(
          Icons.chevron_left,
          () => setState(() => _date = _date.subtract(const Duration(days: 1))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_dateText, style: const TextStyle(fontSize: 9)),
        ),
        _dateButton(
          Icons.chevron_right,
          () => setState(() => _date = _date.add(const Duration(days: 1))),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 19,
          child: OutlinedButton(
            onPressed: _changeDate,
            style: _buttonStyle,
            child: const Text('Change Date', style: TextStyle(fontSize: 7)),
          ),
        ),
      ],
    ),
  );

  Widget _dateButton(IconData icon, VoidCallback onPressed) => SizedBox(
    width: 20,
    height: 19,
    child: OutlinedButton(
      onPressed: onPressed,
      style: _buttonStyle,
      child: Icon(icon, size: 13, color: const Color(0xff008ad8)),
    ),
  );

  Widget _entryRow(String label, VoidCallback? onPressed) => Container(
    height: 25,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffdddddd))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 158,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(label, style: const TextStyle(fontSize: 9)),
          ),
        ),
        const Icon(Icons.circle, color: Colors.red, size: 10),
        const SizedBox(width: 8),
        if (onPressed != null)
          SizedBox(
            height: 18,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text('Enter $label', style: const TextStyle(fontSize: 7)),
            ),
          ),
      ],
    ),
  );
}

const _buttonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
  minimumSize: WidgetStatePropertyAll(Size.zero),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  side: WidgetStatePropertyAll(BorderSide(color: Color(0xff8cc8e8))),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
  ),
);

class _ParentEntryPage extends StatelessWidget {
  const _ParentEntryPage();

  @override
  Widget build(BuildContext context) {
    return _DiaryFormScaffold(
      title: "Parent’s Observations for S1746 MOHAMED AZEEMSHA A",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Date : 27-Aug-2026', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 8),
          _timeField('My Child went to bed at'),
          _timeField('My Child got up at'),
          _choices('Brushed teeth', ['Once', 'Twice']),
          _choices('Did do Yoga?', ['Yes', 'No']),
          _choices('Breakfast', ['Had breakfast', 'Refused']),
          _choices('Homework', ['Completed', 'Did not do']),
          _choices('Completion of Assignments', [
            'Worked Independently',
            'Did under Supervision',
            'Failed to do the work',
          ]),
          _choices('Helpful at home', ['Very much', 'Sometimes', 'Never']),
          _choices('Respectful to elders at home', [
            'Very much',
            'Sometimes',
            'Never',
          ]),
          const Text('Parents Remark', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          _formButtons(),
        ],
      ),
    );
  }
}

class _StudentEntryPage extends StatelessWidget {
  const _StudentEntryPage();

  @override
  Widget build(BuildContext context) {
    return _DiaryFormScaffold(
      title: "Student’s Observations for S1746 MOHAMED AZEEMSHA A",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Date : 27-Aug-2026',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          const Text('My Day at School', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _Mood('🤪', 'Exciting'),
              _Mood('🙂', 'Happy'),
              _Mood('😴', 'Lazy'),
              _Mood('😢', 'Sad'),
              _Mood('😡', 'Angry'),
            ],
          ),
          const SizedBox(height: 14),
          _formButtons(),
        ],
      ),
    );
  }
}

class _DiaryFormScaffold extends StatelessWidget {
  const _DiaryFormScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
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
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
    bottomNavigationBar: const AppBottomNavigation(),
  );
}

Widget _timeField(String label) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 3),
      const TextField(
        decoration: InputDecoration(
          hintText: '--:-- --',
          isDense: true,
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time, size: 14),
        ),
      ),
    ],
  ),
);

Widget _choices(String label, List<String> options) => Padding(
  padding: const EdgeInsets.only(bottom: 9),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11)),
      Wrap(
        spacing: 12,
        children: options
            .map(
              (option) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Radio<bool>(
                      value: false,
                      groupValue: null,
                      onChanged: (_) {},
                    ),
                  ),
                  Text(option, style: const TextStyle(fontSize: 10)),
                ],
              ),
            )
            .toList(),
      ),
    ],
  ),
);

Widget _formButtons() => Row(
  children: [
    ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff087ff5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: const Text('Insert', style: TextStyle(fontSize: 8)),
    ),
    const SizedBox(width: 10),
    const Text('Reset', style: TextStyle(fontSize: 8)),
  ],
);

class _Mood extends StatelessWidget {
  const _Mood(this.emoji, this.label);
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      Text(label, style: const TextStyle(fontSize: 8)),
    ],
  );
}
