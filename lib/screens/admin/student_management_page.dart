import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final StudentService _studentService = StudentService();
  bool _showStudentForm = false;
  bool _loading = true;
  bool _submittingStudent = false;
  String? _error;
  int? _editingStudentIndex;
  String? _selectedClass;
  String? _selectedSection;
  final List<StudentRecord> _students = [];
  final Map<String, TextEditingController> _controllers = {
    'Name': TextEditingController(),
    'Class': TextEditingController(),
    'Section': TextEditingController(),
    'Student ID': TextEditingController(),
    'Admission Number': TextEditingController(),
    'Parent Name': TextEditingController(),
    'Mobile Number': TextEditingController(),
    'Address': TextEditingController(),
    'About': TextEditingController(),
    'Hobbies & Interest': TextEditingController(),
    'Role': TextEditingController(),
  };
  Uint8List? _imageBytes;
  String _imageName = '';

  static const List<String> _classOptions = ['6th', '7th', '8th', '9th', '10th', '11th', '12th'];
  static const List<String> _sectionOptions = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final students = await _studentService.getStudents();
      if (!mounted) return;
      setState(() => _students
        ..clear()
        ..addAll(students));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final file = result.first;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  void _resetStudentForm() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _selectedClass = null;
    _selectedSection = null;
    _imageBytes = null;
    _imageName = '';
  }

  Future<void> _generateNextStudentId() async {
    try {
      final nextStudentId = await _studentService.getNextStudentId();
      if (!mounted) return;
      _controllers['Student ID']!.text = nextStudentId;
    } catch (_) {
      if (!mounted) return;
      final existingIds = _students
          .map((student) => student.studentId)
          .where((value) => RegExp(r'^STU\d+$', caseSensitive: false).hasMatch(value))
          .toList();
      var maxNumber = 0;
      for (final id in existingIds) {
        final match = RegExp(r'^STU(\d+)$', caseSensitive: false).firstMatch(id);
        if (match == null) continue;
        final parsed = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (parsed > maxNumber) maxNumber = parsed;
      }
      _controllers['Student ID']!.text = 'STU${(maxNumber + 1).toString().padLeft(4, '0')}';
    }
  }

  Future<void> _openAddStudentForm() async {
    setState(() {
      _editingStudentIndex = null;
      _showStudentForm = true;
      _resetStudentForm();
    });
    await _generateNextStudentId();
  }

  void _editStudent(StudentRecord student) {
    final index = _students.indexOf(student);
    if (index < 0) return;

    _controllers['Name']!.text = student.name;
    _controllers['Class']!.text = student.className;
    _controllers['Section']!.text = student.section;
    _controllers['Student ID']!.text = student.studentId;
    _controllers['Admission Number']!.text = student.admissionNumber;
    _controllers['Parent Name']!.text = student.parentName;
    _controllers['Mobile Number']!.text = student.mobileNumber;
    _controllers['Address']!.text = student.address;
    _controllers['About']!.text = student.about;
    _controllers['Hobbies & Interest']!.text = student.hobbies;
    _controllers['Role']!.text = student.role;
    _selectedClass = _classOptions.contains(student.className) ? student.className : null;
    _selectedSection = _sectionOptions.contains(student.section) ? student.section : null;
    _imageBytes = null;
    _imageName = '';

    setState(() {
      _editingStudentIndex = index;
      _showStudentForm = true;
    });
  }

  Future<void> _deleteStudent(StudentRecord student) async {
    if (student.id == null || student.id!.isEmpty) {
      setState(() => _students.remove(student));
      return;
    }

    try {
      await _studentService.deleteStudent(student.id!);
      if (!mounted) return;
      setState(() => _students.remove(student));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _saveStudent() async {
    if (_submittingStudent || !_formKey.currentState!.validate()) return;

    final studentId = _controllers['Student ID']!.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID is required.')),
      );
      return;
    }

    setState(() => _submittingStudent = true);

    final imageUrl = _imageBytes != null ? 'data:image/png;base64,${base64Encode(_imageBytes!)}' : '';

    final student = StudentRecord(
      id: _editingStudentIndex != null && _editingStudentIndex! < _students.length ? _students[_editingStudentIndex!].id : null,
      name: _controllers['Name']!.text.trim(),
      className: _controllers['Class']!.text.trim(),
      section: _controllers['Section']!.text.trim(),
      studentId: studentId,
      admissionNumber: _controllers['Admission Number']!.text.trim(),
      parentName: _controllers['Parent Name']!.text.trim(),
      mobileNumber: _controllers['Mobile Number']!.text.trim(),
      address: _controllers['Address']!.text.trim(),
      about: _controllers['About']!.text.trim(),
      hobbies: _controllers['Hobbies & Interest']!.text.trim(),
      role: _controllers['Role']!.text.trim(),
      imageUrl: imageUrl,
    );

    try {
      final saved = _editingStudentIndex == null
          ? await _studentService.createStudent(student)
          : await _studentService.updateStudent(student);

      if (!mounted) return;
      setState(() {
        if (_editingStudentIndex == null) {
          _students.insert(0, saved);
        } else {
          _students[_editingStudentIndex!] = saved;
        }
        _editingStudentIndex = null;
        _showStudentForm = false;
        _resetStudentForm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('already assigned') || message.contains('already exists')) {
        await _generateNextStudentId();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student ID already exists. A new Student ID has been generated.')),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isNotEmpty ? message : 'Unable to add student. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submittingStudent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      'Name',
      'Class',
      'Section',
      'Student ID',
      'Admission Number',
      'Parent Name',
      'Mobile Number',
      'Address',
      'About',
      'Hobbies & Interest',
      'Role',
    ];

    final inputDecoration = const InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminOtherOptions, (route) => false);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _openAddStudentForm,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add Student'),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_showStudentForm)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  for (final field in fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: field == 'Class'
                          ? DropdownButtonFormField<String>(
                              initialValue: _selectedClass,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              hint: const Text('Class'),
                              decoration: inputDecoration.copyWith(hintText: 'Class'),
                              validator: (value) => (value == null || value.isEmpty) ? 'This field is required.' : null,
                              items: _classOptions
                                  .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedClass = value);
                                _controllers['Class']!.text = value ?? '';
                              },
                            )
                          : field == 'Section'
                              ? DropdownButtonFormField<String>(
                                  initialValue: _selectedSection,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  hint: const Text('Section'),
                                  decoration: inputDecoration.copyWith(hintText: 'Section'),
                                  validator: (value) => (value == null || value.isEmpty) ? 'This field is required.' : null,
                                  items: _sectionOptions
                                      .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedSection = value);
                                    _controllers['Section']!.text = value ?? '';
                                  },
                                )
                              : field == 'Student ID'
                                  ? TextFormField(
                                      controller: _controllers[field],
                                      enabled: false,
                                      showCursor: false,
                                      enableInteractiveSelection: false,
                                      validator: _required,
                                      decoration: inputDecoration.copyWith(hintText: 'Student ID'),
                                    )
                                  : TextFormField(
                                      controller: _controllers[field],
                                      validator: ['About', 'Hobbies & Interest', 'Address'].contains(field) ? null : _required,
                                      maxLines: ['About', 'Hobbies & Interest', 'Address'].contains(field) ? 4 : 1,
                                      decoration: inputDecoration.copyWith(labelText: field),
                                    ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_imageBytes != null ? 'Replace Image' : 'Upload Image'),
                        ),
                      ),
                      if (_imageBytes != null)
                        IconButton(
                          onPressed: () => setState(() => _imageBytes = null),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove image',
                        ),
                    ],
                  ),
                  if (_imageBytes != null) ...[
                    const SizedBox(height: 12),
                    if (_imageName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _imageName,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    SizedBox(
                      height: 140,
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submittingStudent ? null : _saveStudent,
                    child: _submittingStudent
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Student'),
                  ),
                ],
              ),
            )
          else if (_students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No student details added yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            Column(
              children: _students.map((student) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (student.imageUrl.isEmpty)
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF7A7A7A),
                        child: const Icon(Icons.person_outline, color: Colors.white),
                      )
                    else
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(student.imageUrl),
                        backgroundColor: const Color(0xFF7A7A7A),
                        child: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name.isEmpty ? 'Student' : student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          if (student.className.isNotEmpty) Text(student.className, style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
                          if (student.studentId.isNotEmpty) Text(student.studentId, style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
                          if (student.parentName.isNotEmpty) Text(student.parentName, style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: () => _editStudent(student),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () => _deleteStudent(student),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
      bottomNavigationBar: _AdminStudentNav(),
    );
  }
}

class _AdminStudentNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          } else if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          }
        },
      );
}
