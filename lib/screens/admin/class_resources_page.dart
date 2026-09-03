import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/group.dart';
import '../../models/school_resource.dart';
import '../../services/school_resource_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassResourcesPage extends StatefulWidget {
  const ClassResourcesPage({super.key, required this.group, this.isViewOnly = false});

  final Group group;
  final bool isViewOnly;

  @override
  State<ClassResourcesPage> createState() => _ClassResourcesPageState();
}

class _ClassResourcesPageState extends State<ClassResourcesPage> {
  final _service = SchoolResourceService();
  final _searchController = TextEditingController();
  final _filters = ['All', 'PDF', 'Documents', 'Images', 'Videos', 'Links'];
  String _selectedFilter = 'All';
  bool _loading = true;
  String? _error;
  List<SchoolResource> _resources = const [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
        final groupId = widget.group.id.trim().isNotEmpty
          ? widget.group.id.trim()
          : widget.group.name.trim();
        final data = await _service.getResources(groupId);
      if (!mounted) return;
      setState(() {
        _resources = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resources = const [];
        _error = 'Unable to load class resources right now.';
        _loading = false;
      });
    }
  }

  List<SchoolResource> get _filteredResources {
    final query = _searchController.text.trim().toLowerCase();
    final list = _resources.where((resource) {
      final matchesFilter = _matchesFilter(resource, _selectedFilter);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final haystack = '${resource.heading} ${resource.resourceName} ${resource.date}'.toLowerCase();
      return haystack.contains(query);
    }).toList();

    return list;
  }

  bool _matchesFilter(SchoolResource resource, String filter) {
    if (filter == 'All') return true;
    final type = _resourceType(resource).toLowerCase();
    switch (filter.toLowerCase()) {
      case 'pdf':
        return type == 'pdf';
      case 'documents':
        return type == 'document';
      case 'images':
        return type == 'image';
      case 'videos':
        return type == 'video';
      case 'links':
        return type == 'link';
      default:
        return true;
    }
  }

  String _resourceType(SchoolResource resource) {
    if (resource.resourceType.trim().isNotEmpty) return resource.resourceType.trim();
    final value = (resource.fileName.isNotEmpty
            ? resource.fileName
            : (resource.imageUrl.isNotEmpty ? resource.imageUrl : resource.resourceName))
        .toLowerCase();
    if (value.contains('.pdf') || resource.heading.toLowerCase().contains('pdf')) {
      return 'PDF';
    }
    if (value.contains('.mp4') || value.contains('.mov') || value.contains('.avi') || value.contains('video')) {
      return 'Video';
    }
    if (value.contains('.jpg') || value.contains('.jpeg') || value.contains('.png') || value.contains('.gif') || value.contains('image')) {
      return 'Image';
    }
    if (value.startsWith('http://') || value.startsWith('https://') || value.contains('://')) {
      return 'Link';
    }
    return 'Document';
  }

  IconData _resourceIcon(SchoolResource resource) {
    switch (_resourceType(resource)) {
      case 'PDF':
        return Icons.picture_as_pdf_outlined;
      case 'Video':
        return Icons.videocam_outlined;
      case 'Image':
        return Icons.image_outlined;
      case 'Link':
        return Icons.link_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _resourceColor(SchoolResource resource) {
    switch (_resourceType(resource)) {
      case 'PDF':
        return const Color(0xFFDC2626);
      case 'Video':
        return const Color(0xFF7C3AED);
      case 'Image':
        return const Color(0xFF16A34A);
      case 'Link':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF475569);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _fileExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }

  Future<void> _showAddOrEditDialog({SchoolResource? resource}) async {
    final titleController = TextEditingController(text: resource?.heading ?? '');
    final descriptionController = TextEditingController(text: resource?.resourceName ?? '');
    final linkController = TextEditingController(text: resource?.imageUrl ?? '');
    PlatformFile? selectedFile;
    final type = ValueNotifier<String>(_resourceType(resource ?? const SchoolResource(
      heading: '',
      date: '',
      resourceName: '',
    )));

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final options = ['PDF', 'Document', 'Image', 'Video', 'Link'];
          return AlertDialog(
            title: Text(resource == null ? 'Add Resource' : 'Edit Resource'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Resource title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Resource type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final selected = type.value == option;
                      return ChoiceChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (_) => setState(() => type.value = option),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(labelText: 'External link or upload URL'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resource == null ? 'Upload file' : 'Replace uploaded file',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        allowMultiple: false,
                      );
                      if (result.isEmpty) return;
                      setState(() => selectedFile = result.first);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: selectedFile == null
                                ? const Text('Choose file')
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder<int>(
                                        future: selectedFile!.length(),
                                        builder: (context, snapshot) {
                                          final extension = _fileExtension(selectedFile!.name);
                                          final size = snapshot.hasData
                                              ? ' · ${_formatFileSize(snapshot.data!)}'
                                              : '';
                                          return Text(
                                            '${extension.isEmpty ? 'Unknown' : extension.toUpperCase()}$size',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(resource == null ? 'Save' : 'Update'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || result != true) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final link = linkController.text.trim();
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a resource title.')),
        );
      }
      return;
    }

    if (selectedFile == null && resource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a file.')),
      );
      return;
    }

    final payload = SchoolResource(
      id: resource?.id,
      heading: title,
      date: resource?.date ?? DateFormat('dd-MMM-yyyy').format(DateTime.now()),
      resourceName: description.isNotEmpty ? description : title,
      imageUrl: link,
      groupId: widget.group.id.trim().isNotEmpty ? widget.group.id.trim() : widget.group.name.trim(),
      resourceType: type.value,
      fileName: selectedFile?.name ?? resource?.fileName ?? '',
      fileSize: selectedFile == null ? resource?.fileSize : await selectedFile!.length(),
    );

    try {
      if (resource == null || resource.id == null) {
        await _service.createResource(
          payload,
          groupId: payload.groupId,
          file: selectedFile!,
        );
      } else {
        await _service.updateResource(
          resource.id!,
          payload,
          groupId: payload.groupId,
        );
      }
      if (!mounted) return;
      await _loadResources();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resource == null ? 'Resource added.' : 'Resource updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the resource.')),
      );
    }
  }

  Future<void> _deleteResource(SchoolResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: const Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || resource.id == null) return;

    try {
      await _service.deleteResource(
        resource.id!,
        groupId: resource.groupId,
      );
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

  Future<void> _openResource(SchoolResource resource) async {
    final url = resource.imageUrl.trim();
    final type = _resourceType(resource);
    if (type == 'Image' && url.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: const Color(0xff34395f),
                  automaticallyImplyLeading: false,
                  title: Text(resource.heading),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(
                  height: 260,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 42)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if ((type == 'PDF' || type == 'Document' || type == 'Video' || type == 'Link') && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This resource URL is invalid.')),
          );
        }
        return;
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open the resource.')),
          );
        }
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resource link is available yet.')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_outlined, size: 56, color: Color(0xff9ca3af)),
            const SizedBox(height: 18),
            const Text(
              'No Resources Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xff1f2937)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add notes, study materials, videos, documents or useful links for this class.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xff6b7280), height: 1.45),
            ),
            const SizedBox(height: 22),
            if (!widget.isViewOnly) FilledButton.icon(
              onPressed: () => _showAddOrEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('+ Add Resource'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(SchoolResource resource) {
    final type = _resourceType(resource);
    final color = _resourceColor(resource);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_resourceIcon(resource), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        resource.heading,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937)),
                      ),
                    ),
                    if (!widget.isViewOnly) PopupMenuButton<String>(
                      tooltip: 'More options',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAddOrEditDialog(resource: resource);
                            break;
                          case 'replace':
                            _showAddOrEditDialog(resource: resource);
                            break;
                          case 'download':
                            _openResource(resource);
                            break;
                          case 'delete':
                            _deleteResource(resource);
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'replace', child: Text('Replace File')),
                        PopupMenuItem(value: 'download', child: Text('Download')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MetaPill(type),
                    const SizedBox(width: 6),
                    if (resource.fileSize != null)
                      _MetaPill(_formatFileSize(resource.fileSize!)),
                  ],
                ),
                const SizedBox(height: 8),
                if (resource.resourceName.trim().isNotEmpty)
                  Text(
                    resource.resourceName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xff6b7280), height: 1.45),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xff64748b)),
                    const SizedBox(width: 6),
                    Text(
                      resource.date.isNotEmpty ? resource.date : 'Added recently',
                      style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: FilledButton.tonal(
                          onPressed: () => _openResource(resource),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xffe0f2fe),
                            foregroundColor: const Color(0xff0f172a),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('View/Open'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryCount = _filteredResources.length;
    final headerSubtitle = [
      if (widget.group.type.isNotEmpty && widget.group.type != 'Other') widget.group.type,
      if (widget.group.code.isNotEmpty) widget.group.code,
      if (widget.group.year.isNotEmpty) widget.group.year,
    ].join(' • ');

    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            if (headerSubtitle.isNotEmpty)
              Text(
                headerSubtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xffdce7ff)),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$summaryCount Resources',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff1f2937)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffeef2ff),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Class Files',
                      style: TextStyle(fontSize: 11, color: Color(0xff3730a3), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search resources...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xff64748b)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff34395f)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    selectedColor: const Color(0xff34395f),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xff374151),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error!, textAlign: TextAlign.center),
                          ),
                        )
                      : _filteredResources.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                              children: _filteredResources.map(_buildResourceCard).toList(),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isViewOnly ? null : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddOrEditDialog(),
          backgroundColor: const Color(0xff34395f),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Resource'),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xff475569)),
      ),
    );
  }
}
