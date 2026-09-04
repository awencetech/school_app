import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/staff_info.dart';
import '../../models/staff_resource.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_resource_service.dart';
import 'admin_staff_resource_page.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class StaffResourceHistoryPage extends StatefulWidget {
  const StaffResourceHistoryPage({super.key, required this.staff});
  final StaffInfo? staff;

  @override
  State<StaffResourceHistoryPage> createState() => _StaffResourceHistoryPageState();
}

class _StaffResourceHistoryPageState extends State<StaffResourceHistoryPage> {
  final _service = StaffResourceService();
  List<StaffResource> _resources = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staff = widget.staff;
    if (staff == null || staff.employeeId.isEmpty) {
      setState(() { _loading = false; _error = 'Staff information is unavailable.'; });
      return;
    }
    try {
      final resources = await _service.getAll(
        staffId: staff.employeeId,
        token: context.read<AppState>().currentAuthToken,
      );
      if (mounted) setState(() { _resources = resources; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _deleteResource(StaffResource resource) async {
    if (resource.id == null || resource.id!.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete staff resource?'),
        content: const Text('Are you sure you want to delete this staff resource?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final original = List<StaffResource>.from(_resources);
    final token = context.read<AppState>().currentAuthToken;
    setState(() => _resources = _resources.where((item) => item.id != resource.id).toList());
    try {
      await _service.delete(resource.id!, token: token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource deleted successfully.')));
    } catch (error) {
      if (mounted) {
        setState(() => _resources = original);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red.shade700));
      }
    }
  }

  Future<void> _editResource(StaffResource resource) async {
    final staff = widget.staff;
    if (staff == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StaffResourceForm(
        staff: [staff],
        resource: resource,
        onSave: (updated) => _service.update(
          updated,
          token: context.read<AppState>().currentAuthToken,
        ),
      ),
    );
    if (saved == true) {
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource updated successfully.')));
    }
  }

  void _showDetails(StaffResource resource) {
    final staff = widget.staff;
    Widget value(String label, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 142,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff263238),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text.isEmpty ? 'Not available' : text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Color(0xff263238),
                  ),
                ),
              ),
            ],
          ),
        );
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Resource Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                value('Resource Title', resource.description),
                value('Staff Name', staff?.name ?? resource.staffName),
                value('Staff ID', staff?.employeeId ?? resource.staffId),
                value('Description', resource.description),
                value('Resource Link', resource.link),
                value('Slip/Report Image URL', resource.slipReportImageUrl),
                value('Created Date', _detailDate(resource.createdAt)),
                value('Updated Date', _detailDate(resource.updatedAt)),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _viewResource(StaffResource resource) {
    if (resource.slipReportImageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image available for this resource.')));
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.adminOtherStaffResourceHistoryView, arguments: resource);
  }

  Future<void> _downloadResource(StaffResource resource) async {
    final value = resource.slipReportImageUrl.trim().isNotEmpty ? resource.slipReportImageUrl.trim() : resource.link.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No downloadable file available.')));
      return;
    }
    final opened = await launchUrl(Uri.tryParse(value)!, mode: LaunchMode.externalApplication);
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open downloadable file.')));
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Resource History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Text(staff?.name.isEmpty == false ? staff!.name : 'Staff member', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Staff ID: ${staff?.employeeId ?? 'Unavailable'}'),
                  const SizedBox(height: 20),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red))
                  else if (_resources.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('No staff resources available.')))
                  else
                    ..._resources.map((resource) => _HistoryCard(
                          resource: resource,
                          onView: () => _viewResource(resource),
                          onDetails: () => _showDetails(resource),
                          onDelete: () => _deleteResource(resource),
                          onEdit: () => _editResource(resource),
                          onDownload: () => _downloadResource(resource),
                        )),
                ],
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          if (index == 3) Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          if (index == 4) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.resource, required this.onView, required this.onDetails, required this.onDelete, required this.onEdit, required this.onDownload});
  final StaffResource resource;
  final VoidCallback onView;
  final VoidCallback onDetails;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: Color(0xffdddddd)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 4, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resource.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xff173c70)),
              ),
              Text(
                _shortHistoryDate(resource.createdAt),
                style: const TextStyle(fontSize: 7, color: Color(0xff555555)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _HistoryAction(tooltip: 'View slip/report image', icon: Icons.visibility_outlined, onPressed: onView),
                  _HistoryAction(
                    tooltip: 'View resource details',
                    icon: Icons.info_outline,
                    onPressed: onDetails,
                  ),
                  _HistoryAction(tooltip: 'Delete resource', icon: Icons.delete_outline, onPressed: onDelete),
                  _HistoryAction(tooltip: 'Edit resource', icon: Icons.edit_outlined, onPressed: onEdit),
                  _HistoryAction(tooltip: 'Download resource', icon: Icons.download_outlined, onPressed: onDownload),
                ],
              ),
            ],
          ),
        ),
      );

}

class _HistoryAction extends StatelessWidget {
  const _HistoryAction({required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 15, color: const Color(0xff777777)),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
        visualDensity: VisualDensity.compact,
      );
}

String _shortHistoryDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Date unavailable';
  return '${date.day.toString().padLeft(2, '0')}-${_monthShort(date.month)}-${date.year.toString().substring(2)}';
}

String _monthShort(int month) => const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month];

String _detailDate(String? value) {
  if (value == null || value.isEmpty) return 'Not available';
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null ? 'Not available' : '${date.day.toString().padLeft(2, '0')}-${_monthShort(date.month)}-${date.year}';
}
