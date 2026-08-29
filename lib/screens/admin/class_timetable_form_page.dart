import 'package:flutter/material.dart';
import '../../models/class_timetable.dart';
import '../../models/group.dart';
import '../../services/class_timetable_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassTimetableFormPage extends StatefulWidget {
  const ClassTimetableFormPage({super.key, required this.group, this.entry});
  final Group group;
  final ClassTimetableEntry? entry;
  @override
  State<ClassTimetableFormPage> createState() => _ClassTimetableFormPageState();
}

class _ClassTimetableFormPageState extends State<ClassTimetableFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _teacher = TextEditingController();
  final _room = TextEditingController();
  final _notes = TextEditingController();
  final _service = ClassTimetableService();
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String? _day, _error;
  TimeOfDay? _start, _end;
  bool _saving = false;
  String get _groupId => widget.group.id.trim().isNotEmpty
      ? widget.group.id.trim()
      : widget.group.name.trim();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _day = entry.day;
      _start = _parse(entry.startTime);
      _end = _parse(entry.endTime);
      _subject.text = entry.subject;
      _teacher.text = entry.teacher;
      _room.text = entry.room;
      _notes.text = entry.notes;
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _teacher.dispose();
    _room.dispose();
    _notes.dispose();
    super.dispose();
  }

  TimeOfDay? _parse(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    if (match.group(3)!.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (match.group(3)!.toUpperCase() == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: int.parse(match.group(2)!));
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start
          ? (_start ?? TimeOfDay.now())
          : (_end ?? _start ?? TimeOfDay.now()),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    isDense: true,
  );
  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _day == null ||
        _start == null ||
        _end == null) {
      setState(() => _error = 'Day, start time, and end time are required.');
      return;
    }
    if (_minutes(_end!) <= _minutes(_start!)) {
      setState(() => _error = 'End time must be later than start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final entries = await _service.getForGroup(_groupId);
      final overlap = entries.any((entry) {
        final start = _parse(entry.startTime), end = _parse(entry.endTime);
        return entry.id != widget.entry?.id &&
            entry.day == _day &&
            start != null &&
            end != null &&
            _minutes(start) < _minutes(_end!) &&
            _minutes(end) > _minutes(_start!);
      });
      if (overlap) {
        setState(() {
          _saving = false;
          _error = 'This time overlaps another entry for $_day.';
        });
        return;
      }
      if (!mounted) return;
      final startTimeLabel = _start!.format(context);
      final endTimeLabel = _end!.format(context);
      final entryToSave = ClassTimetableEntry(
        id: widget.entry?.id ?? '',
        groupId: _groupId,
        day: _day!,
        startTime: startTimeLabel,
        endTime: endTimeLabel,
        subject: _subject.text.trim(),
        teacher: _teacher.text.trim(),
        room: _room.text.trim(),
        notes: _notes.text.trim(),
      );

      await _service.save(_groupId, entryToSave);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  Widget _timeButton(String label, TimeOfDay? value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _decoration(label),
          child: Text(value == null ? 'Select' : value.format(context)),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: AppColors.topBar,
      title: Text(
        widget.entry == null ? 'Add Class Timetable' : 'Edit Class Timetable',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _day,
            decoration: _decoration('Day'),
            items: _days
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
            onChanged: (value) => setState(() => _day = value),
            validator: (value) => value == null ? 'Select a day' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeButton('Start Time', _start, () => _pick(true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _timeButton('End Time', _end, () => _pick(false)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subject,
            decoration: _decoration('Subject'),
            validator: (value) =>
                value!.trim().isEmpty ? 'Subject is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _teacher,
            decoration: _decoration('Teacher'),
            validator: (value) =>
                value!.trim().isEmpty ? 'Teacher is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _room,
            decoration: _decoration('Room (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 3,
            decoration: _decoration('Notes (optional)'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueButton,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save'),
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
