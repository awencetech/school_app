import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ListStudentsPage extends StatefulWidget {
  const ListStudentsPage({super.key});

  @override
  State<ListStudentsPage> createState() => _ListStudentsPageState();
}

class _ListStudentsPageState extends State<ListStudentsPage> {
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();
  List<StudentRecord> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final students = await _studentService.getStudents();
      if (!mounted) return;
      setState(() => _students = students);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to load students.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StudentRecord> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.className.toLowerCase().contains(query) ||
          student.studentId.toLowerCase().contains(query) ||
          student.parentName.toLowerCase().contains(query);
    }).toList();
  }

  String _initials(StudentRecord student) {
    final words = student.name.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0]).join();
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Student List'),
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
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Student List',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search Student here',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPager(),
            if (_isLoading)
              const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(_errorMessage!)),
              )
            else if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No students found.')),
              )
            else
              ...students.map(_buildStudentCard),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      ),
    );
  }

  Widget _buildPager() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Prev', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Next']
            .map((label) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: label == '1' ? AppColors.blueButton : AppColors.primaryText,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStudentCard(StudentRecord student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Class: ${student.className}', style: const TextStyle(fontSize: 9)),
                    if (student.section.isNotEmpty) Text('Section: ${student.section}', style: const TextStyle(fontSize: 9)),
                    Text('Student ID: ${student.studentId}', style: const TextStyle(fontSize: 9)),
                    if (student.admissionNumber.isNotEmpty) Text('Admission No: ${student.admissionNumber}', style: const TextStyle(fontSize: 9)),
                    const SizedBox(height: 3),
                    if (student.parentName.isNotEmpty) _detail('Parent Name', student.parentName),
                    if (student.about.isNotEmpty) _detail('About', student.about),
                    if (student.hobbies.isNotEmpty) _detail('Hobbies & Interest', student.hobbies),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StudentImage(url: student.imageUrl, initials: _initials(student)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _compactAction(Icons.edit_outlined, 'Goto', () {
                Navigator.of(context).pushNamed(
                  AppRoutes.adminStudentMenu,
                  arguments: student,
                );
              }),
              _compactAction(Icons.info_outline, 'Info', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _compactAction(IconData icon, String label, [VoidCallback? onPressed]) {
    return TextButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 13, color: Colors.grey),
      label: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _StudentImage extends StatelessWidget {
  const _StudentImage({required this.url, required this.initials});

  final String url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.blueButton,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10)),
      );
    }
    return SizedBox(
      width: 56,
      height: 56,
      child: CircleAvatar(
        backgroundImage: NetworkImage(url),
        backgroundColor: AppColors.blueButton,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }
}
