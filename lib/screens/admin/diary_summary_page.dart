import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../models/parent_observation.dart';
import '../../services/group_service.dart';
import '../../services/group_state_service.dart';
import '../../services/parent_observation_service.dart';
import '../../services/student_service.dart';
import '../../widgets/admin_bottom_nav.dart';
import 'parent_observations_page.dart';
import 'student_observations_page.dart';

class DiarySummaryPage extends StatefulWidget {
  const DiarySummaryPage({super.key, required this.group});

  final Group group;

  @override
  State<DiarySummaryPage> createState() => _DiarySummaryPageState();
}

class _DiarySummaryPageState extends State<DiarySummaryPage> {
  final GroupStateService _stateService = GroupStateService.instance;
  final GroupService _groupService = GroupService();
  final ParentObservationService _observationService =
      ParentObservationService();
  List<GroupStudent> _students = [];
  Map<String, ParentObservation> _observations = {};
  bool _isLoading = true;

  int _tab = 0;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      await _stateService.initialize();
      final groupId = widget.group.id.isNotEmpty
          ? widget.group.id
          : widget.group.name;
      final localStudents = await _stateService.getGroupStudents(groupId);
      var students = localStudents;
      try {
        final remote = await _groupService.getGroupDetails(
          widget.group.databaseId.isNotEmpty
              ? widget.group.databaseId
              : groupId,
        );
        if (remote.students.isNotEmpty || localStudents.isEmpty) {
          students = remote.students;
        }
      } catch (_) {}
      if (students.isEmpty) {
        try {
          final directoryStudents = await StudentService().getStudents();
          students = directoryStudents
              .map(
                (student) => GroupStudent(
                  id: student.studentId,
                  groupId: groupId,
                  name: student.name,
                  admissionNo: student.admissionNumber,
                  section: student.section,
                  imageUrl: student.imageUrl,
                ),
              )
              .toList();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
        await _loadObservations();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadObservations() async {
    final groupId = widget.group.id.isNotEmpty
        ? widget.group.id
        : widget.group.name;
    try {
      final records = await _observationService.getForGroupDate(
        groupId: groupId,
        date: _dateText,
      );
      if (!mounted) return;
      setState(() {
        _observations = {
          for (final record in records) record.studentId: record,
        };
      });
    } catch (_) {
      if (mounted) setState(() => _observations = {});
    }
  }

  String _studentId(GroupStudent student) =>
      student.id.isNotEmpty ? student.id : student.admissionNo;

  Future<void> _openParentForm(GroupStudent student) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ParentObservationsPage(
          group: widget.group,
          student: student,
          date: _date,
        ),
      ),
    );
    if (saved == true) {
      await _loadObservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parent observations saved successfully.'),
          ),
        );
      }
    }
  }

  Future<void> _viewParentObservation(GroupStudent student) async {
    final record = _observations[_studentId(student)];
    if (record == null || record.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No observation saved for this date.')),
        );
      }
      return;
    }
    if (record.studentMood.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentObservationsPage(
            group: widget.group,
            student: student,
            date: _date,
            recordId: record.id,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentObservationsPage(
          group: widget.group,
          student: student,
          date: _date,
          recordId: record.id,
        ),
      ),
    );
  }

  Future<void> _openStudentForm(GroupStudent student) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StudentObservationsPage(
          group: widget.group,
          student: student,
          date: _date,
        ),
      ),
    );
    if (saved == true) {
      await _loadObservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student observation saved successfully.'),
          ),
        );
      }
    }
  }

  Future<void> _openCompleteEditor(GroupStudent student) async {
    final record = _observations[_studentId(student)];
    final controllers = <String, TextEditingController>{
      'area': TextEditingController(text: record?.area ?? ''),
      'status': TextEditingController(text: record?.status ?? ''),
      'bed': TextEditingController(text: record?.wentToBedAt ?? ''),
      'wake': TextEditingController(text: record?.gotUpAt ?? ''),
      'parentRemark': TextEditingController(text: record?.parentsRemark ?? ''),
      'teacherPunctuality': TextEditingController(
        text: record?.teacherPunctuality ?? '',
      ),
      'teacherFood': TextEditingController(text: record?.teacherFood ?? ''),
      'gkScore': TextEditingController(text: record?.gkScore ?? ''),
      'subject': TextEditingController(text: record?.subject ?? ''),
      'assignmentFeedback': TextEditingController(
        text: record?.assignmentCompletionFeedback ?? '',
      ),
      'performance': TextEditingController(
        text: record?.classPerformance ?? '',
      ),
      'subjectNote': TextEditingController(text: record?.subjectNote ?? ''),
      'details': TextEditingController(text: record?.diaryDetails ?? ''),
    };
    final values = <String, String>{
      'brushedTeeth': record?.brushedTeeth ?? '',
      'didYoga': record?.didYoga ?? '',
      'breakfast': record?.breakfast ?? '',
      'homework': record?.homework ?? '',
      'assignmentCompletion': record?.assignmentCompletion ?? '',
      'helpfulAtHome': record?.helpfulAtHome ?? '',
      'respectfulToElders': record?.respectfulToElders ?? '',
      'mood': record?.studentMood ?? '',
    };
    const choices = <String, Map<String, String>>{
      'brushedTeeth': {'once': 'Once', 'twice': 'Twice'},
      'didYoga': {'yes': 'Yes', 'no': 'No'},
      'breakfast': {'had_breakfast': 'Had breakfast', 'refused': 'Refused'},
      'homework': {'completed': 'Completed', 'did_not_do': 'Did not do'},
      'assignmentCompletion': {
        'worked_independently': 'Worked independently',
        'did_under_supervision': 'Did under supervision',
        'failed_to_do': 'Failed to do the work',
      },
      'helpfulAtHome': {
        'very_much': 'Very much',
        'sometimes': 'Sometimes',
        'never': 'Never',
      },
      'respectfulToElders': {
        'very_much': 'Very much',
        'sometimes': 'Sometimes',
        'never': 'Never',
      },
      'mood': {
        'exciting': 'Exciting',
        'happy': 'Happy',
        'lazy': 'Lazy',
        'sad': 'Sad',
        'angry': 'Angry',
      },
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${student.name} - ${_dateText}',
            style: const TextStyle(fontSize: 14),
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _editorField(controllers['area']!, 'Area'),
                  _editorField(controllers['status']!, 'Status'),
                  const Divider(),
                  const Text(
                    'Parent Entry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _editorField(controllers['bed']!, 'My Child went to bed at'),
                  _editorField(controllers['wake']!, 'My Child got up at'),
                  ...choices.entries
                      .where((entry) => entry.key != 'mood')
                      .map(
                        (entry) => _editorChoice(
                          entry.key,
                          entry.value,
                          values,
                          setDialogState,
                        ),
                      ),
                  _editorField(
                    controllers['parentRemark']!,
                    'Parents Remark',
                    maxLines: 3,
                  ),
                  const Divider(),
                  const Text(
                    'Student Entry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _editorChoice(
                    'mood',
                    choices['mood']!,
                    values,
                    setDialogState,
                  ),
                  const Divider(),
                  const Text(
                    'Teacher Entry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _editorField(
                    controllers['teacherPunctuality']!,
                    'Punctuality',
                  ),
                  _editorField(controllers['teacherFood']!, 'Food'),
                  const Divider(),
                  const Text(
                    'GK Score Entry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _editorField(controllers['gkScore']!, 'GK Score'),
                  const Divider(),
                  const Text(
                    'Subject Feedback Entry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _editorField(controllers['subject']!, 'Subject'),
                  _editorField(
                    controllers['assignmentFeedback']!,
                    'Completion of Due Assignment',
                  ),
                  _editorField(
                    controllers['performance']!,
                    'Performance in Class Today',
                  ),
                  _editorField(
                    controllers['subjectNote']!,
                    'Note',
                    maxLines: 2,
                  ),
                  _editorField(
                    controllers['details']!,
                    'Diary Details',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final groupId = widget.group.id.isNotEmpty
                      ? widget.group.id
                      : widget.group.name;
                  await _observationService.saveCompleteDiary(
                    studentId: _studentId(student),
                    studentName: student.name,
                    groupId: groupId,
                    date: _dateText,
                    area: controllers['area']!.text,
                    status: controllers['status']!.text,
                    diaryDetails: controllers['details']!.text,
                    wentToBedAt: controllers['bed']!.text,
                    gotUpAt: controllers['wake']!.text,
                    parentValues: values,
                    parentsRemark: controllers['parentRemark']!.text,
                    mood: values['mood']!,
                    teacherObservation: {
                      'punctuality': controllers['teacherPunctuality']!.text,
                      'food': controllers['teacherFood']!.text,
                    },
                    subjectFeedback: {
                      'subject': controllers['subject']!.text,
                      'completionOfDueAssignment':
                          controllers['assignmentFeedback']!.text,
                      'performanceInClassToday':
                          controllers['performance']!.text,
                      'note': controllers['subjectNote']!.text,
                    },
                    gkScore: controllers['gkScore']!.text,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Save / Update'),
            ),
          ],
        ),
      ),
    );
    for (final controller in controllers.values) controller.dispose();
    if (saved == true) await _loadObservations();
  }

  Widget _editorField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _editorChoice(
    String key,
    Map<String, String> options,
    Map<String, String> values,
    StateSetter setDialogState,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: DropdownButtonFormField<String>(
      value: options.containsKey(values[key]) ? values[key] : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: key == 'mood' ? 'My Day at School' : key,
        isDense: true,
      ),
      items: options.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: (value) => setDialogState(() => values[key] = value ?? ''),
    ),
  );

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _date = selected);
      await _loadObservations();
    }
  }

  Future<void> _editSections(GroupStudent student, String section) async {
    final record = _observations[_studentId(student)];
    final controllers = <String, TextEditingController>{};
    final fields = section == 'subject'
        ? [
            'Subject',
            'Completion of Due Assignment',
            'Performance in Class Today',
            'Note',
          ]
        : section == 'teacher'
        ? ['Punctuality', 'Food']
        : section == 'details'
        ? ['Area', 'Status', 'Diary Details']
        : ['GK Score'];
    for (final field in fields) {
      final value = switch (field) {
        'Subject' => record?.subject ?? '',
        'Completion of Due Assignment' =>
          record?.assignmentCompletionFeedback ?? '',
        'Performance in Class Today' => record?.classPerformance ?? '',
        'Note' => record?.subjectNote ?? '',
        'Punctuality' => record?.teacherPunctuality ?? '',
        'Food' => record?.teacherFood ?? '',
        'Area' => record?.area ?? '',
        'Status' => record?.status ?? '',
        'Diary Details' => record?.diaryDetails ?? '',
        _ => record?.gkScore ?? '',
      };
      controllers[field] = TextEditingController(text: value);
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$section entry', style: const TextStyle(fontSize: 14)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields
                .map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: controllers[field],
                      decoration: InputDecoration(
                        labelText: field,
                        isDense: true,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final groupId = widget.group.id.isNotEmpty
                    ? widget.group.id
                    : widget.group.name;
                await _observationService.updateDiarySections(
                  studentId: _studentId(student),
                  studentName: student.name,
                  groupId: groupId,
                  date: _dateText,
                  teacherObservation: section == 'teacher'
                      ? {
                          'punctuality': controllers['Punctuality']!.text,
                          'food': controllers['Food']!.text,
                        }
                      : null,
                  subjectFeedback: section == 'subject'
                      ? {
                          'subject': controllers['Subject']!.text,
                          'completionOfDueAssignment':
                              controllers['Completion of Due Assignment']!.text,
                          'performanceInClassToday':
                              controllers['Performance in Class Today']!.text,
                          'note': controllers['Note']!.text,
                        }
                      : null,
                  gkScore: section == 'score'
                      ? controllers['GK Score']!.text
                      : null,
                  area: section == 'details' ? controllers['Area']!.text : null,
                  status: section == 'details'
                      ? controllers['Status']!.text
                      : null,
                  diaryDetails: section == 'details'
                      ? controllers['Diary Details']!.text
                      : null,
                );
                if (context.mounted) Navigator.pop(context, true);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) controller.dispose();
    if (saved == true) await _loadObservations();
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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 17, color: Colors.white),
        ),
        title: const Text(
          'Class Students Diary',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
        actions: [
          IconButton(
            onPressed: () => navigateBack(context),
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
        _smallButton(Icons.chevron_left, () async {
          setState(() => _date = _date.subtract(const Duration(days: 1)));
          await _loadObservations();
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_dateText, style: const TextStyle(fontSize: 9)),
        ),
        _smallButton(Icons.chevron_right, () async {
          setState(() => _date = _date.add(const Duration(days: 1)));
          await _loadObservations();
        }),
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
        _tabButton('Subject Feedback', 1),
        _tabButton('Teacher Entry', 2),
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

  Widget _parentTab() {
    final students = List<GroupStudent>.of(_students);
    return Column(
      children: [
        _tableHeader(
          ['Id', 'Name', 'Status', 'Parent', 'Student', 'Overview', 'Edit'],
          const [32, 105, 45, 42, 45, 48, 42],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, index) => _parentRow(students[index]),
                ),
        ),
      ],
    );
  }

  Widget _parentRow(GroupStudent student) => _row([
    _cell(student.admissionNo, 32),
    _cell(student.name, 105),
    GestureDetector(
      onTap: () => _editSections(student, 'details'),
      child: _cell(
        _observations.containsKey(_studentId(student)) ? 'Updated' : 'Pending',
        45,
      ),
    ),
    _actionCell(42, Icons.circle, Colors.red, () => _openParentForm(student)),
    _actionCell(45, Icons.circle, Colors.red, () => _openStudentForm(student)),
    _actionCell(
      48,
      Icons.visibility,
      Colors.blue,
      () => _viewParentObservation(student),
    ),
    _actionCell(
      45,
      Icons.edit,
      Colors.deepPurple,
      () => _openCompleteEditor(student),
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
        ['Id-Name', 'Subject feedback', 'Edit'],
        const [150, 150, 55],
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (_, index) {
            final student = _students[index];
            final record = _observations[_studentId(student)];
            return _row([
              _cell('${student.admissionNo}-${student.name}', 150),
              _cell(record?.subjectNote ?? 'Not entered', 150),
              _actionCell(
                55,
                Icons.edit,
                Colors.blue,
                () => _editSections(student, 'subject'),
              ),
            ]);
          },
        ),
      ),
    ],
  );

  Widget _teacherTab() {
    final students = List<GroupStudent>.of(_students);
    return Column(
      children: [
        _tableHeader(
          ['Id-Name', 'Discipline', 'Food', 'Edit'],
          const [75, 100, 100, 50],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (_, index) => _teacherRow(students[index]),
          ),
        ),
      ],
    );
  }

  Widget _teacherRow(GroupStudent student) => _row([
    _cell('${student.admissionNo}-${student.name}', 75),
    _cell(
      _observations[_studentId(student)]?.teacherPunctuality ?? 'Not entered',
      100,
    ),
    _cell(
      _observations[_studentId(student)]?.teacherFood ?? 'Not entered',
      100,
    ),
    _actionCell(
      50,
      Icons.edit,
      Colors.blue,
      () => _editSections(student, 'teacher'),
    ),
  ], height: 84);

  Widget _scoreTab() {
    final students = List<GroupStudent>.of(_students);
    return Column(
      children: [
        _tableHeader(['Id-Name', 'Score', 'Edit'], const [145, 100, 50]),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (_, index) => _row([
              _cell(
                '${students[index].admissionNo}-${students[index].name}',
                165,
              ),
              _cell(
                _observations[_studentId(students[index])]?.gkScore ??
                    'Not entered',
                100,
              ),
              _actionCell(
                50,
                Icons.edit,
                Colors.blue,
                () => _editSections(students[index], 'score'),
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
  }

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
  Widget _actionCell(
    double width,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => SizedBox(
    width: width,
    height: 20,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(child: Icon(icon, size: 10, color: color)),
    ),
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
