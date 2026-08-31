import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/event_celebration.dart';
import '../../routes/app_routes.dart';
import '../../services/event_celebration_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class EventsCelebrationEditPage extends StatefulWidget {
  const EventsCelebrationEditPage({super.key});

  @override
  State<EventsCelebrationEditPage> createState() => _EventsCelebrationEditPageState();
}

class _EventsCelebrationEditPageState extends State<EventsCelebrationEditPage> {
  final _service = EventCelebrationService();
  List<EventCelebration> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
    });

    try {
      final items = await _service.getEvents();
      if (!mounted) return;
      setState(() {
        _events = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _events = [];
        _loading = false;
      });
    }
  }

  Future<void> _deleteEvent(EventCelebration event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
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

    if (confirm != true || event.id == null) return;

    try {
      await _service.delete(event.id!);
      if (!mounted) return;
      setState(() => _events.removeWhere((item) => item.id == event.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete the event.')),
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
        title: const Text('Events & Celebrations Edit'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Events & Celebrations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage school events and celebrations.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.adminKnowYourSchoolEventsCelebrationEditAddEvent,
                  ).then((_) => _loadEvents()),
                  icon: const Icon(Icons.add),
                  label: const Text('+ Add Event'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No events available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create your first school event or celebration.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    AppRoutes.adminKnowYourSchoolEventsCelebrationEditAddEvent,
                                  ).then((_) => _loadEvents()),
                                  icon: const Icon(Icons.add),
                                  label: const Text('+ Add Event'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final item = _events[index];
                          final dateText = item.eventDate == null
                              ? ''
                              : DateFormat('d MMMM yyyy').format(item.eventDate!);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.imageUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 90,
                                          height: 90,
                                          color: const Color(0xffe5e7eb),
                                          child: const Icon(Icons.broken_image_outlined),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffe5e7eb),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.event,
                                        size: 40,
                                        color: Color(0xff6b7280),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.heading,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.subHeading,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 8),
                                        if (dateText.isNotEmpty)
                                          Text(
                                            dateText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff4b5563),
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pushNamed(
                                                AppRoutes.adminKnowYourSchoolEventsCelebrationEditEditEvent,
                                                arguments: item,
                                              ).then((_) => _loadEvents()),
                                              child: const Text('Edit'),
                                            ),
                                            const SizedBox(width: 12),
                                            TextButton(
                                              onPressed: () => _deleteEvent(item),
                                              child: const Text('Delete'),
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

class EventCelebrationFormPage extends StatefulWidget {
  const EventCelebrationFormPage({
    super.key,
    this.event,
  });

  final EventCelebration? event;

  @override
  State<EventCelebrationFormPage> createState() => _EventCelebrationFormPageState();
}

class _EventCelebrationFormPageState extends State<EventCelebrationFormPage> {
  final _service = EventCelebrationService();
  final _headingController = TextEditingController();
  final _subHeadingController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();
  String _imageUrl = '';
  String _tag = 'Event';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _headingController.text = event.heading;
      _subHeadingController.text = event.subHeading;
      _contentController.text = event.content;
      _imageUrl = event.imageUrl;
      _tag = event.category;
      if (event.eventDate != null) {
        _dateController.text = DateFormat('yyyy-MM-dd').format(event.eventDate!);
      }
    }
  }

  @override
  void dispose() {
    _headingController.dispose();
    _subHeadingController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.tryParse(_dateController.text) ?? now
          : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  Future<void> _pickImage() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;

    final file = files.first;

    try {
      setState(() => _uploading = true);

      final dynamic selectedFile = file;
      List<int> bytes = const [];

      final dynamic rawBytes = selectedFile.bytes;
      if (rawBytes != null) {
        bytes = List<int>.from(rawBytes);
      }

      if (bytes.isEmpty) {
        final path = selectedFile.path as String?;
        if (path != null && path.isNotEmpty) {
          bytes = await File(path).readAsBytes();
        }
      }

      if (bytes.isEmpty) {
        throw Exception('Uploaded file data is not available.');
      }

      final url = await _service.uploadImage(bytes, file.name);
      setState(() => _imageUrl = url);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to upload the image.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final heading = _headingController.text.trim();
    final subHeading = _subHeadingController.text.trim();
    final content = _contentController.text.trim();
    if (heading.isEmpty || subHeading.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heading, Sub Heading, and Content are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final model = EventCelebration(
      id: widget.event?.id,
      schoolId: EventCelebrationService.schoolId,
      heading: heading,
      imageUrl: _imageUrl,
      subHeading: subHeading,
      content: content,
      eventDate: _dateController.text.isNotEmpty
          ? DateTime.tryParse(_dateController.text)
          : null,
      category: _tag,
    );

    try {
      if (widget.event == null) {
        await _service.create(model);
      } else {
        await _service.update(widget.event!.id!, model);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the event.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(isEditing ? 'Edit Event' : 'Add Event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Event' : 'Add Event',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('admin / other-options / know-your-school / events-celebration-edit / add-event'),
              const SizedBox(height: 20),
              TextField(
                controller: _headingController,
                decoration: const InputDecoration(labelText: 'Heading'),
              ),
              const SizedBox(height: 16),
              const Text('Event Image', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_imageUrl.isEmpty ? 'Upload Image' : 'Change Image'),
                  ),
                  if (_imageUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _imageUrl = ''),
                      child: const Text('Remove Image'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subHeadingController,
                decoration: const InputDecoration(labelText: 'Sub Heading'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Event Content'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Event Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tag,
                decoration: const InputDecoration(labelText: 'Event Category'),
                items: const [
                  'Event',
                  'Celebration',
                  'Competition',
                  'Cultural Program',
                  'Sports',
                  'National Day',
                  'School Activity',
                  'Other',
                ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => setState(() => _tag = value ?? 'Event'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : isEditing ? 'Save Changes' : 'Save Event'),
                    ),
                  ),
                ],
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
