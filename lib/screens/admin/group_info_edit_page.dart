import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/group_state_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupInfoEditPage extends StatefulWidget {
  const GroupInfoEditPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupInfoEditPage> createState() => _GroupInfoEditPageState();
}

class _GroupInfoEditPageState extends State<GroupInfoEditPage> {
  final GroupService _groupService = GroupService();
  final GroupStateService _stateService = GroupStateService.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _statusController;
  late final TextEditingController _yearController;
  late String _groupId;
  String? _selectedImagePath;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _saving = false;
  List<GroupStudent> _students = <GroupStudent>[];
  List<GroupTeacher> _teachers = <GroupTeacher>[];
  GroupSettings _settings = GroupSettings(groupId: '');

  @override
  void initState() {
    super.initState();
    _groupId = widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;
    _nameController = TextEditingController(text: widget.group.name);
    _idController = TextEditingController(text: widget.group.id);
    _typeController = TextEditingController(text: widget.group.type);
    _descriptionController = TextEditingController(text: widget.group.description);
    _statusController = TextEditingController(text: widget.group.status);
    _yearController = TextEditingController(text: widget.group.year);
    _loadGroupData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _statusController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    try {
      await _stateService.initialize();
      final stored = _stateService.ensureStateForGroup(_groupId, seed: widget.group).group;
      final settings = await _stateService.getGroupSettings(_groupId);
      final students = await _stateService.getGroupStudents(_groupId);
      final teachers = await _stateService.getGroupTeachers(_groupId);
      final imageUrl = _stateService.ensureStateForGroup(_groupId, seed: widget.group).imageUrl;
      if (!mounted) return;
      setState(() {
        _currentImageUrl = imageUrl;
        _students = students;
        _teachers = teachers;
        _settings = settings;
        _nameController.text = stored.name;
        _idController.text = stored.id;
        _typeController.text = stored.type;
        _descriptionController.text = stored.description;
        _statusController.text = stored.status;
        _yearController.text = stored.year;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result.isEmpty) return;

    final file = result.first;
    final path = file.path;
    if (path == null || path.isEmpty) return;

    setState(() {
      _selectedImagePath = path;
      _currentImageUrl = null;
    });
  }

  Future<void> _removeImage() async {
    await _stateService.uploadGroupImage(_groupId, null);
    setState(() {
      _selectedImagePath = null;
      _currentImageUrl = null;
    });
  }

  String get _effectiveGroupName => _nameController.text.trim();

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final groupId = _idController.text.trim();
    final type = _typeController.text.trim();
    final description = _descriptionController.text.trim();
    final status = _statusController.text.trim();
    final year = _yearController.text.trim();

    if (name.isEmpty || groupId.isEmpty || year.isEmpty) {
      _showSnackBar('Please complete the required group fields.');
      return;
    }

    setState(() => _saving = true);

    try {
      final updatePayload = {
        'id': groupId,
        'name': name,
        'type': type.isEmpty ? 'Other' : type,
        'description': description.isEmpty ? name : description,
        'status': status.isEmpty ? 'Active' : status,
        'year': year,
      };

      if (widget.group.databaseId.isNotEmpty) {
        await _groupService.updateGroup(
          widget.group.databaseId,
          name: name,
          id: groupId,
          type: type.isEmpty ? 'Other' : type,
          description: description.isEmpty ? name : description,
          status: status.isEmpty ? 'Active' : status,
          year: year,
        );
      }

      await _stateService.updateGroup(_groupId, updatePayload);
      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        await _stateService.uploadGroupImage(groupId, _selectedImagePath);
      }
      for (final student in _students) {
        await _stateService.addStudent(groupId, student);
      }
      for (final teacher in _teachers) {
        await _stateService.assignTeacher(groupId, teacher.teacherId, {
          'id': teacher.id,
          'name': teacher.name,
          'subject': teacher.subject,
          'role': teacher.role,
        });
      }
      await _stateService.saveGroupSettings(
        groupId,
        GroupSettings(
          groupId: groupId,
          section: _settings.section,
          communicationPermissions: _settings.communicationPermissions,
          studentPermissions: _settings.studentPermissions,
          teacherPermissions: _settings.teacherPermissions,
          description: description,
          status: status,
          academicYear: year,
        ),
      );

      if (!mounted) return;
      _showSnackBar('Group information updated successfully.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _selectedImagePath != null
        ? Image.file(
            File(_selectedImagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 150,
          )
        : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
            ? Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
                errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
              )
            : Container(
                height: 150,
                color: const Color(0xffe9eef7),
                child: const Icon(Icons.image, size: 48, color: Color(0xff5a6f92)),
              ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: AppColors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Group Info Edit',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _effectiveGroupName.isNotEmpty ? _effectiveGroupName : 'Group',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _groupId,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Group Image',
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageWidget,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Image'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change Image'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Image'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Group Details',
                    child: Column(
                      children: [
                        _FieldRow(label: 'Group/Class Name', controller: _nameController),
                        _FieldRow(label: 'Group ID', controller: _idController, readOnly: true),
                        _FieldRow(label: 'Type', controller: _typeController),
                        _FieldRow(label: 'Description', controller: _descriptionController, maxLines: 3),
                        _FieldRow(label: 'Status', controller: _statusController),
                        _FieldRow(label: 'Academic Year', controller: _yearController, keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Students',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Students')),
                            TextButton.icon(
                              onPressed: () {
                                final student = GroupStudent(
                                  id: 'student-${DateTime.now().millisecondsSinceEpoch}',
                                  groupId: _groupId,
                                  name: 'New Student',
                                  admissionNo: 'ADM-${_students.length + 1}',
                                  section: 'A',
                                  details: 'Add student details here',
                                  contact: '',
                                  email: '',
                                );
                                setState(() => _students = [..._students, student]);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Student'),
                            ),
                          ],
                        ),
                        ..._students.map((student) => _StudentTile(student: student, onDelete: () => setState(() => _students.remove(student))))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Teachers / Staff',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Teachers / Staff')),
                            TextButton.icon(
                              onPressed: () {
                                final teacher = GroupTeacher(
                                  id: 'teacher-${DateTime.now().millisecondsSinceEpoch}',
                                  groupId: _groupId,
                                  teacherId: 'teacher-${DateTime.now().millisecondsSinceEpoch}',
                                  name: 'New Teacher',
                                  subject: 'Mathematics',
                                  role: 'Class Teacher',
                                  details: 'Add teacher details here',
                                  contact: '',
                                  email: '',
                                );
                                setState(() => _teachers = [..._teachers, teacher]);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Teacher'),
                            ),
                          ],
                        ),
                        ..._teachers.map((teacher) => _TeacherTile(teacher: teacher, onDelete: () => setState(() => _teachers.remove(teacher))))
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Group Settings',
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          SwitchListTile(
                          value: _settings.communicationPermissions,
                          onChanged: (value) => setState(() => _settings = GroupSettings(
                            groupId: _groupId,
                            section: _settings.section,
                            communicationPermissions: value,
                            studentPermissions: _settings.studentPermissions,
                            teacherPermissions: _settings.teacherPermissions,
                            description: _settings.description,
                            status: _settings.status,
                            academicYear: _settings.academicYear,
                          )),
                          title: const Text('Communication permissions'),
                          ),
                          SwitchListTile(
                          value: _settings.studentPermissions,
                          onChanged: (value) => setState(() => _settings = GroupSettings(
                            groupId: _groupId,
                            section: _settings.section,
                            communicationPermissions: _settings.communicationPermissions,
                            studentPermissions: value,
                            teacherPermissions: _settings.teacherPermissions,
                            description: _settings.description,
                            status: _settings.status,
                            academicYear: _settings.academicYear,
                          )),
                          title: const Text('Student permissions'),
                          ),
                          SwitchListTile(
                          value: _settings.teacherPermissions,
                          onChanged: (value) => setState(() => _settings = GroupSettings(
                            groupId: _groupId,
                            section: _settings.section,
                            communicationPermissions: _settings.communicationPermissions,
                            studentPermissions: _settings.studentPermissions,
                            teacherPermissions: value,
                            description: _settings.description,
                            status: _settings.status,
                            academicYear: _settings.academicYear,
                          )),
                          title: const Text('Teacher permissions'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueButton,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.blueButton,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatefulWidget {
  const _StudentTile({required this.student, required this.onDelete});

  final GroupStudent student;
  final VoidCallback onDelete;

  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  late final TextEditingController _nameController;
  late final TextEditingController _admissionController;
  late final TextEditingController _sectionController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _admissionController = TextEditingController(text: widget.student.admissionNo);
    _sectionController = TextEditingController(text: widget.student.section);
    _contactController = TextEditingController(text: widget.student.contact);
    _emailController = TextEditingController(text: widget.student.email);
    _detailsController = TextEditingController(text: widget.student.details);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionController.dispose();
    _sectionController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;

    final path = result.first.path;
    if (path == null || path.isEmpty) return;

    setState(() {
      widget.student.imageUrl = path;
      widget.student.name = _nameController.text.trim();
      widget.student.admissionNo = _admissionController.text.trim();
      widget.student.section = _sectionController.text.trim();
      widget.student.contact = _contactController.text.trim();
      widget.student.email = _emailController.text.trim();
      widget.student.details = _detailsController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xffe8edf8),
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: AppColors.blueButton.withValues(alpha: 0.2)),
                  ),
                  child: widget.student.imageUrl != null && widget.student.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: Image.file(
                            File(widget.student.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Color(0xff4a5a7a), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Name'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      onChanged: (value) => widget.student.name = value,
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _admissionController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Admission No'),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.student.admissionNo = value,
                    ),
                    TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Section'),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.student.section = value,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Contact', isDense: true),
            onChanged: (value) => widget.student.contact = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', isDense: true),
            onChanged: (value) => widget.student.email = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Details', isDense: true),
            onChanged: (value) => widget.student.details = value,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Image'),
              ),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherTile extends StatefulWidget {
  const _TeacherTile({required this.teacher, required this.onDelete});

  final GroupTeacher teacher;
  final VoidCallback onDelete;

  @override
  State<_TeacherTile> createState() => _TeacherTileState();
}

class _TeacherTileState extends State<_TeacherTile> {
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _roleController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher.name);
    _subjectController = TextEditingController(text: widget.teacher.subject);
    _roleController = TextEditingController(text: widget.teacher.role);
    _contactController = TextEditingController(text: widget.teacher.contact);
    _emailController = TextEditingController(text: widget.teacher.email);
    _detailsController = TextEditingController(text: widget.teacher.details);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _roleController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;

    final path = result.first.path;
    if (path == null || path.isEmpty) return;

    setState(() {
      widget.teacher.imageUrl = path;
      widget.teacher.name = _nameController.text.trim();
      widget.teacher.subject = _subjectController.text.trim();
      widget.teacher.role = _roleController.text.trim();
      widget.teacher.contact = _contactController.text.trim();
      widget.teacher.email = _emailController.text.trim();
      widget.teacher.details = _detailsController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xffe8edf8),
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: AppColors.blueButton.withValues(alpha: 0.2)),
                  ),
                  child: widget.teacher.imageUrl != null && widget.teacher.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: Image.file(
                            File(widget.teacher.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Color(0xff4a5a7a), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Name'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      onChanged: (value) => widget.teacher.name = value,
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Subject'),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.teacher.subject = value,
                    ),
                    TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Role'),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.teacher.role = value,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: 'Contact', isDense: true),
            onChanged: (value) => widget.teacher.contact = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', isDense: true),
            onChanged: (value) => widget.teacher.email = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Details', isDense: true),
            onChanged: (value) => widget.teacher.details = value,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Image'),
              ),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
