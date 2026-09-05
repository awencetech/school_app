// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../models/parent_observation.dart';
import '../../services/group_state_service.dart';
import '../../services/parent_observation_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class ParentObservationsPage extends StatefulWidget {
  const ParentObservationsPage({
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
  State<ParentObservationsPage> createState() => _ParentObservationsPageState();
}

class _ParentObservationsPageState extends State<ParentObservationsPage> {
  final ParentObservationService _service = ParentObservationService();
  final _remarkController = TextEditingController();
  final Map<String, String> _values = <String, String>{};
  String _wentToBedAt = '';
  String _gotUpAt = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  String get _groupId =>
      widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;

  String get _studentId => widget.student.id.isNotEmpty
      ? widget.student.id
      : widget.student.admissionNo;

  String get _date => _formatDate(widget.date);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final observation = widget.recordId != null
          ? await _service.getById(widget.recordId!)
          : await _service.getForContext(
              studentId: _studentId,
              groupId: _groupId,
              date: _date,
            );
      if (observation != null) _applyObservation(observation);
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyObservation(ParentObservation observation) {
    _wentToBedAt = observation.wentToBedAt;
    _gotUpAt = observation.gotUpAt;
    _values
      ..clear()
      ..addAll({
        'brushedTeeth': observation.brushedTeeth,
        'didYoga': observation.didYoga,
        'breakfast': observation.breakfast,
        'homework': observation.homework,
        'assignmentCompletion': observation.assignmentCompletion,
        'helpfulAtHome': observation.helpfulAtHome,
        'respectfulToElders': observation.respectfulToElders,
      });
    _remarkController.text = observation.parentsRemark;
  }

  Future<void> _chooseTime(bool bedtime) async {
    final current = bedtime ? _parseTime(_wentToBedAt) : _parseTime(_gotUpAt);
    final selected = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (selected == null || !mounted) return;
    final value = selected.format(context);
    setState(() {
      if (bedtime) {
        _wentToBedAt = value;
      } else {
        _gotUpAt = value;
      }
    });
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (match.group(3)!.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (match.group(3)!.toUpperCase() == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _save() async {
    final missing = _missingField();
    if (missing != null) {
      _showMessage('Please complete $missing.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _service.save(
        ParentObservation(
          studentId: _studentId,
          studentName: widget.student.name,
          groupId: _groupId,
          date: _date,
          diaryId: '$_groupId:$_studentId:$_date',
          wentToBedAt: _wentToBedAt,
          gotUpAt: _gotUpAt,
          brushedTeeth: _values['brushedTeeth']!,
          didYoga: _values['didYoga']!,
          breakfast: _values['breakfast']!,
          homework: _values['homework']!,
          assignmentCompletion: _values['assignmentCompletion']!,
          helpfulAtHome: _values['helpfulAtHome']!,
          respectfulToElders: _values['respectfulToElders']!,
          parentsRemark: _remarkController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _missingField() {
    if (_wentToBedAt.isEmpty) return 'My Child went to bed at';
    if (_gotUpAt.isEmpty) return 'My Child got up at';
    const required = [
      'brushedTeeth',
      'didYoga',
      'breakfast',
      'homework',
      'assignmentCompletion',
      'helpfulAtHome',
      'respectfulToElders',
    ];
    for (final key in required) {
      if (!_values.containsKey(key)) return _labelFor(key);
    }
    return null;
  }

  String _labelFor(String key) => switch (key) {
    'brushedTeeth' => 'Brushed teeth',
    'didYoga' => 'Did do Yoga?',
    'breakfast' => 'Breakfast',
    'homework' => 'Homework',
    'assignmentCompletion' => 'Completion of Assignments',
    'helpfulAtHome' => 'Helpful at home',
    _ => 'Respectful to elders at home',
  };

  void _reset() {
    setState(() {
      _wentToBedAt = '';
      _gotUpAt = '';
      _values.clear();
      _remarkController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.readOnly
        ? 'Parent\'s Observations'
        : 'Parent\'s Observations';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        toolbarHeight: 43,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
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
                    'Parent\'s Observations for ${widget.student.admissionNo} ${widget.student.name}'
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
                  const SizedBox(height: 10),
                  _timeField('My Child went to bed at', _wentToBedAt, true),
                  _timeField('My Child got up at', _gotUpAt, false),
                  _choiceField('Brushed teeth', 'brushedTeeth', const {
                    'once': 'Once',
                    'twice': 'Twice',
                  }),
                  _choiceField('Did do Yoga?', 'didYoga', const {
                    'yes': 'Yes',
                    'no': 'No',
                  }),
                  _choiceField('Breakfast', 'breakfast', const {
                    'had_breakfast': 'Had breakfast',
                    'refused': 'Refused',
                  }),
                  _choiceField('Homework', 'homework', const {
                    'completed': 'Completed',
                    'did_not_do': 'Did not do',
                  }),
                  _choiceField(
                    'Completion of Assignments',
                    'assignmentCompletion',
                    const {
                      'worked_independently': 'Worked Independently',
                      'did_under_supervision': 'Did under Supervision',
                      'failed_to_do': 'Failed to do the work',
                    },
                  ),
                  _choiceField('Helpful at home', 'helpfulAtHome', const {
                    'very_much': 'Very much',
                    'sometimes': 'Sometimes',
                    'never': 'Never',
                  }),
                  _choiceField(
                    'Respectful to elders at home',
                    'respectfulToElders',
                    const {
                      'very_much': 'Very much',
                      'sometimes': 'Sometimes',
                      'never': 'Never',
                    },
                  ),
                  const Text('Parents Remark', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _remarkController,
                    enabled: !widget.readOnly,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 12),
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

  Widget _timeField(String label, String value, bool bedtime) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 3),
        InkWell(
          onTap: widget.readOnly ? null : () => _chooseTime(bedtime),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              suffixIcon: Icon(Icons.access_time, size: 15),
            ),
            child: Text(
              value.isEmpty ? '--:-- --' : value,
              style: TextStyle(
                fontSize: 11,
                color: value.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _choiceField(String label, String key, Map<String, String> options) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: options.entries
                  .map(
                    (entry) => SizedBox(
                      width: 160,
                      child: RadioListTile<String>(
                        value: entry.key,
                        groupValue: _values[key],
                        onChanged: widget.readOnly
                            ? null
                            : (value) => setState(() => _values[key] = value!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        title: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

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
