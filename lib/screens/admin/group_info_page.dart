import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
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
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<User> _students = [];
  List<User> _staff = [];

  @override
  void initState() {
    super.initState();
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
      final users = await _userService.getUsers();
      final matchedRole = widget.group.name.trim();
      _students = users
          .where((user) => user.role == 'student')
          .toList();
      _staff = users
          .where((user) => user.role == 'staff')
          .toList();

      if (_students.isEmpty && _staff.isEmpty && matchedRole.isNotEmpty) {
        _students = [];
        _staff = [];
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
  final List<User> members;
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
          final displayName = member.userId.isNotEmpty ? member.userId : 'Unknown';

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE9EEF7),
                  child: Icon(
                    Icons.person,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
