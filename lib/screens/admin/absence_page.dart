import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/class_timetable.dart';
import '../../models/employee_attendance.dart';
import '../../models/group.dart';
import '../../services/app_state.dart';
import '../../services/class_timetable_service.dart';
import '../../services/employee_attendance_service.dart';
import '../../services/group_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class AbsencePage extends StatefulWidget {
  const AbsencePage({super.key, required this.group});

  final Group group;

  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends State<AbsencePage> {
  int _selectedTab = 0;
  String? _message;
  bool _messageIsError = false;

  Future<void> _showAttendanceForm() async {
    final employeeId = context.read<AppState>().currentUserId?.trim() ?? '';
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AttendanceDialog(
        employeeId: employeeId,
        group: widget.group,
      ),
    );
    if (!mounted || saved != true) return;
    setState(() {
      _message = 'Attendance recorded successfully.';
      _messageIsError = false;
    });
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
        title: const Text('Today in Class', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(
            height: 27,
            child: Padding(
              padding: EdgeInsets.only(left: 7, top: 7),
              child: Text('Absence', style: TextStyle(fontSize: 11, color: Color(0xff1d3557))),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
          SizedBox(
            height: 31,
            child: Row(children: [
              _Tab(label: 'Take Attendance', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
              _Tab(label: 'Analytics', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
            ]),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
          if (_selectedTab == 0) ...[
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 7, right: 8),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 10,
                    color: _messageIsError ? Colors.red : Colors.green,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 7),
              child: SizedBox(
                width: 65,
                height: 21,
                child: ElevatedButton(
                  onPressed: _showAttendanceForm,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff087ff5), foregroundColor: Colors.white, padding: EdgeInsets.zero, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))),
                  child: const Text('Take Attendance', style: TextStyle(fontSize: 7)),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(left: 3, top: 10), child: Text('No Attendance Taken Today', style: TextStyle(fontSize: 10, color: Color(0xff222222)))),
            const Padding(padding: EdgeInsets.only(left: 3, top: 10), child: Text('No Student Applied for Leave Today', style: TextStyle(fontSize: 10, color: Color(0xff222222)))),
          ] else
            const Padding(padding: EdgeInsets.only(left: 3, top: 12), child: Text('No Data available', style: TextStyle(fontSize: 10, color: Color(0xff222222))),),
          const Expanded(child: SizedBox()),
        ]),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: label == 'Take Attendance' ? 97 : 66,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, border: selected ? Border.all(color: const Color(0xffd9e2ec)) : null),
        child: Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xff333333) : const Color(0xff0066cc))),
      ),
    );
  }
}

class _AttendanceDialog extends StatefulWidget {
  const _AttendanceDialog({required this.employeeId, required this.group});

  final String employeeId;
  final Group group;

