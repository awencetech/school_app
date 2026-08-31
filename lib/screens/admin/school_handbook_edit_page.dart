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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final handbook = await _service.getHandbook();
      _handbookId = handbook.id;
      for (final section in _sections) {
        section.dispose();
      }
      _sections.clear();
      _sections.addAll(handbook.sections.map(_SectionDraft.fromModel));
    } catch (_) {
      _handbookId = null;
      for (final section in _sections) {
        section.dispose();
      }
      _sections.clear();
      _error = 'Handbook data is temporarily unavailable.';
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }
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
    if (confirmed == true) {
      setState(() {
        _sections[index].dispose();
        _sections.removeAt(index);
      });
    }
  }

  Future<void> _editSection(int index) async {
    final section = _sections[index];
    final headingController = TextEditingController(text: section.heading.text);
    final subDrafts = section.subSections
        .map(
          (sub) => _SubSectionDraft(
            heading: TextEditingController(text: sub.heading.text),
            content: TextEditingController(text: sub.content.text),
          ),
        )
        .toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Section ${index + 1}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: headingController,
                  decoration: const InputDecoration(labelText: 'Heading *'),
                ),
                const SizedBox(height: 12),
                ...subDrafts.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sub Heading ${entry.key + 1}'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: entry.value.heading,
                          decoration: const InputDecoration(labelText: 'Sub Heading *'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry.value.content,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Content *'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) {
      for (final draft in subDrafts) {
        draft.dispose();
      }
      headingController.dispose();
      return;
    }

    setState(() {
      section.heading.text = headingController.text.trim();
      for (var i = 0; i < section.subSections.length && i < subDrafts.length; i++) {
        section.subSections[i].heading.text = subDrafts[i].heading.text.trim();
        section.subSections[i].content.text = subDrafts[i].content.text.trim();
      }
    });

    for (final draft in subDrafts) {
      draft.dispose();
    }
    headingController.dispose();
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
    final sectionModels = <HandbookSection>[];
    for (var i = 0; i < _sections.length; i++) {
      sectionModels.add(_sections[i].toModel(i + 1));
    }
    final handbook = StaffHandbook(
      schoolId: StaffHandbookService.schoolId,
      id: _handbookId,
      sections: sectionModels,
    );
    try {
      final saved = await _service.save(handbook);
      if (!mounted) return;
      _handbookId = saved.id ?? _handbookId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School Handbook saved successfully.')),
      );
    } catch (_) {
      if (mounted) {
        _snack(
          'Unable to save handbook sections. Please try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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

  Widget _sectionCard(int index, _SectionDraft section) {
    final heading = section.heading.text.trim();
    final summary = section.subSections.isEmpty
        ? 'No content added yet.'
        : section.subSections.first.content.text.trim().isNotEmpty
        ? section.subSections.first.content.text.trim()
        : 'No content added yet.';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasNetworkImage(section.imageUrl))
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.network(
                section.imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('Image unavailable')),
                ),
              ),
            )
          else
            Container(
              height: 165,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined, size: 36),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              heading.isEmpty ? 'Section ${index + 1}' : heading,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _editSection(index),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteSection(index),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
  HandbookSection toModel(int order) {
    final subSectionModels = <HandbookSubSection>[];
    for (var i = 0; i < subSections.length; i++) {
      subSectionModels.add(subSections[i].toModel(i + 1));
    }
    return HandbookSection(
      heading: heading.text.trim(),
      imageUrl: imageUrl,
      order: order,
      subSections: subSectionModels,
    );
  }
  void dispose() {
    heading.dispose();
    for (final sub in subSections) {
      sub.dispose();
    }
  }
}

class _SubSectionDraft {
  _SubSectionDraft({TextEditingController? heading, TextEditingController? content})
    : heading = heading ?? TextEditingController(),
      content = content ?? TextEditingController();
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
