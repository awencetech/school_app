import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupAchievementAwardPage extends StatefulWidget {
  const GroupAchievementAwardPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupAchievementAwardPage> createState() =>
      _GroupAchievementAwardPageState();
}

class _GroupAchievementAwardPageState extends State<GroupAchievementAwardPage> {
  static const _fallbackStudents = [
    'SADAF FATHIMA I - S1197',
    'MIRASHI SINGH J - S1289',
    'VEDARSH VISAKA MOORTHY TN - S1319',
    'VAISHAVI K M - S1346',
    'Aashish Kumar M - S1378',
    'HARIPRAKASH M I - S1388',
    'SURIYA VISWANATHAN K - S270',
    'SHRIDHARSHINI M - S875',
    'HARINI N - S1654',
    'VAHINI k R - S1618',
    'SANOFAR A - S1670',
    'DWARAGA S - S1765',
    'MITHUSHI SINGH J - S1288',
    'MITHUSHI SINGH J - S1288',
    'INEIYAA V.S - S1662',
    'SAHANA SRI G - S1726',
  ];

  final UserService _userService = UserService();
  List<String> _students = _fallbackStudents;
  final Map<String, String> _awards = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final users = await _userService.getUsers(role: 'student');
      if (!mounted || users.isEmpty) return;
      setState(() {
        _students = users
            .map((user) => user.userId)
            .where((id) => id.isNotEmpty)
            .toList();
      });
    } catch (_) {
      // The reference roster remains useful while the backend is unavailable.
    }
  }

  Future<void> _addAward() async {
    final entry = await showDialog<_AwardEntry>(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => _AddAwardForm(students: _students),
    );
    if (entry != null) {
      setState(() => _awards[entry.student] = entry.title);
    }
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
            SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.only(left: 5, top: 6, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Awards/Appreciation for ${widget.group.name} - ${widget.group.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff333333),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _addAward,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xff0066cc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffdddddd)),
            const Padding(
              padding: EdgeInsets.only(left: 5, top: 5, bottom: 6),
              child: Text(
                'Awards/Certificates/Appreciation for Students in the Class .......',
                style: TextStyle(
                  fontSize: 8,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff333333),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final award = _awards[student];
                  return _StudentAwardRow(
                    student: student,
                    award: award,
                    onClassSummary: () {},
                    onAllSummary: () {},
                  );
                },
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

class _AwardEntry {
  const _AwardEntry({required this.student, required this.title});

  final String student;
  final String title;
}

class _AddAwardForm extends StatefulWidget {
  const _AddAwardForm({required this.students});

  final List<String> students;

  @override
  State<_AddAwardForm> createState() => _AddAwardFormState();
}

class _AddAwardFormState extends State<_AddAwardForm> {
  late String _student;
  String _type = '(Select One)';
  DateTime _date = DateTime(2026, 8, 21);
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _student = widget.students.isEmpty ? '(Select One)' : '(Select One)';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final date =
        '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}';
    final studentItems = ['(Select One)', ...widget.students];
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 26, top: 12, right: 22),
            child: SizedBox(
              width: 259,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _formLabel('Student ID'),
                  _dropdown(
                    value: _student,
                    items: studentItems,
                    onChanged: (value) => setState(() => _student = value!),
                  ),
                  const SizedBox(height: 12),
                  _formLabel('Observation date'),
                  _dateField(date),
                  const SizedBox(height: 12),
                  _formLabel('Short description/Title'),
                  SizedBox(
                    height: 26,
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 10),
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _formLabel('Type'),
                  _dropdown(
                    value: _type,
                    items: const [
                      '(Select One)',
                      'Award',
                      'Certificate',
                      'Appreciation',
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 13),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 31,
                      height: 19,
                      child: ElevatedButton(
                        onPressed:
                            _student == '(Select One)' ||
                                _titleController.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                context,
                                _AwardEntry(
                                  student: _student,
                                  title: _titleController.text.trim(),
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff087ff5),
                          disabledBackgroundColor: const Color(0xff087ff5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'Insert',
                          style: TextStyle(fontSize: 7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: AdminBottomNavigationBar(
          currentIndex: 2,
          onItemSelected: (_) {},
        ),
      ),
    );
  }

  Widget _formLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
    ),
  );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 26,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        iconSize: 13,
        style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
        decoration: _inputDecoration(),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(String date) => SizedBox(
    height: 26,
    child: TextField(
      readOnly: true,
      onTap: _selectDate,
      controller: TextEditingController(text: date),
      style: const TextStyle(fontSize: 10),
      decoration: _inputDecoration().copyWith(
        suffixIcon: const Icon(Icons.calendar_today, size: 13),
      ),
    ),
  );

  InputDecoration _inputDecoration() => const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffcfd6de)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffcfd6de)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xff087ff5)),
    ),
  );
}

class _StudentAwardRow extends StatelessWidget {
  const _StudentAwardRow({
    required this.student,
    required this.award,
    required this.onClassSummary,
    required this.onAllSummary,
  });

  final String student;
  final String? award;
  final VoidCallback onClassSummary;
  final VoidCallback onAllSummary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 18,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      student,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xff333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClassSummary,
                  style: _summaryButtonStyle,
                  child: const Text('Summary(Class)'),
                ),
                TextButton(
                  onPressed: onAllSummary,
                  style: _summaryButtonStyle,
                  child: const Text('Summary(All)'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              award ?? 'No record',
              style: const TextStyle(
                fontSize: 8,
                fontStyle: FontStyle.italic,
                color: Color(0xff555555),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
        ],
      ),
    );
  }

  static final ButtonStyle _summaryButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 7),
    foregroundColor: const Color(0xff0066cc),
  );
}
