import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:intl/intl.dart';

import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class AnnouncementEditPage extends StatefulWidget {
  const AnnouncementEditPage({super.key});

  @override
  State<AnnouncementEditPage> createState() => _AnnouncementEditPageState();
}

class _AnnouncementEditPageState extends State<AnnouncementEditPage> {
  final _service = AnnouncementService();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _createdOnController = TextEditingController();
  final List<String> _selectedTo = <String>[];

  bool _loading = true;
  String? _selectedId;
  List<Announcement> _announcements = const [];

  static const List<String> _recipientOptions = [
    'All Students',
    'Specific Students',
    'Parents',
    'Staff/Teachers',
    'Selected Group/Class',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _fromController.dispose();
    _contentController.dispose();
    _createdOnController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _announcements = const [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load announcements.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final formatted = DateFormat('MMMM dd, yyyy').format(picked);
    setState(() => _createdOnController.text = formatted);
  }

  Future<void> _openForm({Announcement? announcement}) async {
    _subjectController.text = announcement?.subject ?? '';
    _fromController.text = announcement?.fromName ?? '';
    _contentController.text = announcement?.content ?? '';
    _createdOnController.text = announcement?.createdOn ?? '';
    _selectedTo
      ..clear()
      ..addAll(announcement?.to ?? const <String>[]);
    _selectedId = announcement?.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        subjectController: _subjectController,
        fromController: _fromController,
        contentController: _contentController,
        createdOnController: _createdOnController,
        selectedTo: _selectedTo,
        recipientOptions: _recipientOptions,
        selectedId: _selectedId,
        onDatePicked: _pickDate,
      ),
    );

    if (result == true) {
      await _loadAnnouncements();
      _clearForm();
    }
  }

  void _clearForm() {
    _selectedId = null;
    _subjectController.clear();
    _fromController.clear();
    _contentController.clear();
    _createdOnController.clear();
    _selectedTo.clear();
  }

  Future<void> _deleteAnnouncement(Announcement item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || item.id == null || item.id!.isEmpty) return;

    try {
      await _service.delete(item.id!);
      if (!mounted) return;
      setState(() => _announcements.removeWhere((entry) => entry.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the announcement.')),
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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Announcement Edit'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Announcement'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _announcements.isEmpty
                          ? const Center(
                              child: Text(
                                'No announcements available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final item = _announcements[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.subject,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Created On: ${item.createdOn?.isNotEmpty == true ? item.createdOn : '—'}'),
                                        const SizedBox(height: 6),
                                        Text('From: ${item.fromName.isNotEmpty ? item.fromName : '—'}'),
                                        const SizedBox(height: 6),
                                        Text('To: ${item.to.isEmpty ? '—' : item.to.join(', ')}'),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _openForm(announcement: item),
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Edit'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _deleteAnnouncement(item),
                                                icon: const Icon(Icons.delete_outline),
                                                label: const Text('Delete'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog({
    required this.subjectController,
    required this.fromController,
    required this.contentController,
    required this.createdOnController,
    required this.selectedTo,
    required this.recipientOptions,
    required this.selectedId,
    required this.onDatePicked,
  });

  final TextEditingController subjectController;
  final TextEditingController fromController;
  final TextEditingController contentController;
  final TextEditingController createdOnController;
  final List<String> selectedTo;
  final List<String> recipientOptions;
  final String? selectedId;
  final VoidCallback onDatePicked;

  @override
  State<_AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _service = AnnouncementService();
  bool _saving = false;

  List<String> _normalizeSelectedTo() {
    final set = <String>{};
    for (final value in widget.selectedTo) {
      if (value.trim().isNotEmpty) set.add(value.trim());
    }
    return set.toList();
  }

  Future<void> _submit() async {
    final subject = widget.subjectController.text.trim();
    final fromName = widget.fromController.text.trim();
    final content = widget.contentController.text.trim();
    final createdOn = widget.createdOnController.text.trim();
    final selectedTo = _normalizeSelectedTo();

    if (subject.isEmpty || fromName.isEmpty || content.isEmpty || createdOn.isEmpty || selectedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final payload = Announcement(
      id: widget.selectedId,
      subject: subject,
      fromName: fromName,
      to: selectedTo,
      createdOn: createdOn,
      content: content,
    );

    setState(() => _saving = true);
    try {
      if (widget.selectedId == null || widget.selectedId!.isEmpty) {
        await _service.create(payload);
      } else {
        await _service.update(widget.selectedId!, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement saved successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save announcement.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTo = _normalizeSelectedTo();
    final toText = selectedTo.isEmpty ? 'None selected' : selectedTo.join(', ');

    return AlertDialog(
      title: const Text('Announcement'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: widget.subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.fromController,
                decoration: const InputDecoration(
                  labelText: 'From *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('To *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.recipientOptions.map((option) {
                  final selected = selectedTo.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          widget.selectedTo.remove(option);
                        } else {
                          widget.selectedTo.add(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(toText, style: const TextStyle(fontSize: 12, color: Color(0xff4b5563))),
              const SizedBox(height: 12),
              TextField(
                controller: widget.createdOnController,
                readOnly: true,
                onTap: widget.onDatePicked,
                decoration: const InputDecoration(
                  labelText: 'Created On Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.contentController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
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
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Save Announcement'),
        ),
      ],
    );
  }
}
