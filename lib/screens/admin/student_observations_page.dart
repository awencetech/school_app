// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../services/group_state_service.dart';
import '../../services/parent_observation_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class StudentObservationsPage extends StatefulWidget {
  const StudentObservationsPage({
    super.key,
    required this.group,
    required this.student,
    required this.date,
    this.recordId,
  });

  final Group group;
  final GroupStudent student;
  final DateTime date;
  final String? recordId;

  bool get readOnly => recordId != null && recordId!.isNotEmpty;

  @override
  State<StudentObservationsPage> createState() =>
      _StudentObservationsPageState();
}

class _StudentObservationsPageState extends State<StudentObservationsPage> {
  final ParentObservationService _service = ParentObservationService();
  String? _mood;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String get _studentId => widget.student.id.isNotEmpty
      ? widget.student.id
      : widget.student.admissionNo;

  String get _groupId =>
      widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;

  String get _date => _formatDate(widget.date);

  String get _diaryId => '$_groupId:$_studentId:$_date';

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final observation = widget.recordId != null
          ? await _service.getStudentObservationById(widget.recordId!)
          : await _service.getForContext(
              studentId: _studentId,
              groupId: _groupId,
              date: _date,
            );
      if (observation != null && observation.studentMood.isNotEmpty) {
        _mood = observation.studentMood;
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_mood == null) {
      _showMessage('Please select an emotion.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _service.saveStudentObservation(
        studentId: _studentId,
        studentName: widget.student.name,
        diaryId: _diaryId,
        classId: _groupId,
        groupId: _groupId,
        date: _date,
        mood: _mood!,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() => setState(() => _mood = null);

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        toolbarHeight: 43,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        title: const Text(
          "Student's Observations",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(9, 10, 9, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Student's Observations for ${widget.student.admissionNo} ${widget.student.name}"
                        .trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Date : ${_displayDate(widget.date)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'My Day at School',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _moodChoices(),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: _buttonStyle,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Insert',
                                  style: TextStyle(fontSize: 9),
                                ),
                        ),
                        TextButton(
                          onPressed: _isSaving ? null : _reset,
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _moodChoices() {
    const moods = <String, String>{
      'exciting': '😆 Exciting',
      'happy': '🙂 Happy',
      'lazy': '😴 Lazy',
      'sad': '😢 Sad',
      'angry': '😡 Angry',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: moods.entries
          .map(
            (entry) => SizedBox(
              width: 150,
              child: RadioListTile<String>(
                value: entry.key,
                groupValue: _mood,
                onChanged: widget.readOnly
                    ? null
                    : (value) => setState(() => _mood = value),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                title: Text(entry.value, style: const TextStyle(fontSize: 11)),
              ),
            ),
          )
          .toList(),
    );
  }

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xff087ff5),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    minimumSize: Size.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
  );

  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${_month(value.month)}-${value.year}';

  String _month(int value) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][value];

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
