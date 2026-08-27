import 'package:flutter/material.dart';

import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ListTeachersPage extends StatefulWidget {
  const ListTeachersPage({super.key});

  @override
  State<ListTeachersPage> createState() => _ListTeachersPageState();
}

class _ListTeachersPageState extends State<ListTeachersPage> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();
  List<StaffInfo> _teachers = [];
  bool _includeInactive = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final teachers = await _staffService.getStaff();
      if (!mounted) return;
      setState(() => _teachers = teachers);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to load teachers.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StaffInfo> get _filteredTeachers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _teachers;
    return _teachers.where((teacher) {
      return teacher.name.toLowerCase().contains(query) ||
          teacher.designation.toLowerCase().contains(query) ||
          teacher.employeeId.toLowerCase().contains(query);
    }).toList();
  }

  String _initials(StaffInfo teacher) {
    final words = teacher.name.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0]).join();
  }

  @override
  Widget build(BuildContext context) {
    final teachers = _filteredTeachers;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('School Team'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTeachers,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'School Team',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _includeInactive = !_includeInactive),
                  icon: Icon(
                    _includeInactive ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                  ),
                  label: const Text('Include Inactive'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.blueButton,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSummaryTable(teachers),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search Staff here',
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
            const SizedBox(height: 6),
            _buildPager(),
            if (_isLoading)
              const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              _EmptyState(message: _errorMessage!)
            else if (teachers.isEmpty)
              const _EmptyState(message: 'No teachers found.')
            else
              ...teachers.map(_buildTeacherCard),
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

  Widget _buildSummaryTable(List<StaffInfo> teachers) {
    final preview = teachers.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9DDE2)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          _tableRow(const ['Super Stars(top 5)', '', ''], header: true, bold: true),
          _tableRow(const ['Id', 'Points', 'Name'], header: true, bold: true),
          if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text('No teacher data available.', style: TextStyle(fontSize: 11)),
            )
          else
            ...preview.asMap().entries.map((entry) {
              final teacher = entry.value;
              return _tableRow([
                teacher.employeeId,
                '${50 - entry.key * 5}',
                teacher.name,
              ]);
            }),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> values, {bool header = false, bool bold = false}) {
    return Container(
      color: header ? const Color(0xFFE9EDF1) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(values[0], style: TextStyle(fontSize: 9, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
          SizedBox(width: 42, child: Text(values[1], style: TextStyle(fontSize: 9, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
          Expanded(flex: 5, child: Text(values[2], style: TextStyle(fontSize: 9, fontWeight: bold ? FontWeight.w600 : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildPager() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Prev', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Next']
          .map((label) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(label, style: TextStyle(fontSize: 11, color: label == '1' ? AppColors.blueButton : AppColors.primaryText)),
              ))
          .toList(),
    );
  }

  Widget _buildTeacherCard(StaffInfo teacher) {
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
                Text(teacher.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Designation: ${teacher.designation}', style: const TextStyle(fontSize: 9)),
                Text('Employee Category: ${teacher.employeeCategory}', style: const TextStyle(fontSize: 9)),
                Text('Employee Id: ${teacher.employeeId}', style: const TextStyle(fontSize: 9)),
                const SizedBox(height: 3),
                _detail('Teaches', teacher.teaches),
                _detail('About', teacher.about),
                _detail('Hobbies & Interest', teacher.hobbiesAndInterest),
                _detail('Role', teacher.role),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StaffImage(url: teacher.imageUrl, initials: _initials(teacher)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_outline, size: 13),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    tooltip: 'Staff action',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_outlined, size: 13),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    tooltip: 'Call',
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _compactAction(Icons.info_outline, 'Goto'),
                  _compactAction(Icons.info_outline, 'Info'),
                ],
              ),
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

  Widget _compactAction(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
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

class _StaffImage extends StatelessWidget {
  const _StaffImage({required this.url, required this.initials});

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
      height: 70,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          backgroundColor: AppColors.blueButton,
          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(child: Text(message, style: const TextStyle(fontSize: 13))),
    );
  }
}
