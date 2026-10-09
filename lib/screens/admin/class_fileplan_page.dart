import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';
import '../../models/school_resource.dart';
import '../../services/school_resource_service.dart';
import '../../widgets/admin_bottom_nav.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class FileItem {
  final String id;
  final String name;
  final String type; // pdf, word, powerpoint, excel, image, video, link
  final double sizeInMB;
  final DateTime uploadedDate;
  final DateTime updatedDate;
  final String folder;
  final String uploadedBy;
  final String description;
  final PlatformFile? uploadFile;

  FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeInMB,
    required this.uploadedDate,
    required this.updatedDate,
    required this.folder,
    required this.uploadedBy,
    required this.description,
    this.uploadFile,
  });

  FileItem copyWith({
    String? id,
    String? name,
    String? type,
    double? sizeInMB,
    DateTime? uploadedDate,
    DateTime? updatedDate,
    String? folder,
    String? uploadedBy,
    String? description,
    PlatformFile? uploadFile,
  }) {
    return FileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sizeInMB: sizeInMB ?? this.sizeInMB,
      uploadedDate: uploadedDate ?? this.uploadedDate,
      updatedDate: updatedDate ?? this.updatedDate,
      folder: folder ?? this.folder,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      description: description ?? this.description,
      uploadFile: uploadFile ?? this.uploadFile,
    );
  }
}

class FolderItem {
  final String id;
  final String name;
  final String description;
  final DateTime createdDate;
  final DateTime updatedDate;

  FolderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.createdDate,
    required this.updatedDate,
  });

  FolderItem copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return FolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

// ============================================================================
// CLASS FILE PLAN PAGE
// ============================================================================

class ClassFileplanPage extends StatefulWidget {
  const ClassFileplanPage({
    super.key,
    required this.group,
    this.isViewOnly = false,
    this.resourceService,
  });

  final Group group;
  final bool isViewOnly;
  final SchoolResourceService? resourceService;

  @override
  State<ClassFileplanPage> createState() => _ClassFileplanPageState();
}

