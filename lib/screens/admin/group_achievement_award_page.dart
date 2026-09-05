import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/group_state_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupAchievementAwardPage extends StatefulWidget {
  const GroupAchievementAwardPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupAchievementAwardPage> createState() =>
      _GroupAchievementAwardPageState();
}

class _GroupAchievementAwardPageState extends State<GroupAchievementAwardPage> {
  final GroupService _groupService = GroupService();
  List<String> _students = const [];
  List<GroupStudent> _classStudents = const [];
  List<GroupTeacher> _classTeachers = const [];
  String _groupName = '';
  bool _membersLoading = true;
  int _selectedTab = 0;
  final Map<String, String> _awards = {};

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final groupId = widget.group.id.trim().isNotEmpty &&
            widget.group.id.toLowerCase() != 'unknown'
        ? widget.group.id.trim()
        : widget.group.name.trim();
    if (groupId.isEmpty || groupId.toLowerCase() == 'unknown') {
      if (mounted) {
        setState(() {
          _membersLoading = false;
        });
      }
      return;
    }
    try {
      final remote = await _groupService.getGroupDetails(
        widget.group.databaseId.isNotEmpty ? widget.group.databaseId : groupId,
      );
      if (!mounted) return;
      setState(() {
        final remoteName = remote.group.name.trim();
        if (remoteName.isNotEmpty && remoteName.toLowerCase() != 'unknown') {
          _groupName = remoteName;
        }
        _classStudents = remote.students;
        _classTeachers = remote.teachers;
        _students = remote.students
            .map(_studentLabel)
            .where((label) => label.isNotEmpty)
            .toList();
        _membersLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _membersLoading = false;
        _students = const [];
        _classStudents = const [];
        _classTeachers = const [];
      });
    }
  }

  String _studentLabel(GroupStudent student) {
    final id = student.admissionNo.isNotEmpty ? student.admissionNo : student.id;
    if (student.name.isEmpty) return id;
    return id.isEmpty ? student.name : '${student.name} - $id';
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
          onPressed: () => navigateBack(context),
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
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _TabBar(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
            if (_selectedTab == 0) _groupContent() else _classContent(),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _groupContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_groupName.trim().isNotEmpty && _groupName.toLowerCase() != 'unknown')
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(
            'Group Name: $_groupName',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      SizedBox(
        height: 30,
        child: Padding(
          padding: const EdgeInsets.only(left: 5, top: 6, right: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Awards/Appreciation for Students in the Class',
                  style: TextStyle(fontSize: 11, color: Color(0xff333333)),
                ),
              ),
              TextButton(
                onPressed: _students.isEmpty ? null : _addAward,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Add', style: TextStyle(fontSize: 10, color: Color(0xff0066cc))),
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
          style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Color(0xff333333)),
        ),
      ),
      if (_membersLoading)
        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
      else if (_students.isEmpty)
        const SizedBox.shrink()
      else
        ..._students.map(
          (student) => _StudentAwardRow(
            student: student,
            award: _awards[student],
            onClassSummary: () {},
            onAllSummary: () {},
          ),
        ),
    ],
  );

  Widget _classContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: _groupName.trim().isEmpty || _groupName.toLowerCase() == 'unknown'
            ? const SizedBox.shrink()
            : Text('Class: $_groupName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      const _SubsectionHeader(title: 'Teachers'),
      if (_membersLoading)
        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
      else if (_classTeachers.isEmpty)
        const SizedBox.shrink()
      else
        ..._classTeachers.map(
          (teacher) => _MemberLine(
            name: teacher.name,
            detail: [teacher.teacherId, teacher.subject, teacher.role]
                .where((value) => value.trim().isNotEmpty)
                .join(' | '),
          ),
        ),
      const _SubsectionHeader(title: 'Students'),
      if (_membersLoading)
        const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
      else if (_classStudents.isEmpty)
        const SizedBox.shrink()
      else
        ..._classStudents.map(
          (student) => _MemberLine(
            name: student.name,
            detail: [student.admissionNo, student.section]
                .where((value) => value.trim().isNotEmpty)
                .join(' | '),
          ),
        ),
    ],
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(5, 8, 5, 0),
    height: 30,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffd5d9e2)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      children: [
        _Tab(
          label: 'Group',
          selected: selectedIndex == 0,
          onPressed: () => onChanged(0),
        ),
        _Tab(
          label: 'Class',
          selected: selectedIndex == 1,
          onPressed: () => onChanged(1),
        ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onPressed});

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? const Color(0xff34395f) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xff34395f),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 9, 8, 5),
    child: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
    ),
    child: Row(
      children: [
        Expanded(child: Text(name.isEmpty ? 'Unnamed' : name, style: const TextStyle(fontSize: 10))),
        if (detail.isNotEmpty)
          Text(detail, style: const TextStyle(fontSize: 9, color: Color(0xff555555))),
      ],
    ),
  );
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
            onPressed: () => navigateBack(context),
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
                onPressed: () => navigateBack(context),
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
