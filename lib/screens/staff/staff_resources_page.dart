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
                _shortStaffDate(resource.createdAt),
                style: const TextStyle(fontSize: 7, color: Color(0xff555555)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StaffResourceAction(
                    tooltip: 'View slip/report image',
                    icon: Icons.visibility_outlined,
                    onPressed: () => _viewImage(context),
                  ),
                  _StaffResourceAction(
                    tooltip: 'View resource details',
                    icon: Icons.info_outline,
                    onPressed: () => _showDetails(context),
                  ),
                  _StaffResourceAction(
                    tooltip: 'Open resource',
                    icon: Icons.download_outlined,
                    onPressed: () => _openResource(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _viewImage(BuildContext context) {
    if (resource.slipReportImageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image available for this resource.')));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520, maxWidth: 700),
            child: Image.network(
              resource.slipReportImageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
              errorBuilder: (_, error, stack) => const Center(child: Text('Image unavailable.')),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resource Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLine('Description', resource.description),
              _detailLine('Resource Link', resource.link),
              _detailLine('Image URL', resource.slipReportImageUrl),
              _detailLine('Created Date', _formatDate(resource.createdAt)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Expanded(child: Text(value.isEmpty ? 'Not available' : value)),
          ],
        ),
      );

  Future<void> _openResource(BuildContext context) async {
    final value = resource.slipReportImageUrl.trim().isNotEmpty
        ? resource.slipReportImageUrl.trim()
        : resource.link.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No downloadable file available.')));
      return;
    }
    final opened = await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open resource.')));
    }
  }
}

class _StaffResourceAction extends StatelessWidget {
  const _StaffResourceAction({required this.tooltip, required this.icon, required this.onPressed});
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

String _formatDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Created date unavailable';
  return 'Created ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

String _shortStaffDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Date unavailable';
  return '${date.day.toString().padLeft(2, '0')}-${_shortMonth(date.month)}-${date.year.toString().substring(2)}';
}

String _shortMonth(int month) => const [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][month];

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.action});
  final String message;
  final VoidCallback action;
  @override
  Widget build(BuildContext context) => Column(children: [Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), TextButton(onPressed: action, child: const Text('Retry'))]);
}
