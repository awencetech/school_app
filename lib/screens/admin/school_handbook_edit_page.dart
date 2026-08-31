import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/staff_handbook.dart';
import '../../services/staff_handbook_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class SchoolHandbookEditPage extends StatefulWidget {
  const SchoolHandbookEditPage({super.key});
  @override
  State<SchoolHandbookEditPage> createState() => _SchoolHandbookEditPageState();
}

class _SchoolHandbookEditPageState extends State<SchoolHandbookEditPage> {
  final _service = StaffHandbookService();
  final List<_SectionDraft> _sections = [];
  String? _handbookId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final handbook = await _service.getHandbook();
      _handbookId = handbook.id;
      for (final section in _sections) section.dispose();
      _sections.clear();
      _sections.addAll(handbook.sections.map(_SectionDraft.fromModel));
    } catch (_) {
      _handbookId = null;
      for (final section in _sections) section.dispose();
      _sections.clear();
      _error = 'Handbook data is temporarily unavailable.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final section in _sections) section.dispose();
    super.dispose();
  }

  void _addSection() =>
      setState(() => _sections.add(_SectionDraft.withSubSection()));

  Future<void> _deleteSection(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section?'),
        content: const Text('Are you sure you want to delete this section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true)
      setState(() {
        _sections[index].dispose();
        _sections.removeAt(index);
      });
  }

  Future<void> _pickImage(_SectionDraft section) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    try {
      setState(() => section.uploading = true);
      section.imageUrl = await _service.upload(
        await files.single.readAsBytes(),
        files.single.name,
      );
    } catch (_) {
      if (mounted) _snack('Unable to upload this image.', error: true);
    } finally {
      if (mounted) setState(() => section.uploading = false);
    }
  }

  Future<void> _save() async {
    final invalid = _sections.any(
      (section) =>
          section.heading.text.trim().isEmpty ||
          section.subSections.any(
            (sub) =>
                sub.heading.text.trim().isEmpty ||
                sub.content.text.trim().isEmpty,
          ),
    );
    if (invalid) {
      _snack(
        'Complete every heading, sub heading, and content field.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final handbook = StaffHandbook(
      schoolId: StaffHandbookService.schoolId,
      id: _handbookId,
      sections: [
        for (var i = 0; i < _sections.length; i++) _sections[i].toModel(i + 1),
      ],
    );
    try {
      final saved = await _service.save(handbook);
      if (!mounted) return;
      _handbookId = saved.id ?? _handbookId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School Handbook saved successfully.')),
      );
    } catch (_) {
      if (mounted)
        _snack(
          'Unable to save handbook sections. Please try again.',
          error: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final children = <Widget>[
      const Text(
        'School Handbook Sections',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      const Text('Create and manage handbook sections.'),
      const SizedBox(height: 20),
      if (_sections.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text('No sections yet. Add your first section.'),
          ),
        ),
      ..._sections.asMap().entries.map(
        (entry) => _sectionCard(entry.key, entry.value),
      ),
      OutlinedButton.icon(
        onPressed: _addSection,
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('School Handbook Edit'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_error!)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ...children,
        ],
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
      bottomSheet: _saveBar(),
    );
  }

  bool _hasNetworkImage(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  Widget _saveBar() => SafeArea(
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save Changes'),
        ),
      ),
    ),
  );

  Widget _sectionCard(int index, _SectionDraft section) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Section ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: index == 0
                    ? null
                    : () => setState(() {
                        final item = _sections.removeAt(index);
                        _sections.insert(index - 1, item);
                      }),
                tooltip: 'Move Up',
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                onPressed: index == _sections.length - 1
                    ? null
                    : () => setState(() {
                        final item = _sections.removeAt(index);
                        _sections.insert(index + 1, item);
                      }),
                tooltip: 'Move Down',
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                onPressed: () => _deleteSection(index),
                tooltip: 'Delete Section',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          _field('Heading *', section.heading, 'Staff Handbook'),
          const SizedBox(height: 4),
          const Text('Section Image'),
          const SizedBox(height: 8),
          if (_hasNetworkImage(section.imageUrl))
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                section.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 80,
                  child: Center(child: Text('Image unavailable')),
                ),
              ),
            )
          else
            const SizedBox(
              height: 40,
              child: Center(child: Text('No image selected')),
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: section.uploading ? null : () => _pickImage(section),
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  section.imageUrl.isEmpty ? 'Upload Image' : 'Change Image',
                ),
              ),
              if (section.imageUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => section.imageUrl = ''),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Image'),
                ),
            ],
          ),
          const Divider(height: 28),
          ...section.subSections.asMap().entries.map(
            (entry) => _subSectionCard(section, entry.key, entry.value),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => section.subSections.add(_SubSectionDraft())),
            icon: const Icon(Icons.add),
            label: const Text('Add Sub Heading'),
          ),
        ],
      ),
    ),
  );

  Widget _subSectionCard(
    _SectionDraft section,
    int index,
    _SubSectionDraft sub,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sub Heading ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              onPressed: index == 0
                  ? null
                  : () => setState(() {
                      final item = section.subSections.removeAt(index);
                      section.subSections.insert(index - 1, item);
                    }),
              tooltip: 'Move Up',
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
            ),
            IconButton(
              onPressed: index == section.subSections.length - 1
                  ? null
                  : () => setState(() {
                      final item = section.subSections.removeAt(index);
                      section.subSections.insert(index + 1, item);
                    }),
              tooltip: 'Move Down',
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            ),
            IconButton(
              onPressed: () => setState(() {
                sub.dispose();
                section.subSections.removeAt(index);
              }),
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
        _field('Sub Heading *', sub.heading, 'Introduction'),
        _field(
          'Content *',
          sub.content,
          'Welcome to the Staff Handbook...',
          lines: 5,
        ),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _SectionDraft {
  _SectionDraft() : heading = TextEditingController();
  _SectionDraft.withSubSection()
    : heading = TextEditingController(),
      subSections = [_SubSectionDraft()];
  _SectionDraft.fromModel(HandbookSection value)
    : heading = TextEditingController(text: value.heading),
      imageUrl = value.imageUrl,
      subSections = value.subSections.map(_SubSectionDraft.fromModel).toList();
  final TextEditingController heading;
  String imageUrl = '';
  bool uploading = false;
  List<_SubSectionDraft> subSections = [];
  HandbookSection toModel(int order) => HandbookSection(
    heading: heading.text.trim(),
    imageUrl: imageUrl,
    order: order,
    subSections: [
      for (var i = 0; i < subSections.length; i++)
        subSections[i].toModel(i + 1),
    ],
  );
  void dispose() {
    heading.dispose();
    for (final sub in subSections) sub.dispose();
  }
}

class _SubSectionDraft {
  _SubSectionDraft()
    : heading = TextEditingController(),
      content = TextEditingController();
  _SubSectionDraft.fromModel(HandbookSubSection value)
    : heading = TextEditingController(text: value.subHeading),
      content = TextEditingController(text: value.content);
  final TextEditingController heading;
  final TextEditingController content;
  HandbookSubSection toModel(int order) => HandbookSubSection(
    subHeading: heading.text.trim(),
    content: content.text.trim(),
    order: order,
  );
  void dispose() {
    heading.dispose();
    content.dispose();
  }
}
