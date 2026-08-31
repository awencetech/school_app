import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/newsletter.dart';
import '../../routes/app_routes.dart';
import '../../services/newsletter_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class NewsletterEditPage extends StatefulWidget {
  const NewsletterEditPage({super.key});

  @override
  State<NewsletterEditPage> createState() => _NewsletterEditPageState();
}

class _NewsletterEditPageState extends State<NewsletterEditPage> {
  final _service = NewsletterService();
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  final List<_NewsletterSectionDraft> _sections = [];
  String _imageUrl = '';
  bool _loading = true;
  bool _saving = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadNewsletters();
  }

  @override
  void dispose() {
    _headingController.dispose();
    _introductionController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNewsletters() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getNewsletters();
      if (!mounted) return;
      if (items.isNotEmpty) {
        final item = items.first;
        _selectedId = item.id;
        _headingController.text = item.heading;
        _introductionController.text = item.introduction;
        _imageUrl = item.imageUrl;
        for (final section in _sections) {
          section.dispose();
        }
        _sections.clear();
        _sections.addAll(
          item.sections.map(
            (section) => _NewsletterSectionDraft(
              subHeadingController: TextEditingController(text: section.subHeading),
              contentController: TextEditingController(text: section.content),
            ),
          ),
        );
      } else {
        _selectedId = null;
        _headingController.clear();
        _introductionController.clear();
        _imageUrl = '';
        for (final section in _sections) {
          section.dispose();
        }
        _sections.clear();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load newsletters.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty) return;
      final file = result.first;
      final bytes = await file.readAsBytes();
      final uploadedUrl = await _service.uploadImage(bytes, file.name);
      if (!mounted) return;
      setState(() => _imageUrl = uploadedUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to upload image.')),
      );
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(
        _NewsletterSectionDraft(
          subHeadingController: TextEditingController(),
          contentController: TextEditingController(),
        ),
      );
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  Future<void> _saveNewsletter() async {
    final heading = _headingController.text.trim();
    final introduction = _introductionController.text.trim();
    final sections = _sections
        .map(
          (section) => NewsletterSection(
            subHeading: section.subHeadingController.text.trim(),
            content: section.contentController.text.trim(),
          ),
        )
        .where((section) => section.subHeading.isNotEmpty || section.content.isNotEmpty)
        .toList();
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (heading.isEmpty || introduction.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Heading and introduction are required.')),
      );
      return;
    }

    final payload = Newsletter(
      id: _selectedId,
      heading: heading,
      imageUrl: _imageUrl,
      introduction: introduction,
      sections: sections,
    );

    setState(() => _saving = true);
    try {
      if (_selectedId == null || _selectedId!.isEmpty) {
        await _service.create(payload);
      } else {
        await _service.update(_selectedId!, payload);
      }
      if (!mounted) return;
      await _loadNewsletters();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Newsletter saved successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Unable to save newsletter.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteNewsletter() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (_selectedId == null || _selectedId!.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('No newsletter selected to delete.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Newsletter?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.delete(_selectedId!);
      if (!mounted) return;
      _selectedId = null;
      _headingController.clear();
      _introductionController.clear();
      _imageUrl = '';
      for (final section in _sections) {
        section.dispose();
      }
      _sections.clear();
      setState(() {});
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Newsletter deleted successfully.')),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.adminDashboardNewsletter);
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        const SnackBar(content: Text('Unable to delete newsletter.')),
      );
    }
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
        title: const Text('Newsletter Edit'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  const Text(
                    'Create Newsletter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _headingController,
                    decoration: const InputDecoration(labelText: 'Heading *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _introductionController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Introduction *'),
                  ),
                  const SizedBox(height: 14),
                  if (_imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xffeef2f7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('No cover image selected'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload cover image'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Sections',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add),
                        label: const Text('Add section'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_sections.length, (index) {
                    final section = _sections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Section ${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeSection(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: section.subHeadingController,
                              decoration: const InputDecoration(labelText: 'Subheading'),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: section.contentController,
                              maxLines: 4,
                              decoration: const InputDecoration(labelText: 'Content'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
      bottomSheet: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleteNewsletter,
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _saveNewsletter,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsletterSectionDraft {
  _NewsletterSectionDraft({
    required this.subHeadingController,
    required this.contentController,
  });

  final TextEditingController subHeadingController;
  final TextEditingController contentController;

  void dispose() {
    subHeadingController.dispose();
    contentController.dispose();
  }
}
