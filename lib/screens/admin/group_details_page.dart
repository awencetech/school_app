import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/slug_generator.dart';
import '../../widgets/admin_bottom_nav.dart';
import 'future_event_calendar_page.dart';
import 'group_info_page.dart';
import 'group_messages_page.dart';
import 'homework_today_in_class_page.dart';
import 'class_demography_page.dart';
import 'class_resources_page.dart';
import 'class_news_page.dart';
import 'class_timetable_page.dart';
import 'class_planner_page.dart';
import 'online_class_meeting_page.dart';
import 'class_fileplan_page.dart';
import 'online_assignment_page.dart';
import 'online_assessment_page.dart';
import 'leave_approval_page.dart';
import 'medical_event_list_page.dart';
import 'happiness_report_page.dart';
import 'one_on_one_meeting_page.dart';
import 'group_dashboard_page.dart';
import 'absence_page.dart';
import 'write_message_page.dart';
import 'group_achievement_award_page.dart';
import 'diary_summary_page.dart';

/// Group Details page showing comprehensive information about a selected group.
class GroupDetailsPage extends StatefulWidget {
  const GroupDetailsPage({super.key, required this.group});

  final Group group;

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  int _selectedBottomIndex = 2;

  @override
  Widget build(BuildContext context) {
    final groupDatabaseId = generateGroupDatabaseId(widget.group.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Menu', style: AppTextStyles.appTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name (Compact Title)
            Text(
              widget.group.name,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            // Group Info - Full Width Compact Layout
            _CompactGroupInfo(
              groupDatabaseId: groupDatabaseId,
              groupType: widget.group.type,
              description: widget.group.code,
              status: widget.group.status,
              year: widget.group.year,
            ),
            const SizedBox(height: 16),

            // Divider
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 24),

            // Group Menu Section
            Text(
              'Group Menu',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),

            // First Icon Grid
            _IconGrid(
              items: [
                _IconGridItem(
                  'Group Info',
                  Icons.info,
                  const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupInfoPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Future Event Calendar',
                  Icons.calendar_month,
                  const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FutureEventCalendarPage(
                          groupId: groupDatabaseId,
                          groupName: widget.group.name,
                        ),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'HW Today in class',
                  Icons.book,
                  const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomeworkTodayInClassPage(
                          groupId: groupDatabaseId,
                          groupName: widget.group.name,
                          groupYear: widget.group.year,
                        ),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Group Messages',
                  Icons.mail,
                  const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupMessagesPage(
                          groupId: groupDatabaseId,
                          groupName: widget.group.name,
                          groupYear: widget.group.year,
                        ),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Write Write Msg!',
                  Icons.edit,
                  const Color(0xFF9333EA),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WriteMessagePage(
                          groupId: groupDatabaseId,
                          groupName: widget.group.name,
                          groupYear: widget.group.year,
                        ),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class Demography',
                  Icons.people,
                  const Color(0xFF06B6D4),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ClassDemographyPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class Resources',
                  Icons.library_books,
                  const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassResourcesPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Photos News',
                  Icons.photo_camera,
                  const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassNewsPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class TimeTable',
                  Icons.schedule,
                  const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassTimetablePage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class Planner',
                  Icons.today,
                  const Color(0xFF10B981),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassPlannerPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Video Conf',
                  Icons.videocam,
                  const Color(0xFFDC2626),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineClassMeetingPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class FilePlan',
                  Icons.folder,
                  const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassFileplanPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Online Assignment',
                  Icons.assignment,
                  const Color(0xFFF97316),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineAssignmentPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Online Assessment',
                  Icons.assessment,
                  const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineAssessmentPage(group: widget.group),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Divider
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 24),

            // Teacher Options Section
            Text(
              'Teacher Options',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),

            // Second Icon Grid
            _IconGrid(
              items: [
                _IconGridItem(
                  'Group/Class Menu',
                  Icons.menu,
                  const Color(0xFF06B6D4),
                ),
                _IconGridItem(
                  'Group Dashboard',
                  Icons.dashboard,
                  const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDashboardPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Diary Summary',
                  Icons.note_outlined,
                  const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DiarySummaryPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Take Attendance',
                  Icons.how_to_reg,
                  const Color(0xFF10B981),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AbsencePage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Appreciate Award',
                  Icons.emoji_events,
                  const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupAchievementAwardPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Class FilePlan',
                  Icons.folder,
                  const Color(0xFFDC2626),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassFileplanPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Online Assignment',
                  Icons.assignment,
                  const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineAssignmentPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Online Assessment',
                  Icons.assessment,
                  const Color(0xFFF97316),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineAssessmentPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Leave Approval',
                  Icons.approval,
                  const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeaveApprovalPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Medical Event List',
                  Icons.health_and_safety,
                  const Color(0xFF14B8A6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MedicalEventListPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Happiness Report',
                  Icons.insert_chart,
                  const Color(0xFFD946EF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HappinessReportPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'One on One Meeting',
                  Icons.video_call,
                  const Color(0xFFFACC15),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OneOnOneMeetingPage(group: widget.group),
                      ),
                    );
                  },
                ),
                _IconGridItem(
                  'Pick/Drop Entry',
                  Icons.directions_car,
                  const Color(0xFF0284C7),
                ),
                _IconGridItem(
                  'Access Mgmt',
                  Icons.admin_panel_settings,
                  const Color(0xFF84CC16),
                ),
                _IconGridItem(
                  'Class Fee Details',
                  Icons.receipt,
                  const Color(0xFFF43F5E),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) {
          // Handle bottom navigation (in this case, just stay on this page)
          setState(() {
            _selectedBottomIndex = index;
          });
        },
      ),
    );
  }
}

/// Compact group information display in full-width layout
class _CompactGroupInfo extends StatelessWidget {
  const _CompactGroupInfo({
    required this.groupDatabaseId,
    required this.groupType,
    required this.description,
    required this.status,
    required this.year,
  });

  final String groupDatabaseId;
  final String groupType;
  final String description;
  final String status;
  final String year;

  @override
  Widget build(BuildContext context) {
    final rows = <_GroupInfoRow>[
      _GroupInfoRow('Id', groupDatabaseId),
      _GroupInfoRow('Type', groupType),
      _GroupInfoRow('Description', description),
      _GroupInfoRow('Status', status),
      _GroupInfoRow('Year', year),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    row.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _GroupInfoRow {
  const _GroupInfoRow(this.label, this.value);

  final String label;
  final String value;
}

/// Reusable menu item widget for compact icon grids.
class GroupMenuItem extends StatelessWidget {
  const GroupMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon grid item
class _IconGridItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _IconGridItem(this.label, this.icon, this.color, {this.onTap});
}

/// Icon grid widget
class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.items});

  final List<_IconGridItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 400 ? 4 : 5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GroupMenuItem(
              icon: item.icon,
              title: item.label,
              backgroundColor: item.color,
              onTap: item.onTap ?? () {},
            );
          },
        );
      },
    );
  }
}
