import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/school_resource.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_resource_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import 'package:provider/provider.dart';

class SchoolResourcesPage extends StatefulWidget {
  const SchoolResourcesPage({super.key});

  @override
  State<SchoolResourcesPage> createState() => _SchoolResourcesPageState();
}

class _SchoolResourcesPageState extends State<SchoolResourcesPage> {
  final _service = SchoolResourceService();
  bool _loading = true;
  List<SchoolResource> _resources = const [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getResources();
      if (!mounted) return;
      setState(() {
        _resources = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resources = const [];
        _loading = false;
      });
    }
  }

  Future<void> _handleBottomNavigation(int index) async {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.staffOverviewDashboard,
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.staffDashboard,
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.staffAnnouncements,
          (route) => false,
        );
        break;
      case 3:
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.staffResources,
          (route) => false,
        );
        break;
      case 4:
        await context.read<AppState>().logout();
        if (!mounted) return;
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
        break;
    }
  }

  void _showPreviewDialog(SchoolResource resource) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resource Preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resource.heading,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(resource.resourceName),
              const SizedBox(height: 8),
              Text(_formatDate(resource.date)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(SchoolResource resource) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resource Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Title', value: resource.heading),
              _InfoRow(label: 'Resource Name', value: resource.resourceName),
              _InfoRow(label: 'Date', value: _formatDate(resource.date)),
              _InfoRow(label: 'Image URL', value: resource.imageUrl.isNotEmpty ? resource.imageUrl : 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadResource(SchoolResource resource) async {
    final url = resource.imageUrl.trim();
    if (url.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file is attached for this resource.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The attached resource URL is invalid.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the resource.')),
      );
    }
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd-MMM-yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 42,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(7, 7, 7, 5),
            child: Text('Resource List', style: TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _resources.isEmpty
                    ? const Center(child: Text('No resources available'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
                        itemCount: _resources.length,
                        itemBuilder: (context, index) => _SchoolResourceRow(
                          resource: _resources[index],
                          onView: _showPreviewDialog,
                          onInfo: _showInfoDialog,
                          onDownload: _downloadResource,
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: _handleBottomNavigation,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(height: 2),
          SelectableText(value, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _SchoolResourceRow extends StatelessWidget {
  const _SchoolResourceRow({
    required this.resource,
    required this.onView,
    required this.onInfo,
    required this.onDownload,
  });

  final SchoolResource resource;
  final void Function(SchoolResource resource) onView;
  final void Function(SchoolResource resource) onInfo;
  final Future<void> Function(SchoolResource resource) onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resource.heading,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff173c70),
            ),
          ),
          if (resource.resourceName.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                resource.resourceName,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff555555),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              resource.date,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff555555),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ResourceAction(
                icon: Icons.visibility_outlined,
                size: 18,
                onTap: () => onView(resource),
              ),
              _ResourceAction(
                icon: Icons.info_outline,
                size: 18,
                onTap: () => onInfo(resource),
              ),
              _ResourceAction(
                icon: Icons.delete_outline,
                size: 18,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete is available in the admin editor.'),
                    ),
                  );
                },
              ),
              _ResourceAction(
                icon: Icons.edit_outlined,
                size: 18,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit is available in the admin editor.'),
                    ),
                  );
                },
              ),
              _ResourceAction(
                icon: Icons.download_outlined,
                size: 18,
                onTap: () => onDownload(resource),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({
    required this.icon,
    required this.onTap,
    this.size = 16,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, size: size, color: const Color(0xff777777)),
      ),
    );
  }
}