class _ClassFileplanPageState extends State<ClassFileplanPage> {
  late final SchoolResourceService _resourceService =
      widget.resourceService ?? SchoolResourceService();
  List<FileItem> _allFiles = [];
  List<FolderItem> _allFolders = [];
  bool _isLoading = true;
  String? _loadError;
  String _viewMode = 'list'; // list or grid
  String _filterType = 'All'; // All, Folders, Documents, Images, Videos
  String _sortBy = 'Recently Updated'; // Recently Updated, Name A–Z, Name Z–A
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _currentFolder; // null = root, else folder id

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final resources = await _resourceService.getResources(widget.group.id);
      if (!mounted) return;
      setState(() {
        _allFiles = resources.map(_fileFromResource).toList();
        _allFolders = [];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  FileItem _fileFromResource(SchoolResource resource) {
    final fileName = resource.fileName.isNotEmpty
        ? resource.fileName
        : resource.heading;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final resourceType = resource.resourceType.toLowerCase();
    const supportedTypes = {
      'pdf',
      'word',
      'powerpoint',
      'excel',
      'image',
      'video',
      'link',
    };
    final type = supportedTypes.contains(resourceType)
        ? resourceType
        : switch (extension) {
            'pdf' => 'pdf',
            'doc' || 'docx' => 'word',
            'ppt' || 'pptx' => 'powerpoint',
            'xls' || 'xlsx' => 'excel',
            'jpg' || 'jpeg' || 'png' || 'gif' => 'image',
            'mp4' || 'mov' || 'avi' => 'video',
            _ => 'link',
          };
    final createdAt = resource.createdAt ?? DateTime.tryParse(resource.date);
    final updatedAt = resource.updatedAt ?? createdAt ?? DateTime.now();
    return FileItem(
      id: resource.id ?? '',
      name: resource.heading.isNotEmpty ? resource.heading : fileName,
      type: type,
      sizeInMB: (resource.fileSize ?? 0) / (1024 * 1024),
      uploadedDate: createdAt ?? DateTime.now(),
      updatedDate: updatedAt,
      folder: resource.resourceType,
      uploadedBy: '',
      description: resource.resourceName,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================================
  // FILTERS AND SEARCH
  // ============================================================================

  List<FileItem> _getFilteredFiles() {
    List<FileItem> files = _allFiles;

    // Filter by folder if in folder view
    if (_currentFolder != null) {
      files = files.where((f) => f.folder == _currentFolder).toList();
    }

    // Filter by type
    if (_filterType == 'Folders') {
      return []; // Show folders in separate section
    } else if (_filterType == 'Documents') {
      files = files
          .where((f) => ['pdf', 'word', 'powerpoint', 'excel'].contains(f.type))
          .toList();
    } else if (_filterType == 'Images') {
      files = files.where((f) => f.type == 'image').toList();
    } else if (_filterType == 'Videos') {
      files = files.where((f) => f.type == 'video').toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      files = files
          .where(
            (f) =>
                f.name.toLowerCase().contains(query) ||
                f.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Sort
    if (_sortBy == 'Recently Updated') {
      files.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
    } else if (_sortBy == 'Name A–Z') {
      files.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Name Z–A') {
      files.sort((a, b) => b.name.compareTo(a.name));
    }

    return files;
  }

  List<FolderItem> _getFilteredFolders() {
    if (_currentFolder != null) return [];

    List<FolderItem> folders = _allFolders;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      folders = folders
          .where(
            (f) =>
                f.name.toLowerCase().contains(query) ||
                f.description.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_sortBy == 'Recently Updated') {
      folders.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
    } else if (_sortBy == 'Name A–Z') {
      folders.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Name Z–A') {
      folders.sort((a, b) => b.name.compareTo(a.name));
    }

    return folders;
  }

  int _getFileCountForFolder(String folderId) =>
      _allFiles.where((f) => f.folder == folderId).length;

  double _getTotalSize() => _allFiles.fold(0, (sum, f) => sum + f.sizeInMB);

  List<FileItem> _getRecentFiles() {
    final files = List<FileItem>.from(_allFiles);
    files.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
    return files.take(5).toList();
  }

  String _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return '📄';
      case 'word':
        return '📝';
      case 'powerpoint':
        return '🎨';
      case 'excel':
        return '📊';
      case 'image':
        return '🖼️';
      case 'video':
        return '🎬';
      case 'link':
        return '🔗';
      default:
        return '📁';
    }
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _openAddMenu() => _openAddFileDialog();

  void _openAddFileDialog() async {
    final result = await showDialog<FileItem>(
      context: context,
      builder: (context) => const _AddFileDialog(),
    );
    if (result == null || result.uploadFile == null) return;
    try {
      await _resourceService.createResource(
        SchoolResource(
          heading: result.name,
          date: DateTime.now().toIso8601String(),
          resourceName: result.description,
          groupId: widget.group.id,
          resourceType: result.type,
        ),
        groupId: widget.group.id,
        file: result.uploadFile,
      );
      await _loadResources();
    } catch (error) {
      _showResourceError(error);
    }
  }

  void _openAddFolderDialog() async {
    final result = await showDialog<FolderItem>(
      context: context,
      builder: (context) => const _AddFolderDialog(),
    );
    if (result != null) {
      setState(() => _allFolders.add(result));
    }
  }

  void _openFileDetails(FileItem file) async {
    final result = await showDialog<FileItem?>(
      context: context,
      builder: (context) => _FileDetailsDialog(file: file),
    );
    if (result != null) _openEditFileDialog(result);
  }

  void _openEditFileDialog(FileItem file) async {
    final result = await showDialog<FileItem>(
      context: context,
      builder: (context) => _EditFileDialog(file: file),
    );
    if (result != null) {
      try {
        await _resourceService.updateResource(
          file.id,
          SchoolResource(
            heading: result.name,
            date: result.updatedDate.toIso8601String(),
            resourceName: result.description,
            groupId: widget.group.id,
            resourceType: result.folder,
          ),
          groupId: widget.group.id,
        );
        await _loadResources();
      } catch (error) {
        _showResourceError(error);
      }
    }
  }

  void _deleteFile(FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _resourceService.deleteResource(file.id, groupId: widget.group.id);
      await _loadResources();
    } catch (error) {
      _showResourceError(error);
    }
  }

  void _showResourceError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to update class resources: $error')),
    );
  }

  void _openFolderDetails(FolderItem folder) async {
    final result = await showDialog<FolderItem?>(
      context: context,
      builder: (context) => _FolderDetailsDialog(folder: folder),
    );
    if (result != null) {
      setState(() {
        final index = _allFolders.indexWhere((f) => f.id == folder.id);
        if (index >= 0) _allFolders[index] = result;
      });
    }
  }

  void _deleteFolder(FolderItem folder) {
    final fileCount = _getFileCountForFolder(folder.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: fileCount > 0
            ? Text(
                'This folder contains $fileCount file(s). Are you sure you want to delete it?',
              )
            : const Text('Are you sure you want to delete this folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allFolders.removeWhere((f) => f.id == folder.id);
                if (fileCount > 0) {
                  _allFiles.removeWhere((f) => f.folder == folder.id);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openFolder(FolderItem folder) {
    setState(() => _currentFolder = folder.id);
  }

  void _goBack() {
    setState(() => _currentFolder = null);
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final filteredFolders = _getFilteredFolders();
    final filteredFiles = _getFilteredFiles();
    final recentFiles = _getRecentFiles();
    final totalSize = _getTotalSize();

    return Scaffold(
      backgroundColor: const Color(0xfff4f5f8),
      appBar: AppBar(
        backgroundColor: const Color(0xff363b60),
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: _currentFolder != null
              ? _goBack
              : () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class File Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentFolder != null
                  ? _allFolders.firstWhere((f) => f.id == _currentFolder).name
                  : widget.group.name,
              style: const TextStyle(
                color: Color(0xffb8bcc8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 22, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load class resources.'),
                      const SizedBox(height: 8),
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadResources,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _allFiles.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open_outlined,
                        size: 48,
                        color: Color(0xffc5cad1),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No files or resources available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff363b60),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _currentFolder == null
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class File Plan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff363b60),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Class: ${widget.group.name}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff4a4a4a),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryItem(
                                    label: 'Total Files',
                                    value: '${_allFiles.length}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _SummaryItem(
                                    label: 'Total Folders',
                                    value: '${_allFolders.length}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: '🔍 Search files and folders...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff7a7a7a),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // View Mode Tabs
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _viewMode = 'list'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _viewMode == 'list'
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: _viewMode == 'list'
                                      ? Border(
                                          bottom: BorderSide(
                                            color: const Color(0xff2baac8),
                                            width: 2,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '📋 List',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _viewMode == 'list'
                                          ? const Color(0xff363b60)
                                          : const Color(0xff7a7a7a),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _viewMode = 'grid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _viewMode == 'grid'
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: _viewMode == 'grid'
                                      ? Border(
                                          bottom: BorderSide(
                                            color: const Color(0xff2baac8),
                                            width: 2,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '▦ Grid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _viewMode == 'grid'
                                          ? const Color(0xff363b60)
                                          : const Color(0xff7a7a7a),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filter and Sort
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...[
                              'All',
                              'Folders',
                              'Documents',
                              'Images',
                              'Videos',
                            ].map((filter) {
                              final isSelected = _filterType == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(filter),
                                  selected: isSelected,
                                  onSelected: (selected) =>
                                      setState(() => _filterType = filter),
                                  backgroundColor: Colors.white,
                                  selectedColor: const Color(0xff2baac8),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xff363b60),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xff2baac8)
                                        : const Color(0xffe4e6eb),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sort Dropdown
                      DropdownButton<String>(
                        value: _sortBy,
                        onChanged: (value) => setState(
                          () => _sortBy = value ?? 'Recently Updated',
                        ),
                        items: ['Recently Updated', 'Name A–Z', 'Name Z–A']
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(
                                  sort,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        underline: Container(),
                      ),
                      const SizedBox(height: 16),

                      // Folders (if in root and not filtering)
                      if (_filterType != 'Documents' &&
                          _filterType != 'Images' &&
                          _filterType != 'Videos' &&
                          filteredFolders.isNotEmpty) ...[
                        Text(
                          'Folders',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff363b60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _viewMode == 'list'
                            ? Column(
                                children: filteredFolders
                                    .map(
                                      (folder) => _buildFolderListCard(folder),
                                    )
                                    .toList(),
                              )
                            : GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.1,
                                children: filteredFolders
                                    .map(
                                      (folder) => _buildFolderGridCard(folder),
                                    )
                                    .toList(),
                              ),
                        const SizedBox(height: 16),
                      ],

                      // Files
                      if (filteredFiles.isNotEmpty) ...[
                        Text(
                          'Files',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff363b60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _viewMode == 'list'
                            ? Column(
                                children: filteredFiles
                                    .map((file) => _buildFileListCard(file))
                                    .toList(),
                              )
                            : GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.1,
                                children: filteredFiles
                                    .map((file) => _buildFileGridCard(file))
                                    .toList(),
                              ),
                        const SizedBox(height: 16),
                      ],

                      // Empty State
                      if (filteredFolders.isEmpty && filteredFiles.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.folder_open_outlined,
                                  size: 48,
                                  color: Color(0xffc5cad1),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Files Yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff363b60),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add files and folders to organize class materials.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff7a7a7a),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!widget.isViewOnly) ...[
                                      ElevatedButton.icon(
                                        onPressed: _openAddFileDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff2baac8,
                                          ),
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add File'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _openAddFolderDialog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Create Folder'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Recently Updated
                      if (recentFiles.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Recently Updated',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff363b60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: recentFiles.map((file) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _getFileIcon(file.type),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff222222),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            DateFormat(
                                              'MMM d, yyyy',
                                            ).format(file.updatedDate),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xff7a7a7a),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Storage Summary
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Files',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff363b60),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_allFiles.length} Files',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff363b60),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalSize.toStringAsFixed(1)} MB Used',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff7a7a7a),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: '🔍 Search files...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff7a7a7a),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filteredFiles.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: const Text(
                              'No files in this folder',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff7a7a7a),
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: filteredFiles
                              .map((file) => _buildFileListCard(file))
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: widget.isViewOnly
          ? null
          : FloatingActionButton(
              onPressed: _openAddMenu,
              backgroundColor: const Color(0xff2baac8),
              child: const Icon(Icons.add, size: 24),
            ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _buildFolderListCard(FolderItem folder) {
    final fileCount = _getFileCountForFolder(folder.id);
    return GestureDetector(
      onTap: () => _openFolder(folder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.folder, size: 24, color: Color(0xfff59e0b)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff222222),
                    ),
                  ),
                  Text(
                    '$fileCount Files',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff7a7a7a),
                    ),
                  ),
                  Text(
                    'Updated ${DateFormat('MMM d').format(folder.updatedDate)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff7a7a7a),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              onPressed: () => _showFolderMenu(folder),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderGridCard(FolderItem folder) {
    final fileCount = _getFileCountForFolder(folder.id);
    return GestureDetector(
      onTap: () => _openFolder(folder),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.folder, size: 32, color: Color(0xfff59e0b)),
            const SizedBox(height: 8),
            Text(
              folder.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xff222222),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$fileCount Files',
              style: const TextStyle(fontSize: 10, color: Color(0xff7a7a7a)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListCard(FileItem file) {
    return GestureDetector(
      onTap: () => _openFileDetails(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(_getFileIcon(file.type), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff222222),
                    ),
                  ),
                  Text(
                    '${file.type.toUpperCase()} • ${file.sizeInMB.toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff7a7a7a),
                    ),
                  ),
                  Text(
                    'Updated ${DateFormat('MMM d, yyyy').format(file.updatedDate)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff7a7a7a),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              onPressed: () => _showFileMenu(file),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileGridCard(FileItem file) {
    return GestureDetector(
      onTap: () => _openFileDetails(file),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getFileIcon(file.type), style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              file.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xff222222),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${file.sizeInMB.toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 9, color: Color(0xff7a7a7a)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileMenu(FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _openFileDetails(file);
              },
            ),
            if (!widget.isViewOnly)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _openEditFileDialog(file);
                },
              ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading file...')),
                );
              },
            ),
            if (!widget.isViewOnly)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFolderMenu(FolderItem folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isViewOnly)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _openFolderDetails(folder);
                },
              ),
            if (!widget.isViewOnly)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFolder(folder);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff4f5f8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff7a7a7a),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff363b60),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOGS
// ============================================================================

class _AddFileDialog extends StatefulWidget {
  const _AddFileDialog();

  @override
  State<_AddFileDialog> createState() => _AddFileDialogState();
}

class _AddFileDialogState extends State<_AddFileDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  PlatformFile? _selectedFile;

  String _resourceType(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return switch (extension) {
      'pdf' => 'pdf',
      'doc' || 'docx' => 'word',
      'ppt' || 'pptx' => 'powerpoint',
      'xls' || 'xlsx' => 'excel',
      'jpg' || 'jpeg' || 'png' || 'gif' => 'image',
      'mp4' || 'mov' || 'avi' => 'video',
      _ => 'link',
    };
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    setState(() {
      _selectedFile = file;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = file.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a file and provide its title.')),
      );
      return;
    }

    final selectedFile = _selectedFile!;
    final now = DateTime.now();
    final fileType = _resourceType(selectedFile.name);
    late final List<int> bytes;
    try {
      bytes = await selectedFile.readAsBytes();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read the selected file: $error')),
      );
      return;
    }
    if (!mounted) return;
    final newFile = FileItem(
      id: '',
      name: _nameController.text.trim(),
      type: fileType,
      sizeInMB: bytes.length / (1024 * 1024),
      uploadedDate: now,
      updatedDate: now,
      folder: fileType,
      uploadedBy: '',
      description: _descController.text.trim(),
      uploadFile: selectedFile,
    );

    Navigator.pop(context, newFile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add File'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedFile?.name ?? 'Choose a file'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2baac8),
          ),
          child: const Text('Add File'),
        ),
      ],
    );
  }
}

