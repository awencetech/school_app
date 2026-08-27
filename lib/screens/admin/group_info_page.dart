import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../services/group_state_service.dart';
import '../../services/group_service.dart';
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
  final GroupService _groupService = GroupService();
  late final String _groupId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<GroupStudent> _students = [];
  List<GroupTeacher> _staff = [];
  StreamSubscription<String>? _groupChangeSub;

  @override
  void initState() {
    super.initState();
    _groupId = widget.group.id.isNotEmpty ? widget.group.id : widget.group.name;
    _tabController = TabController(length: 2, vsync: this);
    _loadMembers();

    // subscribe to group changes so edits made elsewhere are reflected immediately
    _groupChangeSub = _stateService.onGroupChanged
        .where((id) => id == _groupId)
        .listen((_) {
          if (mounted) _loadMembers();
        });
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
    _groupChangeSub?.cancel();
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
      final localStudents = await _stateService.getGroupStudents(_groupId);
      final localStaff = await _stateService.getGroupTeachers(_groupId);
      _students = localStudents;
      _staff = localStaff;
      try {
        final remote = await _groupService.getGroupDetails(
          widget.group.databaseId.isNotEmpty
              ? widget.group.databaseId
              : _groupId,
        );
        final shouldMigrateStudents =
            remote.students.isEmpty && localStudents.isNotEmpty;
        final shouldMigrateStaff =
            remote.teachers.isEmpty && localStaff.isNotEmpty;
        _students = shouldMigrateStudents ? localStudents : remote.students;
        _staff = shouldMigrateStaff ? localStaff : remote.teachers;
        if (shouldMigrateStudents || shouldMigrateStaff) {
          await _groupService.updateGroup(
            widget.group.databaseId,
            name: remote.group.name,
            id: remote.group.id,
            type: remote.group.type,
            description: remote.group.description,
            status: remote.group.status,
            year: remote.group.year,
            students: _students,
            teachers: _staff,
          );
        }
      } catch (_) {
        // Keep locally cached members when MongoDB is unavailable.
      }
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
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
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
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    }

    if (kIsWeb) {
      // On web, local file system paths are not accessible. Try to show as network resource.
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    }

    try {
      return Image.file(
        File(src),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      );
    } catch (e) {
      debugPrint('Error creating File image: $e');
      return const Icon(Icons.broken_image);
    }
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
        actions: [
          IconButton(
            tooltip: 'Undo last change',
            icon: const Icon(Icons.undo, color: AppColors.white),
            onPressed: () async {
              final ok = await _stateService.undoLastChange(_groupId);
              if (ok) {
                await _loadMembers();
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Undo applied')));
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nothing to undo')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _ErrorState(message: _errorMessage, onRetry: _loadMembers)
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentMenuScreen(
                                name: member is GroupStudent
                                    ? member.name
                                    : (member.name ?? 'Student'),
                                studentId: member is GroupStudent
                                    ? member.admissionNo
                                    : null,
                                admissionNo: member is GroupStudent
                                    ? member.admissionNo
                                    : '',
                                grade: member is GroupStudent
                                    ? member.section
                                    : null,
                                year: widget.group.year,
                                status: widget.group.status,
                                imageUrl: member is GroupStudent
                                    ? member.imageUrl
                                    : (member is GroupTeacher
                                          ? member.imageUrl
                                          : null),
                              ),
                            ),
                          );
                        },
                      ),
                      _MemberGridPanel(
                        title: 'Staff/Teachers',
                        members: _staff,
                        emptyMessage: 'No staff members found in this group.',
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
              ? [
                  member.admissionNo,
                  member.section,
                  member.contact,
                  member.details,
                ]
              : member is GroupTeacher
              ? [member.teacherId, member.subject, member.role]
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
    ImageProvider? provider;
    if (hasImage) {
      final raw = imagePath!.trim();
      if (raw.startsWith('data:')) {
        try {
          final comma = raw.indexOf(',');
          final b64 = raw.substring(comma + 1);
          final bytes = base64Decode(b64);
          provider = MemoryImage(bytes);
        } catch (e) {
          debugPrint('Failed to decode data URI in _MemberAvatar: $e');
        }
      } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
        provider = NetworkImage(raw);
      } else {
        if (!kIsWeb) {
          final f = File(raw);
          if (f.existsSync()) {
            provider = FileImage(f);
          } else {
            provider = NetworkImage(_toAbsoluteImageUrl(raw));
          }
        } else {
          // On web, local file paths aren't accessible; treat as backend-relative
          provider = NetworkImage(_toAbsoluteImageUrl(raw));
        }
      }
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE9EEF7),
      backgroundImage: provider,
      child: provider == null
          ? const Icon(Icons.person, size: 26, color: AppColors.primary)
          : null,
    );
  }
}
