import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../services/group_state_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage>
    with SingleTickerProviderStateMixin {
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
  void dispose() {
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
            tooltip: 'Edit group information',
            icon: const Icon(Icons.edit_outlined, color: AppColors.white),
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                '/teacher/group-info-edit',
                arguments: widget.group,
              );
              _loadMembers();
            },
          ),
        ],
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
  });

  final String title;
  final List<dynamic> members;
  final String emptyMessage;

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

          return Container(
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
