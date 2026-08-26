import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import '../../utils/file_picker_helper.dart' as fp_helper;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/group_state_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

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
  Set<String> _originalStudentIds = <String>{};
  Set<String> _originalTeacherIds = <String>{};

  @override
  void initState() {
    super.initState();
    _groupId = widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;
    _nameController = TextEditingController(text: widget.group.name);
    _idController = TextEditingController(text: widget.group.id);
    _typeController = TextEditingController(text: widget.group.type);
    _descriptionController = TextEditingController(
      text: widget.group.description,
    );
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
      final stored = _stateService
          .ensureStateForGroup(_groupId, seed: widget.group)
          .group;
      final settings = await _stateService.getGroupSettings(_groupId);
      final students = await _stateService.getGroupStudents(_groupId);
      final teachers = await _stateService.getGroupTeachers(_groupId);
      final imageUrl = _stateService
          .ensureStateForGroup(_groupId, seed: widget.group)
          .imageUrl;
      var loadedStudents = students;
      var loadedTeachers = teachers;
      var loadedGroup = stored;
      var shouldMigrateMembers = false;
      if (widget.group.databaseId.isNotEmpty) {
        try {
          final remote = await _groupService.getGroupDetails(
            widget.group.databaseId,
          );
          shouldMigrateMembers =
              (remote.students.isEmpty && students.isNotEmpty) ||
              (remote.teachers.isEmpty && teachers.isNotEmpty);
          loadedStudents = remote.students.isEmpty && students.isNotEmpty
              ? students
              : remote.students;
          loadedTeachers = remote.teachers.isEmpty && teachers.isNotEmpty
              ? teachers
              : remote.teachers;
          loadedGroup = remote.group;
        } catch (_) {
          // Keep locally cached data when MongoDB is unavailable.
        }
      }
      if (!mounted) return;
      setState(() {
        _currentImageUrl = imageUrl;
        _students = loadedStudents;
        _teachers = loadedTeachers;
        _originalStudentIds = loadedStudents
            .map((student) => student.id)
            .toSet();
        _originalTeacherIds = loadedTeachers
            .map((teacher) => teacher.teacherId)
            .toSet();
        _settings = settings;
        _nameController.text = loadedGroup.name;
        _idController.text = loadedGroup.id;
        _typeController.text = loadedGroup.type;
        _descriptionController.text = loadedGroup.description;
        _statusController.text = loadedGroup.status;
        _yearController.text = loadedGroup.year;
        _isLoading = false;
      });
      if (shouldMigrateMembers) await _syncMembersToMongo();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final dynamic result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null) return;

    // Normalize to a single file object (supports older API that returns List<PlatformFile>
    // and newer FilePickerResult with .files)
    dynamic file;
    if (result is List && result.isNotEmpty) {
      file = result.first;
    } else {
      // Try dynamic access to FilePickerResult.files for newer API versions
      try {
        final files = (result as dynamic).files;
        if (files is List && files.isNotEmpty) file = files.first;
      } catch (_) {}
      if (file == null && result is PlatformFile) file = result;
    }

    if (file == null) return;
    final path = await _resolvePickedFilePath(file);
    if (path == null || path.isEmpty) return;

    setState(() {
      _selectedImagePath = path;
      _currentImageUrl = null;
    });
  }

  Future<void> _removeImage() async {
    await _stateService.uploadGroupImage(_groupId, null);
    if (!mounted) return;
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
          students: _students,
          teachers: _teachers,
        );
      }

      final currentGroupId = _groupId;
      await _stateService.updateGroup(currentGroupId, updatePayload);
      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
        await _stateService.uploadGroupImage(
          currentGroupId,
          _selectedImagePath,
        );
      }
      for (final student in _students) {
        await _stateService.addStudent(currentGroupId, student);
      }
      final savedStudentIds = _students.map((student) => student.id).toSet();
      for (final studentId in _originalStudentIds.difference(savedStudentIds)) {
        await _stateService.removeStudent(currentGroupId, studentId);
      }
      for (final teacher in _teachers) {
        await _stateService.assignTeacher(currentGroupId, teacher.teacherId, {
          'id': teacher.id,
          'name': teacher.name,
          'subject': teacher.subject,
          'role': teacher.role,
          'imageUrl': teacher.imageUrl,
          'details': teacher.details,
          'contact': teacher.contact,
          'email': teacher.email,
        });
      }
      final savedTeacherIds = _teachers
          .map((teacher) => teacher.teacherId)
          .toSet();
      for (final teacherId in _originalTeacherIds.difference(savedTeacherIds)) {
        await _stateService.removeTeacher(currentGroupId, teacherId);
      }
      await _stateService.saveGroupSettings(
        currentGroupId,
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
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncMembersToMongo() async {
    if (widget.group.databaseId.isEmpty) return;
    try {
      await _groupService.updateGroup(
        widget.group.databaseId,
        name: _nameController.text.trim(),
        id: _idController.text.trim(),
        type: _typeController.text.trim().isEmpty
            ? 'Other'
            : _typeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? _nameController.text.trim()
            : _descriptionController.text.trim(),
        status: _statusController.text.trim().isEmpty
            ? 'Active'
            : _statusController.text.trim(),
        year: _yearController.text.trim(),
        students: _students,
        teachers: _teachers,
      );
    } catch (error) {
      _showSnackBar('Saved locally, but MongoDB sync failed: $error');
    }
  }

  Future<bool> _confirmDelete(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete member?'),
        content: Text('Remove $name from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    String? pickedImage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                      ),
                    ),
                    TextField(
                      controller: classCtrl,
                      decoration: const InputDecoration(labelText: 'Class'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final dynamic result = await FilePicker.pickFiles(
                                type: FileType.image,
                              );
                              if (result == null) return;
                              dynamic file;
                              if (result is List && result.isNotEmpty) {
                                file = result.first;
                              } else {
                                try {
                                  final files = (result as dynamic).files;
                                  if (files is List && files.isNotEmpty)
                                    file = files.first;
                                } catch (_) {}
                                if (file == null && result is PlatformFile) {
                                  file = result;
                                }
                              }
                              if (file == null) return;
                              final path = await _resolvePickedFilePath(file);
                              if (path != null && path.isNotEmpty) {
                                setStateDialog(() => pickedImage = path);
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    if (pickedImage != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: _previewImageWidget(
                          pickedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final sid = idCtrl.text.trim();
                    final cls = classCtrl.text.trim();
                    if (name.isEmpty || sid.isEmpty) {
                      _showSnackBar('Please enter name and student id.');
                      return;
                    }
                    final student = GroupStudent(
                      id: 'student-${DateTime.now().millisecondsSinceEpoch}',
                      groupId: _groupId,
                      name: name,
                      admissionNo: sid,
                      section: cls,
                      imageUrl: pickedImage,
                      details: '',
                      contact: '',
                      email: '',
                    );
                    await _stateService.addStudent(_groupId, student);
                    if (!mounted) return;
                    setState(() => _students = [..._students, student]);
                    await _syncMembersToMongo();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddTeacherDialog({GroupTeacher? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final teacherIdCtrl = TextEditingController(text: existing?.teacherId);
    final subjectCtrl = TextEditingController(text: existing?.subject);
    final roleCtrl = TextEditingController(text: existing?.role);
    String? pickedImage = existing?.imageUrl;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Staff/Teacher' : 'Edit Staff/Teacher',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: teacherIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teacher ID',
                      ),
                    ),
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    TextField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final dynamic result = await FilePicker.pickFiles(
                                type: FileType.image,
                              );
                              if (result == null) return;
                              dynamic file;
                              if (result is List && result.isNotEmpty) {
                                file = result.first;
                              } else {
                                try {
                                  final files = (result as dynamic).files;
                                  if (files is List && files.isNotEmpty)
                                    file = files.first;
                                } catch (_) {}
                                if (file == null && result is PlatformFile) {
                                  file = result;
                                }
                              }
                              if (file == null) return;
                              final path = await _resolvePickedFilePath(file);
                              if (path != null && path.isNotEmpty) {
                                setStateDialog(() => pickedImage = path);
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    if (pickedImage != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: _previewImageWidget(
                          pickedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await _confirmDelete(existing.name);
                      if (!confirmed) return;
                      await _stateService.removeTeacher(
                        _groupId,
                        existing.teacherId,
                      );
                      if (!mounted) return;
                      setState(
                        () => _teachers = _teachers
                            .where(
                              (item) => item.teacherId != existing.teacherId,
                            )
                            .toList(),
                      );
                      await _syncMembersToMongo();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final tid = teacherIdCtrl.text.trim();
                    final subject = subjectCtrl.text.trim();
                    final role = roleCtrl.text.trim();
                    if (name.isEmpty || tid.isEmpty) {
                      _showSnackBar('Please enter name and teacher id.');
                      return;
                    }
                    final teacher = GroupTeacher(
                      id:
                          existing?.id ??
                          'teacher-${DateTime.now().millisecondsSinceEpoch}',
                      groupId: _groupId,
                      teacherId: tid,
                      name: name,
                      subject: subject,
                      role: role.isEmpty ? 'Class Teacher' : role,
                      imageUrl: pickedImage,
                      details: '',
                      contact: '',
                      email: '',
                    );
                    await _stateService
                        .assignTeacher(_groupId, teacher.teacherId, {
                          'id': teacher.id,
                          'name': teacher.name,
                          'subject': teacher.subject,
                          'role': teacher.role,
                          'imageUrl': teacher.imageUrl ?? '',
                          'details': teacher.details,
                          'contact': teacher.contact,
                          'email': teacher.email,
                        });
                    if (!mounted) return;
                    setState(() {
                      _teachers = existing == null
                          ? [..._teachers, teacher]
                          : _teachers
                                .map(
                                  (item) => item.teacherId == existing.teacherId
                                      ? teacher
                                      : item,
                                )
                                .toList();
                    });
                    await _syncMembersToMongo();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _resolvePickedFilePath(dynamic file) async {
    // On web use our helper picker (FilePicker web sometimes returns a WebPlatformFile without usable bytes)
    if (kIsWeb) {
      try {
        final data = await fp_helper.pickImageAsDataUri();
        return data;
      } catch (e) {
        debugPrint('Error resolving picked file bytes on web: $e');
        return null;
      }
    }

    // If the picker gave a direct path, use it. Otherwise write bytes to a temp file.
    try {
      final dynamic df = file;
      final p = (df?.path) as String?;
      if (p != null && p.isNotEmpty) return p;

      final bytes = (df as dynamic).bytes as List<int>?;
      if (bytes == null) return null;
      final ext = (df as dynamic).extension as String? ?? 'png';
      final tmp = File(
        '${Directory.systemTemp.path}/school_app_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await tmp.writeAsBytes(bytes);
      return tmp.path;
    } catch (e) {
      debugPrint('Error resolving picked file path: $e');
      return null;
    }
  }

  Future<void> _showEditStudentDialog(GroupStudent student) async {
    final nameCtrl = TextEditingController(text: student.name);
    final idCtrl = TextEditingController(text: student.admissionNo);
    final sectionCtrl = TextEditingController(text: student.section);
    String? pickedImage = student.imageUrl;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                      ),
                    ),
                    TextField(
                      controller: sectionCtrl,
                      decoration: const InputDecoration(labelText: 'Class'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final dynamic result = await FilePicker.pickFiles(
                                type: FileType.image,
                              );
                              if (result == null) return;
                              dynamic file;
                              if (result is List && result.isNotEmpty) {
                                file = result.first;
                              } else {
                                try {
                                  final files = (result as dynamic).files;
                                  if (files is List && files.isNotEmpty)
                                    file = files.first;
                                } catch (_) {}
                                if (file == null && result is PlatformFile)
                                  file = result;
                              }
                              if (file == null) return;
                              final path = await _resolvePickedFilePath(file);
                              if (path != null && path.isNotEmpty) {
                                setStateDialog(() => pickedImage = path);
                              }
                            },

                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    if (pickedImage != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: _previewImageWidget(
                          pickedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final confirmed = await _confirmDelete(student.name);
                    if (!confirmed) return;
                    await _stateService.removeStudent(_groupId, student.id);
                    if (!mounted) return;
                    setState(
                      () => _students = _students
                          .where((item) => item.id != student.id)
                          .toList(),
                    );
                    await _syncMembersToMongo();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final sid = idCtrl.text.trim();
                    final cls = sectionCtrl.text.trim();
                    if (name.isEmpty || sid.isEmpty) {
                      _showSnackBar('Please enter name and student id.');
                      return;
                    }
                    await _stateService.updateStudent(_groupId, student.id, {
                      'name': name,
                      'admissionNo': sid,
                      'section': cls,
                      'imageUrl': pickedImage ?? '',
                    });
                    final updated = await _stateService.getGroupStudents(
                      _groupId,
                    );
                    if (!mounted) return;
                    setState(() => _students = updated);
                    await _syncMembersToMongo();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _resolveApiBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    const production = 'https://school-app-1uep.onrender.com';
    if (kIsWeb) return production;
    if (kReleaseMode) return production;
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  String _toAbsoluteImageUrl(String rawPath) {
    final base = _resolveApiBaseUrl();
    var p = rawPath.trim();
    if (!p.startsWith('/')) p = '/$p';
    return '$base$p';
  }

  Widget _previewImageWidget(
    String src, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (src.startsWith('data:')) {
      try {
        final comma = src.indexOf(',');
        final b64 = src.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      } catch (e) {
        debugPrint('Failed to decode data URI: $e');
        return const Icon(Icons.broken_image);
      }
    }

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    // For web, local file paths are not available; try resolving as backend-relative
    if (kIsWeb) {
      final abs = _toAbsoluteImageUrl(src);
      return Image.network(
        abs,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    // Native: use file
    try {
      return Image.file(
        File(src),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } catch (e) {
      debugPrint('Error creating File image: $e');
      final abs = _toAbsoluteImageUrl(src);
      return Image.network(
        abs,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }
  }

  Widget _buildStudentCard(GroupStudent s) {
    ImageProvider? imageProvider;
    if (s.imageUrl != null && s.imageUrl!.isNotEmpty) {
      final raw = s.imageUrl!.trim();
      // If it's already an absolute URL, use it
      if (raw.startsWith('data:')) {
        // data URI with base64 encoded bytes (web)
        try {
          final comma = raw.indexOf(',');
          final b64 = raw.substring(comma + 1);
          final bytes = base64Decode(b64);
          imageProvider = MemoryImage(bytes);
        } catch (e) {
          debugPrint('Failed to decode data URI: $e');
        }
      } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
        imageProvider = NetworkImage(raw);
      } else {
        // If it's a local file path that exists, use FileImage
        final f = File(raw);
        if (f.existsSync()) {
          imageProvider = FileImage(f);
        } else {
          // Otherwise treat it as a backend-relative path and build absolute URL
          final abs = _toAbsoluteImageUrl(raw);
          imageProvider = NetworkImage(abs);
        }
      }
    }

    return InkWell(
      onTap: () async {
        await _showEditStudentDialog(s);
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE9EEF7),
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person,
                          size: 28,
                          color: Color(0xFF5A6F92),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  s.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(GroupTeacher t) {
    ImageProvider? imageProvider;
    if (t.imageUrl != null && t.imageUrl!.isNotEmpty) {
      final raw = t.imageUrl!.trim();
      if (raw.startsWith('data:')) {
        try {
          final comma = raw.indexOf(',');
          final b64 = raw.substring(comma + 1);
          final bytes = base64Decode(b64);
          imageProvider = MemoryImage(bytes);
        } catch (e) {
          debugPrint('Failed to decode data URI: $e');
        }
      } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
        imageProvider = NetworkImage(raw);
      } else {
        final f = File(raw);
        if (f.existsSync()) {
          imageProvider = FileImage(f);
        } else {
          final abs = _toAbsoluteImageUrl(raw);
          imageProvider = NetworkImage(abs);
        }
      }
    }

    return InkWell(
      onTap: () => _showAddTeacherDialog(existing: t),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  t.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${t.teacherId}',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.subject,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.role,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _selectedImagePath != null
        ? _previewImageWidget(
            _selectedImagePath!,
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
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported),
                )
              : Container(
                  height: 150,
                  color: const Color(0xffe9eef7),
                  child: const Icon(
                    Icons.image,
                    size: 48,
                    color: Color(0xff5a6f92),
                  ),
                ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: AppColors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Try root navigator maybePop first; fall back to replacing with Group Menu.
            // Using rootNavigator helps when the page is inside nested navigators.
            try {
              final didPop = await Navigator.of(
                context,
                rootNavigator: true,
              ).maybePop();
              if (!didPop) {
                Navigator.of(context, rootNavigator: true).pushReplacementNamed(
                  AppRoutes.teacherGroupClasses,
                  arguments: widget.group,
                );
              }
            } catch (e) {
              debugPrint('Back navigation failed: $e');
              Navigator.of(context, rootNavigator: true).pushReplacementNamed(
                AppRoutes.teacherGroupClasses,
                arguments: widget.group,
              );
            }
          },
        ),
        title: Text(
          'Group Info Edit',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TabBar(
                      labelColor: AppColors.blueButton,
                      unselectedLabelColor: AppColors.hintText,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: AppColors.blueButton,
                          width: 2,
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 28),
                      ),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: const [
                        Tab(text: 'Students'),
                        Tab(text: 'Staff/Teachers'),
                      ],
                    ),
                    // subtle divider below tabs to match screenshot
                    // (keeps tabs visually separated from content)
                    // no extra height so the layout stays tight
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Students tab content: header with Add button and list/grid
                        Container(
                          color: AppColors.background,
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Students',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showAddStudentDialog(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _students.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 40,
                                            ),
                                            child: Text(
                                              'No students found in this group.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ),
                                        )
                                      : GridView.count(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.9,
                                          children: _students
                                              .map((s) => _buildStudentCard(s))
                                              .toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Staff/Teachers tab content: header with Add button and list/grid
                        Container(
                          color: AppColors.background,
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Staff/Teachers',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showAddTeacherDialog(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _teachers.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 40,
                                            ),
                                            child: Text(
                                              'No staff found in this group.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ),
                                        )
                                      : GridView.count(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.8,
                                          children: _teachers
                                              .map((t) => _buildTeacherCard(t))
                                              .toList(),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
    _admissionController = TextEditingController(
      text: widget.student.admissionNo,
    );
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
                    border: Border.all(
                      color: AppColors.blueButton.withValues(alpha: 0.2),
                    ),
                  ),
                  child:
                      widget.student.imageUrl != null &&
                          widget.student.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: Image.file(
                            File(widget.student.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xff4a5a7a),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Name',
                      ),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      onChanged: (value) => widget.student.name = value,
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _admissionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Admission No',
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.student.admissionNo = value,
                    ),
                    TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Section',
                      ),
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
            decoration: const InputDecoration(
              labelText: 'Contact',
              isDense: true,
            ),
            onChanged: (value) => widget.student.contact = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              isDense: true,
            ),
            onChanged: (value) => widget.student.email = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Details',
              isDense: true,
            ),
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
                    border: Border.all(
                      color: AppColors.blueButton.withValues(alpha: 0.2),
                    ),
                  ),
                  child:
                      widget.teacher.imageUrl != null &&
                          widget.teacher.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: Image.file(
                            File(widget.teacher.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xff4a5a7a),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Name',
                      ),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      onChanged: (value) => widget.teacher.name = value,
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Subject',
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) => widget.teacher.subject = value,
                    ),
                    TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Role',
                      ),
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
            decoration: const InputDecoration(
              labelText: 'Contact',
              isDense: true,
            ),
            onChanged: (value) => widget.teacher.contact = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              isDense: true,
            ),
            onChanged: (value) => widget.teacher.email = value,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Details',
              isDense: true,
            ),
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
