import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/class_demography.dart';
import '../../models/demography.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../services/demography_service.dart';
import '../../services/user_service.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class ClassDemographyPage extends StatefulWidget {
  const ClassDemographyPage({
    super.key,
    required this.group,
    this.isStaffView = false,
    this.isViewOnly = false,
  });

  final Group group;
  final bool isStaffView;
  final bool isViewOnly;

  @override
  State<ClassDemographyPage> createState() => _ClassDemographyPageState();
}

class _ClassDemographyPageState extends State<ClassDemographyPage> {
  final UserService _userService = UserService();
  final DemographyService _demographyService = DemographyService();
  bool _isLoading = true;
  String? _error;
  ClassDemography? _demography;

  // Replace with school coordinates when they become available from the API.
  static const schoolLatitude = 11.0168;
  static const schoolLongitude = 76.9558;

  @override
  void initState() {
    super.initState();
    _loadDemography();
  }

  Future<void> _loadDemography() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groupId = widget.group.id.trim();
      final allRecords = await _demographyService.getDemographies();
      Demography? record;
      if (groupId.isNotEmpty) {
        record = allRecords.cast<Demography?>().firstWhere(
          (item) => item!.groupId.trim() == groupId,
          orElse: () => null,
        );
      }
      record ??= allRecords.cast<Demography?>().firstWhere(
        (item) => item!.groupName.trim().toLowerCase() == widget.group.name.trim().toLowerCase(),
        orElse: () => null,
      );
      record ??= allRecords.isEmpty ? null : allRecords.first;

      if (record != null && mounted) {
        setState(() {
          _demography = ClassDemography(
            className: record!.groupName,
            academicYear: widget.group.year,
            schoolName: 'Sri Aurobindo Mira Universal School',
            classTeachers: record.teachers.map((member) => member.displayText).toList(),
            otherTeachers: record.otherTeachers.map((member) => member.displayText).toList(),
            students: record.students.map((member) => member.displayText).toList(),
            locations: [
              const MapLocation(name: 'School', latitude: schoolLatitude, longitude: schoolLongitude, type: MarkerType.school),
            ],
          );
          _isLoading = false;
        });
        return;
      }

      final users = await _userService.getUsers();
      final students = users.where((user) => user.role.toLowerCase() == 'student').map(_userLabel).toList();
      final teachers = users.where((user) => user.role.toLowerCase() == 'staff' || user.role.toLowerCase() == 'teacher').map(_userLabel).toList();
      final locations = <MapLocation>[
        const MapLocation(name: 'School', latitude: schoolLatitude, longitude: schoolLongitude, type: MarkerType.school),
      ];
      if (!mounted) return;
      setState(() {
        _demography = ClassDemography(
          className: widget.group.name,
          academicYear: widget.group.year,
          schoolName: 'Sri Aurobindo Mira Universal School',
          classTeachers: teachers.take(3).toList(),
          otherTeachers: teachers.skip(3).toList(),
          students: students,
          locations: locations,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load class demography';
        _isLoading = false;
      });
    }
  }

  String _userLabel(User user) {
    final name = user.userId.trim().isNotEmpty ? user.userId.trim() : user.email.trim();
    final identifier = (user.id ?? '').trim();
    return identifier.isEmpty ? name : '$name($identifier)';
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
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text('Demography', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _loadDemography)
                : _DemographyContent(demography: _demography!),
      ),
      bottomNavigationBar: widget.isStaffView
          ? ReusableBottomNavigationBar(
              currentIndex: 0,
              onItemSelected: (index) {
                if (index == 4) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.main,
                    (route) => false,
                  );
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'User',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.help),
                  label: 'Support',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Logout',
                ),
              ],
            )
          : AdminBottomNavigationBar(
              currentIndex: 2,
              onItemSelected: (_) {},
            ),
    );
  }
}

class _DemographyContent extends StatelessWidget {
  const _DemographyContent({required this.demography});

  final ClassDemography demography;

  @override
  Widget build(BuildContext context) {
    final center = demography.locations.first.point;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 76),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13, interactionOptions: const InteractionOptions(flags: InteractiveFlag.all)),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'school_app'),
              MarkerLayer(markers: demography.locations.map((location) => Marker(point: location.point, width: 16, height: 16, child: _MapMarker(type: location.type))).toList()),
              RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 20),
          child: _DemographyText(demography: demography),
        ),
      ]),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.type});

  final MarkerType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      MarkerType.school => const Color(0xffe85d04),
      MarkerType.teacher => const Color(0xff277da1),
      MarkerType.student => const Color(0xff277da1),
    };
    return Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)));
  }
}

class _DemographyText extends StatelessWidget {
  const _DemographyText({required this.demography});

  final ClassDemography demography;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 10.5, height: 1.32, color: Color(0xff222222)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(demography.schoolName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Class Teacher:', style: TextStyle(fontWeight: FontWeight.w600)),
        ...demography.classTeachers.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
        const SizedBox(height: 5),
        const Text('Other Teachers:', style: TextStyle(fontWeight: FontWeight.w600)),
        ...demography.otherTeachers.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
        const SizedBox(height: 5),
        const Text('Students:', style: TextStyle(fontWeight: FontWeight.w600)),
        ...demography.students.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
      ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: const TextStyle(fontSize: 11)),
        TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(fontSize: 11))),
      ]),
    );
  }
}
