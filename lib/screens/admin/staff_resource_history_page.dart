import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/staff_info.dart';
import '../../models/staff_resource.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_resource_service.dart';
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
                    ..._resources.map((resource) => _HistoryCard(resource: resource)),
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
  const _HistoryCard({required this.resource});
  final StaffResource resource;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(resource.description, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (resource.link.isNotEmpty) TextButton.icon(onPressed: () => launchUrl(Uri.parse(resource.link), mode: LaunchMode.externalApplication), icon: const Icon(Icons.link), label: const Text('Open resource link')),
            if (resource.slipReportImageUrl.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: SizedBox(height: 150, width: double.infinity, child: Image.network(resource.slipReportImageUrl, fit: BoxFit.contain, errorBuilder: (_, error, stack) => const Center(child: Text('Image unavailable.'))))),
            const SizedBox(height: 8),
            Text(_formatHistoryDate(resource.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

String _formatHistoryDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Created date unavailable';
  return 'Created ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
