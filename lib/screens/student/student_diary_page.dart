// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../models/parent_observation.dart';
import '../../services/parent_observation_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentDiaryPage extends StatefulWidget {
  const StudentDiaryPage({super.key});

  @override
  State<StudentDiaryPage> createState() => _StudentDiaryPageState();
}

class _StudentDiaryPageState extends State<StudentDiaryPage> {
  DateTime _date = DateTime.now();
  final ParentObservationService _service = ParentObservationService();
  ParentObservation? _record;
  bool _loading = true;
  String? _error;

  String get _dateText =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await _service.getForStudentDate(date: _dateText);
      if (mounted) setState(() => _record = record);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _date = selected);
      await _loadDiary();
    }
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
          Padding(
            padding: EdgeInsets.fromLTRB(4, 7, 4, 5),
            child: Text(
              _record == null || _record!.studentName.isEmpty
                  ? 'Student'
                  : 'For ${_record!.studentName}',
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
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 5, 4, 4),
            child: Text(
              'Staff updated diary details',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xff333333),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  'Unable to load diary. Pull to refresh or try again.',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
            )
          else
            Expanded(child: _readOnlyDetails()),
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
        _dateButton(Icons.chevron_left, () async {
          setState(() => _date = _date.subtract(const Duration(days: 1)));
          await _loadDiary();
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_dateText, style: const TextStyle(fontSize: 9)),
        ),
        _dateButton(Icons.chevron_right, () async {
          setState(() => _date = _date.add(const Duration(days: 1)));
          await _loadDiary();
        }),
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

  Widget _readOnlyDetails() {
    final record = _record;
    if (record == null) {
      return const Center(
        child: Text(
          'No diary entry has been added by staff.',
          style: TextStyle(fontSize: 10),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      children: [
        Text(
          'Diary entry for ${record.studentName} on ${record.date}',
          style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
        ),
        const SizedBox(height: 8),
        _detail('Bed time', record.wentToBedAt),
        _detail('Wake up time', record.gotUpAt),
        _detail('Brushed teeth', record.brushedTeeth),
        _detail('Yoga', record.didYoga),
        _detail('Breakfast', record.breakfast),
        _detail('Homework', record.homework),
        _detail('Assignments', record.assignmentCompletion),
        _detail('Helpful at home', record.helpfulAtHome),
        _detail('Respectful to elders', record.respectfulToElders),
        _detail('Parent remark', record.parentsRemark),
        _detail('Student mood', record.studentMood),
        _detail('Teacher punctuality', record.teacherPunctuality),
        _detail('Teacher food', record.teacherFood),
        _detail('Subject', record.subject),
        _detail('Assignment feedback', record.assignmentCompletionFeedback),
        _detail('Class performance', record.classPerformance),
        _detail('Subject note', record.subjectNote),
        _detail('GK score', record.gkScore),
        _detail('Area', record.area),
        _detail('Status', record.status),
        _detail('Diary details', record.diaryDetails),
      ],
    );
  }

  Widget _detail(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffdddddd))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 9)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontSize: 9),
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