class _AddFolderDialog extends StatefulWidget {
  const _AddFolderDialog();

  @override
  State<_AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<_AddFolderDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter folder name')));
      return;
    }

    final newFolder = FolderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      createdDate: DateTime.now(),
      updatedDate: DateTime.now(),
    );

    Navigator.pop(context, newFolder);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Folder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2baac8),
          ),
          child: const Text('Create Folder'),
        ),
      ],
    );
  }
}

class _FileDetailsDialog extends StatelessWidget {
  final FileItem file;

  const _FileDetailsDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Name', value: file.name),
            _DetailRow(label: 'Type', value: file.type.toUpperCase()),
            _DetailRow(label: 'Size', value: '${file.sizeInMB} MB'),
            if (file.uploadedBy.isNotEmpty)
              _DetailRow(label: 'Uploaded By', value: file.uploadedBy),
            _DetailRow(
              label: 'Uploaded',
              value: DateFormat('MMM d, yyyy').format(file.uploadedDate),
            ),
            _DetailRow(
              label: 'Updated',
              value: DateFormat('MMM d, yyyy').format(file.updatedDate),
            ),
            if (file.description.isNotEmpty)
              _DetailRow(label: 'Description', value: file.description),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, file),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2baac8),
          ),
          child: const Text('Edit'),
        ),
      ],
    );
  }
}

class _EditFileDialog extends StatefulWidget {
  final FileItem file;

  const _EditFileDialog({required this.file});

  @override
  State<_EditFileDialog> createState() => _EditFileDialogState();
}

class _EditFileDialogState extends State<_EditFileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.file.name);
    _descController = TextEditingController(text: widget.file.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter file name')));
      return;
    }

    final updated = widget.file.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      updatedDate: DateTime.now(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit File'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2baac8),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _FolderDetailsDialog extends StatefulWidget {
  final FolderItem folder;

  const _FolderDetailsDialog({required this.folder});

  @override
  State<_FolderDetailsDialog> createState() => _FolderDetailsDialogState();
}

class _FolderDetailsDialogState extends State<_FolderDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _descController = TextEditingController(text: widget.folder.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter folder name')));
      return;
    }

    final updated = widget.folder.copyWith(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      updatedDate: DateTime.now(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Folder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2baac8),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Color(0xff7a7a7a),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
          ),
        ],
      ),
    );
  }
}
