import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/school_resource.dart';
import '../../services/school_resource_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class SchoolResourcesEditPage extends StatefulWidget {
  const SchoolResourcesEditPage({super.key});

  @override
  State<SchoolResourcesEditPage> createState() => _SchoolResourcesEditPageState();
}

class _SchoolResourcesEditPageState extends State<SchoolResourcesEditPage> {
  final _service = SchoolResourceService();
  List<SchoolResource> _resources = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getResources();
      if (!mounted) return;
      setState(() {
        _resources = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resources = const [];
        _error = 'Unable to load school resources.';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({SchoolResource? resource}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SchoolResourceFormDialog(resource: resource),
    );

    if (result == true) {
      await _loadResources();
    }
  }

  Future<void> _deleteResource(SchoolResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || resource.id == null || resource.id!.isEmpty) return;

    try {
      await _service.deleteResource(resource.id!);
      if (!mounted) return;
      setState(() => _resources.removeWhere((item) => item.id == resource.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the resource.')),
      );
    }
  }

  Future<void> _downloadResource(SchoolResource resource) async {
    final url = resource.imageUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resource URL is available for download.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme || (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The resource URL is invalid.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the resource link.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download the resource.')),
      );
    }
  }

  void _showPreviewDialog(SchoolResource resource) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resource Preview'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.heading,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (resource.imageUrl.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: resource.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 220,
                      placeholder: (_, _) => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: 220,
                        color: const Color(0xffeef2f7),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffeef2f7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No image available'),
                  ),
              ],
            ),
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
        title: Text(resource.heading),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Description / Resource Name', value: resource.resourceName),
              _InfoRow(label: 'Loaded By', value: 'Not available'),
              _InfoRow(
                label: 'Created On',
                value: resource.createdAt != null
                    ? DateFormat('dd-MMM-yyyy').format(resource.createdAt!)
                    : _formatDate(resource.date),
              ),
              _InfoRow(label: 'Resource URL', value: resource.imageUrl.isNotEmpty ? resource.imageUrl : 'N/A'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd-MMM-yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('School Resources Edit'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _loadResources,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _resources.isEmpty
                    ? const Center(child: Text('No resources available'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _resources.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final resource = _resources[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (resource.imageUrl.trim().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: resource.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => const SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (_, _, _) => Container(
                                          width: 70,
                                          height: 70,
                                          color: const Color(0xffeef2f7),
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffeef2f7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.insert_drive_file_outlined),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resource.heading,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(resource.date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff4b5563),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          resource.resourceName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            IconButton(
                                              tooltip: 'View',
                                              onPressed: () => _showPreviewDialog(resource),
                                              icon: const Icon(Icons.visibility),
                                              color: AppColors.primary,
                                            ),
                                            IconButton(
                                              tooltip: 'Information',
                                              onPressed: () => _showInfoDialog(resource),
                                              icon: const Icon(Icons.info_outline),
                                              color: AppColors.primary,
                                            ),
                                            IconButton(
                                              tooltip: 'Delete',
                                              onPressed: () => _deleteResource(resource),
                                              icon: const Icon(Icons.delete_outline),
                                              color: Colors.red.shade700,
                                            ),
                                            IconButton(
                                              tooltip: 'Edit',
                                              onPressed: () => _openForm(resource: resource),
                                              icon: const Icon(Icons.edit_outlined),
                                              color: AppColors.primary,
                                            ),
                                            IconButton(
                                              tooltip: 'Download',
                                              onPressed: () => _downloadResource(resource),
                                              icon: const Icon(Icons.download_outlined),
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('+ Add Resource'),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SchoolResourceFormDialog extends StatefulWidget {
  const _SchoolResourceFormDialog({this.resource});

  final SchoolResource? resource;

  @override
  State<_SchoolResourceFormDialog> createState() => _SchoolResourceFormDialogState();
}

class _SchoolResourceFormDialogState extends State<_SchoolResourceFormDialog> {
  final _headingController = TextEditingController();
  final _resourceNameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _dateController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final resource = widget.resource;
    if (resource != null) {
      _headingController.text = resource.heading;
      _resourceNameController.text = resource.resourceName;
      _imageUrlController.text = resource.imageUrl;
      _dateController.text = resource.date;
    }
  }

  @override
  void dispose() {
    _headingController.dispose();
    _resourceNameController.dispose();
    _imageUrlController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  Future<void> _save() async {
    final heading = _headingController.text.trim();
    final resourceName = _resourceNameController.text.trim();
    final date = _dateController.text.trim();

    if (heading.isEmpty || resourceName.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heading, Date, and Resource Name are required.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final service = SchoolResourceService();
      final payload = SchoolResource(
        id: widget.resource?.id,
        heading: heading,
        date: date,
        resourceName: resourceName,
        imageUrl: _imageUrlController.text.trim(),
      );

      if (widget.resource == null) {
        await service.createResource(payload);
      } else if (widget.resource!.id != null && widget.resource!.id!.isNotEmpty) {
        await service.updateResource(widget.resource!.id!, payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.resource == null
                ? 'Resource saved successfully.'
                : 'Resource updated successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the resource.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.resource != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Resource' : 'Add Resource',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _headingController,
                  decoration: const InputDecoration(labelText: 'Heading *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _resourceNameController,
                  decoration: const InputDecoration(labelText: 'Resource Name *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving...' : isEditing ? 'Save Changes' : 'Save Resource'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
