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
  String? _error;
  int? _editingStudentIndex;
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
    _imageBytes = null;
    _imageName = '';
  }

  void _openAddStudentForm() {
    setState(() {
      _editingStudentIndex = null;
      _showStudentForm = true;
      _resetStudentForm();
    });
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
    if (!_formKey.currentState!.validate()) return;

    final student = StudentRecord(
      id: _editingStudentIndex != null && _editingStudentIndex! < _students.length ? _students[_editingStudentIndex!].id : null,
      name: _controllers['Name']!.text.trim(),
      className: _controllers['Class']!.text.trim(),
      section: _controllers['Section']!.text.trim(),
      studentId: _controllers['Student ID']!.text.trim(),
      admissionNumber: _controllers['Admission Number']!.text.trim(),
      parentName: _controllers['Parent Name']!.text.trim(),
      mobileNumber: _controllers['Mobile Number']!.text.trim(),
      address: _controllers['Address']!.text.trim(),
      about: _controllers['About']!.text.trim(),
      hobbies: _controllers['Hobbies & Interest']!.text.trim(),
      role: _controllers['Role']!.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
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

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Student')),
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
                      child: TextFormField(
                        controller: _controllers[field],
                        validator: ['About', 'Hobbies & Interest', 'Address'].contains(field) ? null : _required,
                        maxLines: ['About', 'Hobbies & Interest', 'Address'].contains(field) ? 4 : 1,
                        decoration: InputDecoration(
                          labelText: field,
                          border: const OutlineInputBorder(),
                        ),
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
                    onPressed: _saveStudent,
                    child: const Text('Save Student'),
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
                    CircleAvatar(
                      radius: 24,
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
