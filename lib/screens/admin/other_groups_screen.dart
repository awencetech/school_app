import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/slug_generator.dart';
import '../../widgets/admin_bottom_nav.dart';

/// Other Groups page showing a list of groups with search and pagination.
class OtherGroupsScreen extends StatefulWidget {
  const OtherGroupsScreen({super.key});

  @override
  State<OtherGroupsScreen> createState() => _OtherGroupsScreenState();
}

class _OtherGroupsScreenState extends State<OtherGroupsScreen> {
  final GroupService _groupService = GroupService();
  late List<Group> allGroups;
  late List<Group> filteredGroups;
  late TextEditingController searchController;
  bool _isLoading = true;
  String? _errorMessage;
  final int _selectedBottomIndex = 0;

  int currentPage = 1;
  static const int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    allGroups = [];
    filteredGroups = [];
    _loadGroups();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groups = await _groupService.getGroups(
        onRefresh: _applyGroups,
      );
      if (!mounted) return;

      _applyGroups(groups);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'Unable to load groups.';
      });
    }
  }

  void _applyGroups(List<Group> groups) {
    if (!mounted) return;
    final ordered = [...groups]..sort((a, b) => a.order.compareTo(b.order));
    setState(() {
      allGroups = ordered;
      filteredGroups = ordered;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredGroups = allGroups;
      } else {
        final lowerQuery = query.toLowerCase();
        filteredGroups = allGroups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(lowerQuery) ||
                  group.code.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
      currentPage = 1; // Reset to first page on search
    });
  }

  int get totalPages {
    return (filteredGroups.length / itemsPerPage).ceil();
  }

  List<Group> get paginatedGroups {
    if (filteredGroups.isEmpty) return [];
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredGroups.length,
    );
    return filteredGroups.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
    }
  }

  void _goToGroupDetails(Group group) {
    final groupSlug = generateGroupSlug(group.name);
    Navigator.of(context).pushNamed(
      '${AppRoutes.adminOtherGroupDetails}$groupSlug',
      arguments: group,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('List Groups', style: AppTextStyles.appTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search field
            TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Groups here',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.hintText,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.hintText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.blueButton),
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            // Groups grid/list
            if (!_isLoading && filteredGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No groups found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              )
            else if (!_isLoading)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.8,
                ),
                itemCount: paginatedGroups.length,
                itemBuilder: (context, index) {
                  final group = paginatedGroups[index];
                  return _GroupCard(
                    group: group,
                    onTap: () => _goToGroupDetails(group),
                  );
                },
              ),

            if (!_isLoading && totalPages > 1) ...[
              const SizedBox(height: 20),
              _PaginationControls(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: _goToPage,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blueButton,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                group.code,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  List<Object> get _pageItems {
    if (totalPages <= 7) {
      return List<int>.generate(totalPages, (index) => index + 1);
    }

    if (currentPage <= 3) {
      return [1, 2, 3, 4, '...', totalPages];
    }

    if (currentPage >= totalPages - 2) {
      return [
        1,
        '...',
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }

    return [
      1,
      '...',
      currentPage - 1,
      currentPage,
      currentPage + 1,
      '...',
      totalPages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [
        _PaginationButton(
          label: 'Prev',
          enabled: currentPage > 1,
          onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        for (final item in _pageItems)
          if (item is int)
            _PaginationButton(
              label: item.toString(),
              isActive: item == currentPage,
              onTap: () => onPageChanged(item),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                item as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
        _PaginationButton(
          label: 'Next',
          enabled: currentPage < totalPages,
          onTap: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.label,
    this.isActive = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueButton : AppColors.white,
          border: Border.all(
            color: isActive ? AppColors.blueButton : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive
                ? AppColors.white
                : (enabled ? AppColors.primaryText : AppColors.hintText),
          ),
        ),
      ),
    );
  }
}
