import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class AccessManagementPage extends StatefulWidget {
  const AccessManagementPage({super.key, required this.group});

  final Group group;

  @override
  State<AccessManagementPage> createState() => _AccessManagementPageState();
}

class _AccessManagementPageState extends State<AccessManagementPage> {
  final UserService _userService = UserService();
  List<User> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _userService.getUsers(role: 'student');
      if (mounted) setState(() => _students = students);
    } catch (_) {
      // Keep the page usable when the class service is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createIds() async {
    final type = await showDialog<_AccessType>(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => _CreateIdsDialog(group: widget.group),
    );
    if (!mounted || type == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${type.label} IDs created')));
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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text(
          'Access Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 3, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${widget.group.name} - ${widget.group.year} - Class Student/Parent Access Mgmt',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff1d3557),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _createIds,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(right: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Create\nIDs',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Color(0xff087ff5)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            const Padding(
              padding: EdgeInsets.fromLTRB(3, 5, 3, 8),
              child: Text(
                'Review and Manage access to Students and their Parent\'s in class ......',
                style: TextStyle(
                  fontSize: 8,
                  fontStyle: FontStyle.italic,
                  color: Color(0xff333333),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _students.isEmpty
                  ? const Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (_, index) => _studentRow(_students[index]),
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

  Widget _studentRow(User student) {
    final label = student.userId.isNotEmpty ? student.userId : student.email;
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xffe5e5e5), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Color(0xff164f86)),
            ),
          ),
          TextButton(
            onPressed: _createIds,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(39, 20),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Create ID',
              style: TextStyle(fontSize: 7, color: Color(0xff087ff5)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccessType { student, parent }

extension on _AccessType {
  String get label => this == _AccessType.student ? 'Student' : 'Parent';
}

class _CreateIdsDialog extends StatefulWidget {
  const _CreateIdsDialog({required this.group});

  final Group group;

  @override
  State<_CreateIdsDialog> createState() => _CreateIdsDialogState();
}

class _CreateIdsDialogState extends State<_CreateIdsDialog> {
  _AccessType? _type;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        height: 194,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Column(
            children: [
              Text(
                'Select IDs to create for ${widget.group.name}',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 14, color: Color(0xff555555)),
              ),
              const SizedBox(height: 5),
              const Text(
                'This will create IDs for each student/parent, if\ndoes not exist',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Color(0xff555555)),
              ),
              const SizedBox(height: 9),
              RadioGroup<_AccessType>(
                groupValue: _type,
                onChanged: (selected) => setState(() => _type = selected),
                child: Column(
                  children: [
                    _radio(_AccessType.student),
                    _radio(_AccessType.parent),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    child: ElevatedButton(
                      onPressed: _type == null
                          ? null
                          : () => Navigator.of(context).pop(_type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff168be0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'Create Ids',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    height: 24,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffe53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radio(_AccessType value) {
    return SizedBox(
      height: 18,
      width: 90,
      child: RadioListTile<_AccessType>(
        value: value,
        dense: true,
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        title: Text(
          value.label,
          style: const TextStyle(fontSize: 11, color: Color(0xff555555)),
        ),
      ),
    );
  }
}
