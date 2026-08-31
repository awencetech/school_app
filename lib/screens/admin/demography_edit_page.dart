import 'package:flutter/material.dart';

import '../../models/demography.dart';
import '../../services/demography_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class DemographyEditPage extends StatefulWidget {
  const DemographyEditPage({super.key});

  @override
  State<DemographyEditPage> createState() => _DemographyEditPageState();
}

class _DemographyEditPageState extends State<DemographyEditPage> {
  final DemographyService _service = DemographyService();
  bool _loading = true;
  List<Demography> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadDemographies();
  }

  Future<void> _loadDemographies() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final items = await _service.getDemographies();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load demography records.')),
      );
    }
  }

  Future<void> _openForm({Demography? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DemographyFormDialog(existing: item),
    );

    if (result == true) {
      await _loadDemographies();
    }
  }

  Future<void> _deleteDemography(Demography item) async {
    if (item.id == null || item.id!.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Demography?'),
        content: const Text('This will remove the demography record permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDemography(item.id!);
      if (!mounted) return;
      setState(() => _items.removeWhere((entry) => entry.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demography deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete demography.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Demography Edit'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Demography',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('+ Add Demography'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _items.isEmpty
                          ? const Center(
                              child: Text(
                                'No demography records available.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.groupName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Teachers: ${item.teachers.length}'),
                                        Text('Other Teachers: ${item.otherTeachers.length}'),
                                        Text('Students: ${item.students.length}'),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _openForm(item: item),
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _deleteDemography(item),
                                                icon: const Icon(Icons.delete_outline),
                                                label: const Text('Delete'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _DemographyFormDialog extends StatefulWidget {
  const _DemographyFormDialog({this.existing});

  final Demography? existing;

  @override
  State<_DemographyFormDialog> createState() => _DemographyFormDialogState();
}

class _DemographyFormDialogState extends State<_DemographyFormDialog> {
  final DemographyService _service = DemographyService();
  final TextEditingController _groupNameController = TextEditingController();
  final List<_TeacherEntry> _teachers = [];
  final List<_TeacherEntry> _otherTeachers = [];
  final List<_TeacherEntry> _students = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _groupNameController.text = item?.groupName ?? '';
    _teachers.addAll(
      (item?.teachers ?? const []).map(
        (member) => _TeacherEntry(nameController: TextEditingController(text: member.name), idController: TextEditingController(text: member.staffId)),
      ),
    );
    _otherTeachers.addAll(
      (item?.otherTeachers ?? const []).map(
        (member) => _TeacherEntry(nameController: TextEditingController(text: member.name), idController: TextEditingController(text: member.staffId)),
      ),
    );
    _students.addAll(
      (item?.students ?? const []).map(
        (member) => _TeacherEntry(nameController: TextEditingController(text: member.name), idController: TextEditingController(text: member.studentId)),
      ),
    );
    if (_students.isEmpty) {
      _students.add(_TeacherEntry(nameController: TextEditingController(), idController: TextEditingController()));
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final teacher in _teachers) {
      teacher.dispose();
    }
    for (final teacher in _otherTeachers) {
      teacher.dispose();
    }
    for (final student in _students) {
      student.dispose();
    }
    super.dispose();
  }

  void _addTeacher(List<_TeacherEntry> list) {
    setState(() => list.add(_TeacherEntry(nameController: TextEditingController(), idController: TextEditingController())));
  }

  void _removeTeacher(List<_TeacherEntry> list, int index) {
    if (list.length <= 1 && list == _students) return;
    setState(() {
      list[index].dispose();
      list.removeAt(index);
    });
  }

  Future<void> _save() async {
    final groupName = _groupNameController.text.trim();
    final validStudents = _students.where((entry) => entry.nameController.text.trim().isNotEmpty).toList();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Name is required.')),
      );
      return;
    }

    if (validStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one student is required.')),
      );
      return;
    }

    final payload = Demography(
      id: widget.existing?.id,
      groupId: widget.existing?.groupId ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      groupName: groupName,
      teachers: _teachers
          .where((entry) => entry.nameController.text.trim().isNotEmpty)
          .map(
            (entry) => DemographyMember(
              name: entry.nameController.text.trim(),
              staffId: entry.idController.text.trim(),
            ),
          )
          .toList(),
      otherTeachers: _otherTeachers
          .where((entry) => entry.nameController.text.trim().isNotEmpty)
          .map(
            (entry) => DemographyMember(
              name: entry.nameController.text.trim(),
              staffId: entry.idController.text.trim(),
            ),
          )
          .toList(),
      students: validStudents
          .map(
            (entry) => DemographyMember(
              name: entry.nameController.text.trim(),
              studentId: entry.idController.text.trim(),
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    try {
      if (widget.existing?.id != null && widget.existing!.id!.isNotEmpty) {
        await _service.updateDemography(widget.existing!.id!, payload);
      } else {
        await _service.createDemography(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demography saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Demography',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Teachers', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => _addTeacher(_teachers),
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add Teacher'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_teachers.length, (index) {
                  final entry = _teachers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: entry.nameController,
                                decoration: const InputDecoration(labelText: 'Teacher Name', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: entry.idController,
                                decoration: const InputDecoration(labelText: 'Staff ID (Optional)', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeTeacher(_teachers, index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Other Teachers', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => _addTeacher(_otherTeachers),
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add Other Teacher'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_otherTeachers.length, (index) {
                  final entry = _otherTeachers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: entry.nameController,
                                decoration: const InputDecoration(labelText: 'Teacher Name', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: entry.idController,
                                decoration: const InputDecoration(labelText: 'Staff ID (Optional)', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeTeacher(_otherTeachers, index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Students', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => _addTeacher(_students),
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add Student'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_students.length, (index) {
                  final entry = _students[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: entry.nameController,
                                decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: entry.idController,
                                decoration: const InputDecoration(labelText: 'Student ID (Optional)', border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                        ),
                        if (_students.length > 1)
                          IconButton(
                            onPressed: () => _removeTeacher(_students, index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving...' : 'Save Demography'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherEntry {
  _TeacherEntry({required this.nameController, required this.idController});

  final TextEditingController nameController;
  final TextEditingController idController;

  void dispose() {
    nameController.dispose();
    idController.dispose();
  }
}
