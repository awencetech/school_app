import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/staff_resource.dart';
import '../../services/app_state.dart';
import '../../services/staff_resource_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

class StaffResourcesPage extends StatefulWidget {
  const StaffResourcesPage({super.key});

  @override
  State<StaffResourcesPage> createState() => _StaffResourcesPageState();
}

class _StaffResourcesPageState extends State<StaffResourcesPage> {
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
    final token = context.read<AppState>().currentAuthToken?.trim() ?? '';
    if (token.isEmpty) {
      setState(() { _loading = false; _error = 'Please sign in again to view staff resources.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resources = await _service.getMyResources(token: token);
      if (mounted) setState(() { _resources = resources; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffId = context.watch<AppState>().currentUserId ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Resources')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  const Text('Staff Resources', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  if (staffId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Staff ID: $staffId', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 18),
                  if (_error != null)
                    _Message(message: _error!, action: _load)
                  else if (_resources.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 70), child: Center(child: Text('No resources available.')))
                  else
                    ..._resources.map((resource) => _StaffResourceCard(resource: resource)),
                ],
              ),
      ),
      bottomNavigationBar: const StaffFooter(currentIndex: 0),
    );
  }
}

class _StaffResourceCard extends StatelessWidget {
  const _StaffResourceCard({required this.resource});
  final StaffResource resource;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(resource.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (resource.link.isNotEmpty)
              TextButton.icon(onPressed: () => launchUrl(Uri.parse(resource.link), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const Text('Open resource link')),
            if (resource.slipReportImageUrl.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: SizedBox(height: 170, width: double.infinity, child: Image.network(resource.slipReportImageUrl, fit: BoxFit.contain, errorBuilder: (_, error, stack) => const Center(child: Text('Image unavailable.'))))),
            const SizedBox(height: 8),
            Text(_formatDate(resource.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

String _formatDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Created date unavailable';
  return 'Created ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.action});
  final String message;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Column(children: [Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), TextButton(onPressed: action, child: const Text('Retry'))]);
}
