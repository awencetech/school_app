import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../services/group_state_service.dart';
import '../../services/app_route_observer.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import 'package:file_picker/file_picker.dart';
import '../student/student_menu_screen.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage>
  with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  final GroupStateService _stateService = GroupStateService.instance;
  late final String _groupId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<GroupStudent> _students = [];
  List<GroupTeacher> _staff = [];

  @override
  void initState() {
    super.initState();
    _groupId = widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadMembers();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await _stateService.initialize();
      _students = await _stateService.getGroupStudents(_groupId);
      _staff = await _stateService.getGroupTeachers(_groupId);
    } catch (_) {
      _hasError = true;
      _errorMessage = 'Unable to load group members.';
      _students = [];
      _staff = [];
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _previewImageWidget(String src, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (src.startsWith('data:')) {
      try {
        final comma = src.indexOf(',');
        final b64 = src.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(bytes, fit: fit, width: width, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
      } catch (e) {
        debugPrint('Failed to decode data URI: $e');
        return const Icon(Icons.broken_image);
      }
    }

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, fit: fit, width: width, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
    }

    if (kIsWeb) {
      // On web, local file system paths are not accessible. Try to show as network resource.
      return Image.network(src, fit: fit, width: width, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
    }

    try {
      return Image.file(File(src), fit: fit, width: width, height: height, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    } catch (e) {
      debugPrint('Error creating File image: $e');
      return const Icon(Icons.broken_image);
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
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Student'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Student ID')),
                  TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Class')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(type: FileType.image);
                            if (result.isEmpty) return;
                            final file = result.first;
                            if (file.path != null && file.path!.isNotEmpty) {
                              setStateDialog(() => pickedImage = file.path);
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
                                      SizedBox(height: 80, child: _previewImageWidget(pickedImage!, fit: BoxFit.cover)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final sid = idCtrl.text.trim();
                  final cls = sectionCtrl.text.trim();
                  if (name.isEmpty || sid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and student id.')));
                    return;
                  }
                  await _stateService.updateStudent(_groupId, student.id, {
                    'name': name,
                    'admissionNo': sid,
                    'section': cls,
                    'imageUrl': pickedImage ?? '',
                  });
                  final updated = await _stateService.getGroupStudents(_groupId);
                  if (mounted) setState(() => _students = updated);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabTextStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: Text(
          '${widget.group.name} Information',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _ErrorState(
                  message: _errorMessage,
                  onRetry: _loadMembers,
                )
              : Column(
                  children: [
                    Container(
                      color: AppColors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        labelColor: AppColors.blueButton,
                        unselectedLabelColor: AppColors.secondaryText,
                        indicatorColor: AppColors.blueButton,
                        indicatorWeight: 2,
                        labelStyle: tabTextStyle,
                        unselectedLabelStyle: tabTextStyle,
                        tabs: const [
                          Tab(text: 'Students'),
                          Tab(text: 'Staff/Teachers'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _MemberGridPanel(
                            title: 'Students',
                            members: _students,
                            emptyMessage: 'No students found in this group.',
                            onMemberTap: (member) {
                              // Navigate to Student Menu when a student is tapped from Group Info
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentMenuScreen()));
                            },
                          ),
                          _MemberGridPanel(
                            title: 'Staff/Teachers',
                            members: _staff,
                            emptyMessage: 'No staff members found in this group.',
                            onMemberTap: (member) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentMenuScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueButton,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberGridPanel extends StatelessWidget {
  const _MemberGridPanel({
    required this.title,
    required this.members,
    required this.emptyMessage,
    this.onMemberTap,
  });

  final String title;
  final List<dynamic> members;
  final String emptyMessage;
  final void Function(dynamic member)? onMemberTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: GridView.builder(
        itemCount: members.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final member = members[index];
          final displayName = member is GroupStudent
            ? (member.name.isNotEmpty ? member.name : 'Unknown')
            : member is GroupTeacher
              ? (member.name.isNotEmpty ? member.name : 'Unknown')
              : 'Unknown';
          final imagePath = member is GroupStudent
            ? member.imageUrl
            : member is GroupTeacher
              ? member.imageUrl
              : null;
          final details = member is GroupStudent
            ? [member.admissionNo, member.section, member.contact, member.details]
            : member is GroupTeacher
              ? [member.subject, member.role, member.contact, member.details]
              : <String>[];

          return InkWell(
            onTap: () => onMemberTap?.call(member),
            child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                _MemberAvatar(imagePath: imagePath),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                ...details
                    .where((detail) => detail.isNotEmpty)
                    .take(2)
                    .map(
                      (detail) => Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE9EEF7),
      backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
      child: hasImage
          ? null
          : const Icon(Icons.person, size: 26, color: AppColors.primary),
    );
  }
}
