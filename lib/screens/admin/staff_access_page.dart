import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_access.dart';
import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_access_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

const _accessGroups = <_AccessGroup>[
  _AccessGroup('dashboard', 'Dashboard', Icons.dashboard_outlined),
  _AccessGroup('students', 'Students', Icons.people_outline),
  _AccessGroup('staff', 'Staff', Icons.badge_outlined),
  _AccessGroup('attendance', 'Attendance', Icons.fact_check_outlined),
  _AccessGroup('leave-requests', 'Leave / Requests', Icons.assignment_outlined),
  _AccessGroup('calendar', 'Calendar', Icons.calendar_month_outlined),
  _AccessGroup('messages', 'Messages', Icons.mail_outline),
  _AccessGroup('news', 'News', Icons.article_outlined),
  _AccessGroup('reports', 'Reports', Icons.analytics_outlined),
  _AccessGroup('student-records', 'Student Records', Icons.school_outlined),
  _AccessGroup('staff-resources', 'Staff Resources', Icons.folder_shared_outlined),
  _AccessGroup('other-options', 'Other Options', Icons.more_horiz),
];

class _AccessGroup {
  const _AccessGroup(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class StaffAccessPage extends StatefulWidget {
  const StaffAccessPage({super.key});

  @override
  State<StaffAccessPage> createState() => _StaffAccessPageState();
}

class _StaffAccessPageState extends State<StaffAccessPage> {
  final _service = StaffAccessService();
  final _searchController = TextEditingController();
  List<StaffAccessRecord> _records = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _service.getAll();
      if (mounted) setState(() { _records = records; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = _message(error); });
    }
  }

  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().currentUserRole?.toLowerCase() == 'admin';
    final query = _searchController.text.trim().toLowerCase();
    final records = _records.where((record) {
      final staff = record.staff;
      return query.isEmpty ||
          staff.name.toLowerCase().contains(query) ||
          staff.employeeId.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Staff Access'),
        centerTitle: true,
      ),
      body: !isAdmin
          ? const Center(child: Text('Admin access required.'))
          : _buildBody(records),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
        },
      ),
    );
  }

  Widget _buildBody(List<StaffAccessRecord> records) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _StateMessage(message: _error!, actionLabel: 'Retry', onAction: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Manage staff permissions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Review and update which areas each staff member can access.', style: TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name or staff ID',
              suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const _StateMessage(message: 'No staff members found')
          else
            ...records.map(_staffCard),
        ],
      ),
    );
  }

  Widget _staffCard(StaffAccessRecord record) {
    final staff = record.staff;
    final staffId = staff.employeeId.isNotEmpty ? staff.employeeId : (staff.id ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _avatar(staff),
        title: Text(staff.name.isEmpty ? 'Unnamed staff member' : staff.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${staffId.isEmpty ? 'Staff ID unavailable' : 'Staff ID: $staffId'}\n${staff.designation.isNotEmpty ? staff.designation : staff.role.isNotEmpty ? staff.role : 'Designation unavailable'}\nAccess: ${record.accessGroups.length} groups'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final staffId = record.staff.employeeId.isNotEmpty
              ? record.staff.employeeId
              : record.staff.id;
          if (staffId == null || staffId.isEmpty) return;
          final changed = await Navigator.of(context).pushNamed<bool>(
            '${AppRoutes.adminStaffAccessEdit}/${Uri.encodeComponent(staffId)}',
            arguments: record,
          );
          if (changed == true) _load();
        },
      ),
    );
  }

  Widget _avatar(StaffInfo staff) {
    if (staff.imageUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(staff.imageUrl));
    }
    return CircleAvatar(child: Text(staff.name.trim().isEmpty ? '?' : staff.name.trim()[0].toUpperCase()));
  }
}

class StaffAccessEditPage extends StatefulWidget {
  const StaffAccessEditPage({super.key, this.record, this.staffId});
  final StaffAccessRecord? record;
  final String? staffId;

  @override
  State<StaffAccessEditPage> createState() => _StaffAccessEditPageState();
}

class _StaffAccessEditPageState extends State<StaffAccessEditPage> {
  final _service = StaffAccessService();
  StaffAccessRecord? _record;
  Set<String> _selected = {};
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    if (_record != null) {
      _selected = _record!.accessGroups.toSet();
    } else if (widget.staffId != null && widget.staffId!.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final record = await _service.get(widget.staffId!);
      if (mounted) setState(() { _record = record; _selected = record.accessGroups.toSet(); _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _save() async {
    final record = _record;
    if (record == null) return;
    final staff = record.staff;
    final staffId = staff.employeeId.isNotEmpty ? staff.employeeId : staff.id;
    if (staffId == null || staffId.isEmpty) {
      setState(() => _error = 'Staff ID is missing.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _service.save(staffId: staffId, accessGroups: _selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff access saved successfully.')));
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) setState(() { _saving = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AppState>().currentUserRole?.toLowerCase() != 'admin') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Access')),
        body: const Center(child: Text('Admin access required.')),
        bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (_) {}),
      );
    }
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Access')),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (_) {}),
      );
    }
    final record = _record;
    if (record == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Access')),
        body: _StateMessage(message: _error ?? 'Staff member not found.', actionLabel: widget.staffId == null ? null : 'Retry', onAction: widget.staffId == null ? null : _load),
        bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (_) {}),
      );
    }
    final staff = record.staff;
    final staffId = staff.employeeId.isNotEmpty ? staff.employeeId : (staff.id ?? '');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Access'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _profileAvatar(staff),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(staff.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Staff ID: ${staffId.isEmpty ? 'Unavailable' : staffId}'),
                  Text(staff.designation.isNotEmpty ? staff.designation : staff.role),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('Staff Access', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._accessGroups.map((group) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: CheckboxListTile(
                  value: _selected.contains(group.id),
                  onChanged: _saving ? null : (value) => setState(() { value == true ? _selected.add(group.id) : _selected.remove(group.id); }),
                  secondary: Icon(group.icon),
                  title: Text(group.label),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              )),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save), label: const Text('Save Access')),
        ],
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (_) {}),
    );
  }

  Widget _profileAvatar(StaffInfo staff) => staff.imageUrl.isEmpty
      ? CircleAvatar(radius: 28, child: Text(staff.name.isEmpty ? '?' : staff.name[0].toUpperCase()))
      : CircleAvatar(radius: 28, backgroundImage: NetworkImage(staff.imageUrl));
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.actionLabel, this.onAction});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ]),
      );
}