  @override
  State<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  final _service = EmployeeAttendanceService();
  final _groupService = GroupService();
  final _timetableService = ClassTimetableService();
  DateTime _date = DateTime.now();
  List<_SubjectOption> _subjects = const [];
  String? _selectedSubjectId;
  String? _selectedSubject;
  String? _selectedClassType;
  List<String> _classTypes = const [];
  String _resolvedEmployeeId = '';
  bool _loadingOptions = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final groupId = widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;
    try {
      final results = await Future.wait([
        _groupService.getGroupDetails(
          widget.group.databaseId.isNotEmpty ? widget.group.databaseId : groupId,
        ),
        _timetableService.getForGroup(groupId),
        _groupService.getGroups(refresh: true),
      ]);
      final groupDetails = results[0] as GroupRemoteData;
      final timetable = results[1] as List<ClassTimetableEntry>;
      final groups = results[2] as List<Group>;
      final assignedTeacherId = groupDetails.teachers
          .map((teacher) => teacher.teacherId.trim())
          .firstWhere((id) => id.isNotEmpty, orElse: () => '');
      _resolvedEmployeeId = widget.employeeId.isNotEmpty
          ? widget.employeeId
          : assignedTeacherId;
      if (assignedTeacherId.isNotEmpty && widget.employeeId.isNotEmpty) {
        _resolvedEmployeeId = assignedTeacherId;
      }
      final options = <String, _SubjectOption>{};
      for (final entry in timetable) {
        if (entry.subject.trim().isNotEmpty) {
          options[entry.id.isNotEmpty ? entry.id : entry.subject] = _SubjectOption(
            id: entry.id.isNotEmpty ? entry.id : entry.subject,
            label: entry.subject.trim(),
          );
        }
      }
      for (final teacher in groupDetails.teachers) {
        if (teacher.subject.trim().isNotEmpty) {
          options.putIfAbsent(
            teacher.subject.trim(),
            () => _SubjectOption(id: teacher.subject.trim(), label: teacher.subject.trim()),
          );
        }
      }
      final classTypes = <String>{
        for (final item in groups)
          if (item.type.trim().isNotEmpty) item.type.trim(),
        if (groupDetails.group.type.trim().isNotEmpty)
          groupDetails.group.type.trim(),
      }.toList()..sort();
      if (!mounted) return;
      setState(() {
        _subjects = options.values.toList();
        _classTypes = classTypes;
        _selectedClassType = classTypes.contains(groupDetails.group.type.trim())
            ? groupDetails.group.type.trim()
            : null;
        _loadingOptions = false;
        _error = _subjects.isEmpty ? 'No subjects are configured for this group.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingOptions = false;
        _error = 'Unable to load subjects for this group.';
      });
    }
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (date != null) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 34, child: Padding(padding: const EdgeInsets.only(left: 10, top: 10), child: Row(children: [const Text('Enter Attendance', style: TextStyle(fontSize: 11)), const Spacer(), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 24, height: 24), onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 15, color: Color(0xff777777)))]))),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(fontSize: 10, color: Colors.red)),
                ),
              Row(children: [
                const SizedBox(width: 38, child: Text('Subject', style: TextStyle(fontSize: 10))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 150,
                  height: 24,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    isDense: true,
                    isExpanded: true,
                    iconSize: 13,
                    style: const TextStyle(fontSize: 9, color: Color(0xff333333)),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 3), border: OutlineInputBorder()),
                    hint: Text(_loadingOptions ? 'Loading...' : 'Select subject'),
                    items: _subjects
                        .map((item) => DropdownMenuItem(value: item.id, child: Text(item.label)))
                        .toList(),
                    onChanged: _loadingOptions || _subjects.isEmpty
                        ? null
                        : (value) {
                            final option = _subjects.firstWhere((item) => item.id == value);
                            setState(() {
                              _selectedSubjectId = value;
                              _selectedSubject = option.label;
                            });
                          },
                  ),
                ),
              ]),
            const SizedBox(height: 14),
              Row(children: [
                const SizedBox(width: 38, child: Text('Class Type', style: TextStyle(fontSize: 10))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 150,
                  height: 24,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedClassType,
                    isDense: true,
                    isExpanded: true,
                    iconSize: 13,
                    style: const TextStyle(fontSize: 9, color: Color(0xff333333)),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 3), border: OutlineInputBorder()),
                    hint: const Text('Select class type'),
                    items: _classTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                    onChanged: (value) => setState(() => _selectedClassType = value),
                  ),
                ),
              ]),
            const SizedBox(height: 14),
            const Text('Attendance Date', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: TextField(
                readOnly: true,
                onTap: _chooseDate,
                controller: TextEditingController(text: dateText),
                style: const TextStyle(fontSize: 10),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  suffixIcon: Icon(Icons.calendar_today, size: 13),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 13),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 20,
                    child: ElevatedButton(
                      onPressed: _saving || _selectedSubject == null || _selectedClassType == null ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a64a), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                        child: _saving
                          ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                          : const Text('Record Attendance', style: TextStyle(fontSize: 7)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 25, 10),
              child: SizedBox(
                height: 20,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff6c757d), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                  child: const Text('Close', style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.save(
        EmployeeAttendance(
          teacherId: _resolvedEmployeeId,
          employeeId: _resolvedEmployeeId,
          employeeName: '',
          groupId: widget.group.id.isNotEmpty ? widget.group.id : widget.group.name,
          groupName: widget.group.name,
          subjectId: _selectedSubjectId ?? '',
          subject: _selectedSubject ?? '',
          classType: _selectedClassType ?? '',
          attendanceDate: '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          timeRecorded: DateTime.now(),
          attendanceType: 'OnSite',
          present: true,
          selfAttendance: true,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}

class _SubjectOption {
  const _SubjectOption({required this.id, required this.label});

  final String id;
  final String label;
}
