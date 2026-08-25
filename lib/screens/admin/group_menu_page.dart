import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_bottom_nav.dart';

class GroupMenuPage extends StatelessWidget {
  const GroupMenuPage({super.key, required this.group});

  final Group group;

  static const _items = [
    _GroupMenuItem(
      'Group Info',
      Icons.info_outline,
      Color(0xff2563eb),
      AppRoutes.teacherEditGroupInfo,
    ),
    _GroupMenuItem(
      'Future Event Calendar',
      Icons.calendar_month,
      Color(0xfff59e0b),
      AppRoutes.teacherEditFutureEventCalendar,
    ),
    _GroupMenuItem(
      'HW Today In Class',
      Icons.assignment,
      Color(0xffef4444),
      AppRoutes.teacherEditHomeworkToday,
    ),
    _GroupMenuItem(
      'Group Messages',
      Icons.mail_outline,
      Color(0xff16a34a),
      AppRoutes.teacherEditGroupMessages,
    ),
    _GroupMenuItem(
      'Write Write Emsg',
      Icons.edit,
      Color(0xff9333ea),
      AppRoutes.teacherEditWriteMessage,
    ),
    _GroupMenuItem(
      'Class Demography',
      Icons.groups,
      Color(0xff06b6d4),
      AppRoutes.teacherEditClassDemography,
    ),
    _GroupMenuItem(
      'Class Resources',
      Icons.library_books,
      Color(0xff8b5cf6),
      AppRoutes.teacherEditClassResources,
    ),
    _GroupMenuItem(
      'Photos News',
      Icons.photo_camera,
      Color(0xffec4899),
      AppRoutes.teacherEditPhotosNews,
    ),
    _GroupMenuItem(
      'Class Timetable',
      Icons.schedule,
      Color(0xff3b82f6),
      AppRoutes.teacherEditClassTimetable,
    ),
    _GroupMenuItem(
      'Class Planner',
      Icons.today,
      Color(0xff10b981),
      AppRoutes.teacherEditClassPlanner,
    ),
    _GroupMenuItem(
      'Video Conf',
      Icons.videocam,
      Color(0xffdc2626),
      AppRoutes.teacherEditVideoConference,
    ),
    _GroupMenuItem(
      'Class File/Plan',
      Icons.folder,
      Color(0xff0ea5e9),
      AppRoutes.teacherEditClassFilePlan,
    ),
    _GroupMenuItem(
      'Online Assignment',
      Icons.assignment_turned_in,
      Color(0xfff97316),
      AppRoutes.teacherEditOnlineAssignment,
    ),
    _GroupMenuItem(
      'Online Assessment',
      Icons.assessment,
      Color(0xff6366f1),
      AppRoutes.teacherEditOnlineAssessment,
    ),
    _GroupMenuItem(
      'Group Info Edit',
      Icons.edit_note,
      Color(0xff4f46e5),
      AppRoutes.teacherEditGroupInfoEdit,
    ),
  ];

  Future<void> _openItem(BuildContext context, _GroupMenuItem item) async {
    final result = await Navigator.of(context).pushNamed(
      item.route,
      arguments: group,
    );
    if (item.route == AppRoutes.teacherGroupInfoEdit && result == true && context.mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.teacherGroupInfo,
        arguments: group,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text(
          'Group Menu Edit',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 340 ? 4 : 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Group Menu',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff34395f),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 4 ? 1.05 : 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _GroupMenuTile(
                      item: item,
                      onTap: () => _openItem(context, item),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _GroupMenuItem {
  const _GroupMenuItem(this.title, this.icon, this.color, this.route);

  final String title;
  final IconData icon;
  final Color color;
  final String route;
}

class _GroupMenuTile extends StatelessWidget {
  const _GroupMenuTile({required this.item, required this.onTap});

  final _GroupMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(item.icon, size: 22, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  height: 1.15,
                  color: Color(0xff222222),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
