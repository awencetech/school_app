import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/class_news.dart';
import '../../models/class_photo.dart';
import '../../models/group.dart';
import '../../services/class_content_service.dart';
import '../../services/app_state.dart';
import '../../services/group_service.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassNewsPage extends StatefulWidget {
  const ClassNewsPage({super.key, required this.group, this.isViewOnly = false});

  final Group group;
  final bool isViewOnly;

  @override
  State<ClassNewsPage> createState() => _ClassNewsPageState();
}

class _ClassNewsPageState extends State<ClassNewsPage> {
  final _service = ClassContentService();
  final _groupService = GroupService();
  late Group _activeGroup;
  int _selectedTab = 0; // 0: Gallery, 1: News
  List<ClassPhoto> _photos = [];
  List<ClassNews> _newsList = [];
  List<ClassNews> _filteredNews = [];
  bool _loading = true;
  String? _error;
  bool _uploading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeGroup = widget.group;
    _loadContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_activeGroup.id.toLowerCase() == 'unknown') {
        final groups = await _groupService.getGroups(refresh: true);
        if (groups.isNotEmpty) _activeGroup = groups.first;
      }
      debugPrint('ClassNewsPage: Loading content for group ${_activeGroup.id} (${_activeGroup.name})');
      final photosFuture = _service.getPhotosForGroup(_activeGroup.id);
      final newsFuture = _service.getNewsForGroup(_activeGroup.id);

      final results = await Future.wait([photosFuture, newsFuture]);
      final photos = results[0] as List<ClassPhoto>;
      final news = results[1] as List<ClassNews>;

      debugPrint('ClassNewsPage: Loaded ${photos.length} photos and ${news.length} news items');

      if (mounted) {
        setState(() {
          _photos = photos;
          _newsList = news;
          _filteredNews = news;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ClassNewsPage: Error loading content: $e');
      if (mounted) {
        final errorMsg = _extractErrorMessage(e.toString());
        setState(() {
          _error = errorMsg;
          _loading = false;
        });
      }
    }
  }

  String _extractErrorMessage(String error) {
    // Extract meaningful error message from exception
    if (error.contains('Unable to')) {
      return error.substring(error.indexOf('Unable to'));
    }
    if (error.contains('ApiException')) {
      final match = RegExp(r'ApiException\((\d+)\):\s*(.+?)\s*at').firstMatch(error);
      if (match != null) {
        return '${match.group(2)} (Error ${match.group(1)})';
      }
    }
    return error.length > 100 ? '${error.substring(0, 100)}...' : error;
  }

  void _filterNews(String query) {
    if (query.isEmpty) {
      setState(() => _filteredNews = _newsList);
    } else {
      final lower = query.toLowerCase();
      setState(() {
        _filteredNews = _newsList
            .where((news) =>
                news.title.toLowerCase().contains(lower) ||
                news.description.toLowerCase().contains(lower))
            .toList();
      });
    }
  }

  void _sortNews(String sortType) {
    setState(() {
      if (sortType == 'latest') {
        _filteredNews.sort((a, b) =>
            (b.publishedAt ?? b.createdAt ?? DateTime.now())
                .compareTo(a.publishedAt ?? a.createdAt ?? DateTime.now()));
      } else {
        _filteredNews.sort((a, b) =>
            (a.publishedAt ?? a.createdAt ?? DateTime.now())
                .compareTo(b.publishedAt ?? b.createdAt ?? DateTime.now()));
      }
    });
  }

  Future<void> _uploadPhotos() async {
    try {
      final uploadedBy = context.read<AppState>().currentUserId ?? '';
      // ignore: deprecated_member_use
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: true);
      if (result.isEmpty) return;

      if (mounted) setState(() => _uploading = true);

      for (final file in result) {
        final bytes = await file.readAsBytes();
        await _service.uploadPhoto(
          _activeGroup.id,
          file.name,
          bytes,
          caption: '',
          uploadedBy: uploadedBy,
        );
      }

      if (mounted) {
        await _loadContent();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload photos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editPhotoCaption(ClassPhoto photo) async {
    final controller = TextEditingController(text: photo.caption);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter caption...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _service.updatePhotoCaption(
        _activeGroup.id,
        photo.id,
        controller.text.trim(),
      );
      if (!mounted) return;
      await _loadContent();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption updated!')),
      );
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update caption: $e')),
      );
    }
    controller.dispose();
  }

  Future<void> _deletePhoto(ClassPhoto photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deletePhoto(_activeGroup.id, photo.id);
      if (!mounted) return;
      await _loadContent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete photo: $e')),
      );
    }
  }

  Future<void> _showAddNewsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddNewsDialog(
        service: _service,
        groupId: _activeGroup.id,
        onSave: _loadContent,
      ),
    );
  }

  Future<void> _showEditNewsDialog(ClassNews news) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditNewsDialog(
        service: _service,
        groupId: _activeGroup.id,
        news: news,
        onSave: _loadContent,
      ),
    );
  }

  Future<void> _deleteNews(ClassNews news) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News?'),
        content: const Text('Are you sure you want to delete this news?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteNews(_activeGroup.id, news.id);
      if (mounted) {
        await _loadContent();
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('News deleted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete news: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerSubtitle = [
      if (_activeGroup.type.isNotEmpty && _activeGroup.type != 'Other')
        _activeGroup.type,
      if (_activeGroup.code.isNotEmpty) _activeGroup.code,
      if (_activeGroup.year.isNotEmpty) _activeGroup.year,
    ].join(' • ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeGroup.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (headerSubtitle.isNotEmpty)
              Text(
                headerSubtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
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
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Content',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadContent,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Tabs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _TabChip(
                            label: '📸 Gallery',
                            isSelected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _TabChip(
                            label: '📰 News',
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildGallerySection()
                          : _buildNewsSection(),
                    ),
                  ],
                ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _buildGallerySection() {
    if (_photos.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Photos Yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add class photos to share updates and memories with students.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 32),
              if (!widget.isViewOnly) ElevatedButton.icon(
                onPressed: _uploading ? null : _uploadPhotos,
                icon: const Icon(Icons.add),
                label: Text(
                  _uploading ? 'Uploading...' : '+ Add Photos',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.blueButton,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) =>
                _PhotoGridItem(
                  photo: _photos[index],
                  onViewTap: () => _showPhotoPreview(_photos[index]),
                  onEditTap: () => _editPhotoCaption(_photos[index]),
                  onDeleteTap: () => _deletePhoto(_photos[index]),
                  isViewOnly: widget.isViewOnly,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: widget.isViewOnly ? const SizedBox.shrink() : ElevatedButton.icon(
            onPressed: _uploading ? null : _uploadPhotos,
            icon: const Icon(Icons.add),
            label: Text(
              _uploading ? 'Uploading...' : '+ Add Photos',
              style: GoogleFonts.poppins(),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppColors.blueButton,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection() {
    return Column(
      children: [
        // Search and Sort
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterNews,
                  decoration: InputDecoration(
                    hintText: '🔍 Search news...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: _sortNews,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'latest',
                    child: Text(
                      'Latest',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest',
                    child: Text(
                      'Oldest',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.sort,
                    size: 20,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // News List
        Expanded(
          child: _filteredNews.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        Center(
                          child: Icon(
                            Icons.newspaper_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No News Yet',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create news and announcements for this class.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!widget.isViewOnly) ElevatedButton.icon(
                          onPressed: _showAddNewsDialog,
                          icon: const Icon(Icons.add),
                          label: Text(
                            '+ Add News',
                            style: GoogleFonts.poppins(),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.blueButton,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredNews.length,
                  itemBuilder: (context, index) =>
                      _NewsCard(
                        news: _filteredNews[index],
                        onEditTap: () =>
                            _showEditNewsDialog(_filteredNews[index]),
                        onDeleteTap: () =>
                            _deleteNews(_filteredNews[index]),
                        isViewOnly: widget.isViewOnly,
                      ),
                ),
        ),
        // Add News Button
        if (_filteredNews.isNotEmpty && !widget.isViewOnly)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: ElevatedButton.icon(
              onPressed: _showAddNewsDialog,
              icon: const Icon(Icons.add),
              label: Text(
                '+ Add News',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.blueButton,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(0),
              ),
            ),
          ),
      ],
    );
  }

  void _showPhotoPreview(ClassPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.image_not_supported, size: 64),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photo.caption.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            'Caption',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            photo.caption,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    if (photo.uploadedAt != null)
                      Text(
                        'Uploaded: ${DateFormat('MMM dd, yyyy').format(photo.uploadedAt!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== HELPER WIDGETS =====================

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.primaryText,
        ),
      ),
      onSelected: (_) => onTap(),
      selected: isSelected,
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.blueButton,
      side: BorderSide(
        color: isSelected ? AppColors.blueButton : AppColors.divider,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  const _PhotoGridItem({
    required this.photo,
    required this.onViewTap,
    required this.onEditTap,
    required this.onDeleteTap,
    this.isViewOnly = false,
  });

  final ClassPhoto photo;
  final VoidCallback onViewTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final bool isViewOnly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
          ),
          child: Stack(
            children: [
            // Image
            CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 32),
              ),
            ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            // Info and Actions
            if (!isViewOnly) Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.caption.isNotEmpty)
                      Text(
                        photo.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (photo.uploadedAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(photo.uploadedAt!),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Action Buttons
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      onViewTap();
                      break;
                    case 'edit':
                      onEditTap();
                      break;
                    case 'delete':
                      onDeleteTap();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Text('View', style: GoogleFonts.poppins(fontSize: 11)),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Caption', style: GoogleFonts.poppins(fontSize: 11)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
                    ),
                  ),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.news,
    required this.onEditTap,
    required this.onDeleteTap,
    this.isViewOnly = false,
  });

  final ClassNews news;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final bool isViewOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (news.imageUrl.isNotEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: news.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  news.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Published: ${DateFormat('MMM dd, yyyy').format(news.publishedAt ?? news.createdAt ?? DateTime.now())}',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColors.hintText,
                  ),
                ),
                const SizedBox(height: 12),
                if (!isViewOnly) Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEditTap,
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text('Edit', style: GoogleFonts.poppins(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.blueButton,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onDeleteTap,
                      icon: const Icon(Icons.delete, size: 16),
                      label: Text('Delete', style: GoogleFonts.poppins(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: Colors.red,
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
}

class _AddNewsDialog extends StatefulWidget {
  const _AddNewsDialog({
    required this.service,
    required this.groupId,
    required this.onSave,
  });

  final ClassContentService service;
  final String groupId;
  final Future<void> Function() onSave;

  @override
  State<_AddNewsDialog> createState() => _AddNewsDialogState();
}

class _AddNewsDialogState extends State<_AddNewsDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _publishDate = DateTime.now();
  String _imageUrl = '';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty) return;

      final file = result.first;
      final bytes = await file.readAsBytes();

      setState(() => _saving = true);
      final url = await widget.service.uploadNewsImage(file.name, bytes);
      if (mounted) {
        setState(() => _imageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      setState(() => _publishDate = picked);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final news = ClassNews(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: widget.groupId,
        title: title,
        description: description,
        imageUrl: _imageUrl,
        publishedAt: _publishDate,
      );

      await widget.service.createNews(
        widget.groupId,
        news,
        publishedBy: context.read<AppState>().currentUserId ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News published!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add News', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'News Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Publish Date: ${DateFormat('MMM dd, yyyy').format(_publishDate)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_imageUrl.isEmpty ? 'Add Image' : 'Change Image'),
            ),
            if (_imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _imageUrl,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _publish,
          child: Text(_saving ? 'Publishing...' : 'Publish'),
        ),
      ],
    );
  }
}

class _EditNewsDialog extends StatefulWidget {
  const _EditNewsDialog({
    required this.service,
    required this.groupId,
    required this.news,
    required this.onSave,
  });

  final ClassContentService service;
  final String groupId;
  final ClassNews news;
  final Future<void> Function() onSave;

  @override
  State<_EditNewsDialog> createState() => _EditNewsDialogState();
}

class _EditNewsDialogState extends State<_EditNewsDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _publishDate;
  late String _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.news.title);
    _descriptionController = TextEditingController(text: widget.news.description);
    _publishDate = widget.news.publishedAt ?? widget.news.createdAt ?? DateTime.now();
    _imageUrl = widget.news.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty) return;

      final file = result.first;
      final bytes = await file.readAsBytes();

      setState(() => _saving = true);
      final url = await widget.service.uploadNewsImage(file.name, bytes);
      if (mounted) {
        setState(() => _imageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      setState(() => _publishDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final updatedNews = widget.news.copyWith(
        title: title,
        description: description,
        imageUrl: _imageUrl,
        publishedAt: _publishDate,
      );

      await widget.service.updateNews(widget.groupId, updatedNews);

      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSave();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('News updated!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit News', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'News Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Publish Date: ${DateFormat('MMM dd, yyyy').format(_publishDate)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: Text(_imageUrl.isEmpty ? 'Add Image' : 'Change Image'),
            ),
            if (_imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _imageUrl = ''),
                      child: const Text('Remove Image'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _saveChanges,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
