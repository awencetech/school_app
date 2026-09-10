// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';

import '../../services/staff_upload_homework_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';

class StaffUploadHomeworkPage extends StatefulWidget {
  const StaffUploadHomeworkPage({
    super.key,
    this.groupId = 'grade-10-c',
    this.groupName = '10 C',
    this.groupYear = '2026-27',
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<StaffUploadHomeworkPage> createState() => _StaffUploadHomeworkPageState();
}

class _StaffUploadHomeworkPageState extends State<StaffUploadHomeworkPage> {
  final _service = StaffUploadHomeworkService();
  final _subjectController = TextEditingController();
  final _titleController = TextEditingController();
  late final QuillController _messageController;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  String _priority = 'Medium';
  bool _sendStudents = false;
  bool _sendTeachers = false;
  bool _commentsAllowed = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  final List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _messageController = QuillController.basic();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result.isEmpty) return;
    final file = result.single;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = bytes;
    });
  }

  MediaType? _contentTypeFor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const imageTypes = {
      'jpg': 'jpeg',
      'jpeg': 'jpeg',
      'png': 'png',
      'webp': 'webp',
      'gif': 'gif',
    };
    final subtype = imageTypes[extension];
    return subtype == null ? null : MediaType('image', subtype);
  }

  Future<bool> _uploadFile() async {
    if (_selectedFileBytes == null || _selectedFileName == null || _uploading) {
      return false;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _service.uploadAttachment(
        _selectedFileName!,
        _selectedFileBytes!,
        contentType: _contentTypeFor(_selectedFileName!),
      );
      if (!mounted) return false;
      setState(() {
        _attachments.add(url);
        _selectedFileName = null;
        _selectedFileBytes = null;
        _uploading = false;
      });
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Unable to upload attachment: $error';
        });
      }
      return false;
    }
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final title = _titleController.text.trim();
    final message = _messageController.document.toPlainText().trim();
    if (subject.isEmpty || title.isEmpty || message.isEmpty) {
      setState(() => _error = subject.isEmpty
          ? 'Subject is required.'
        : message.isEmpty
          ? 'Description is required.'
          : 'Homework title is required.');
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_date)) {
      setState(() => _error = 'Due date cannot be before assign date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_selectedFileBytes != null) {
        if (!await _uploadFile()) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }
      await _service.create(
        groupId: widget.groupId,
        groupName: widget.groupName,
        schoolId: 'default-school',
        date: _date,
        subject: subject,
        message: message,
        title: title,
        dueDate: _dueDate,
        priority: _priority,
        sendToStudents: _sendStudents,
        sendToTeachers: _sendTeachers,
        commentsAllowed: _commentsAllowed,
        attachments: _attachments,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save staff homework: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text('Homework', style: AppTextStyles.appTitle.copyWith(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldLabel('For Date'),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_date)),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Due Date'),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? _date,
                    firstDate: _date,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate == null ? 'Select due date' : _formatDate(_dueDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Subject'),
              DropdownButtonFormField<String>(
                value: _subjectController.text.isEmpty ? null : _subjectController.text,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Select subject'),
                items: const ['Mathematics', 'Science', 'English', 'Social Studies', 'Computer Science', 'Other']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => _subjectController.text = value ?? ''),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Homework Title'),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Priority'),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const ['Low', 'Medium', 'High']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value ?? 'Medium'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Send Messages to'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('All Students'),
                value: _sendStudents,
                onChanged: (value) =>
                    setState(() => _sendStudents = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('All Teachers'),
                value: _sendTeachers,
                onChanged: (value) =>
                    setState(() => _sendTeachers = value ?? false),
              ),
              _fieldLabel('Message for mail and webapp'),
              _editor(),
              const SizedBox(height: 12),
              _fieldLabel('Attach Files'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFileName ?? 'Click to upload'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedFileBytes == null || _uploading
                        ? null
                        : _uploadFile,
                    child: _uploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Upload'),
                  ),
                ],
              ),
              if (_selectedFileBytes != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Image.memory(
                    Uint8List.fromList(_selectedFileBytes!),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              if (_selectedFileName != null)
                Text(
                  'Selected: $_selectedFileName',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              if (_attachments.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_attachments.length} file(s) uploaded',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachments.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => SizedBox(
                          width: 240,
                          child: CachedNetworkImage(
                            imageUrl: _attachments[index],
                            fit: BoxFit.contain,
                            errorWidget: (_, url, error) => const Icon(Icons.attach_file),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Comments Allowed'),
                  const Spacer(),
                  DropdownButton<bool>(
                    value: _commentsAllowed,
                    items: const [
                      DropdownMenuItem(value: true, child: Text('True')),
                      DropdownMenuItem(value: false, child: Text('False')),
                    ],
                    onChanged: (value) =>
                        setState(() => _commentsAllowed = value ?? true),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add Homework'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _editor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        color: AppColors.white,
      ),
      child: SizedBox(
        height: 190,
        child: QuillEditor.basic(
          controller: _messageController,
          config: const QuillEditorConfig(
            placeholder: 'Type your message...',
            padding: EdgeInsets.all(10),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
