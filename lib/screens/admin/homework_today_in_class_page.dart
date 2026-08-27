// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/today_in_class.dart';
import '../../services/today_in_class_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';

class HomeworkTodayInClassPage extends StatefulWidget {
  const HomeworkTodayInClassPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
    this.initialTabIndex = 1,
  });

  final String groupId;
  final String groupName;
  final String groupYear;
  final int initialTabIndex;

  @override
  State<HomeworkTodayInClassPage> createState() =>
      _HomeworkTodayInClassPageState();
}

class _HomeworkTodayInClassPageState extends State<HomeworkTodayInClassPage> {
  final TodayInClassService _service = TodayInClassService();
  List<TodayInClassRecord> _records = [];
  bool _isLoading = true;
  bool _hasError = false;
  late int _tabIndex;
  int _selectedBottomIndex = 2;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final records = await _service.getRecords(widget.groupId);
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _openAddForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _TodayInClassForm(service: _service, groupId: widget.groupId),
      ),
    );
    if (saved == true) _loadRecords();
  }

  Future<void> _deleteRecord(TodayInClassRecord record) async {
    try {
      await _service.deleteRecord(widget.groupId, record.id);
      if (mounted) {
        setState(() => _records.removeWhere((item) => item.id == record.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted successfully.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to delete: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${widget.groupName} - ${widget.groupYear} - Homework, Today in Class';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(
          'Homework, Today in Class',
          style: AppTextStyles.appTitle.copyWith(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 14),
              _buildTabs(),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tabIndex == 0 ? 'Homework List' : 'Today in Class',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openAddForm,
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasError)
                _errorState()
              else if (_tabIndex == 0)
                _emptyState('No Data available')
              else if (_records.isEmpty)
                _emptyState('No Data available')
              else
                ..._records.map(_recordCard),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) => setState(() => _selectedBottomIndex = index),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _tabButton('Homework', 0)),
        Expanded(child: _tabButton('TodayInClass', 1)),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _tabIndex == index ? AppColors.topBar : AppColors.white,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _tabIndex == index ? AppColors.white : AppColors.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _recordCard(TodayInClassRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(record.date),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteRecord(record),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
            Text(
              record.subject,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              record.message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 45),
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(color: AppColors.secondaryText),
      ),
    ),
  );

  Widget _errorState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      children: [
        Text(
          'Unable to load Today in Class.',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
        TextButton.icon(
          onPressed: _loadRecords,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _TodayInClassForm extends StatefulWidget {
  const _TodayInClassForm({required this.service, required this.groupId});

  final TodayInClassService service;
  final String groupId;

  @override
  State<_TodayInClassForm> createState() => _TodayInClassFormState();
}

class _TodayInClassFormState extends State<_TodayInClassForm> {
  final _subjectController = TextEditingController();
  final _messageController = QuillController.basic();
  DateTime _date = DateTime.now();
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
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

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
    final result = await FilePicker.pickFiles(withData: true);
    final file = result.isEmpty ? null : result.single;
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = bytes;
    });
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.document.toPlainText().trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(
        () => _error = subject.isEmpty
            ? 'Subject is required.'
            : 'Message is required.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_selectedFileBytes != null && _selectedFileName != null) {
        _attachments.add(
          await widget.service.uploadAttachment(
            _selectedFileName!,
            _selectedFileBytes!,
          ),
        );
      }
      await widget.service.createRecord(
        groupId: widget.groupId,
        date: _date,
        subject: subject,
        message: message,
        sendToStudents: _sendStudents,
        sendToTeachers: _sendTeachers,
        commentsAllowed: _commentsAllowed,
        attachments: _attachments,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save Today in Class: $error';
        });
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFileBytes == null || _selectedFileName == null || _uploading) {
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await widget.service.uploadAttachment(
        _selectedFileName!,
        _selectedFileBytes!,
      );
      if (!mounted) return;
      setState(() {
        _attachments.add(url);
        _uploading = false;
        _selectedFileBytes = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Unable to upload attachment: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(
          'Today in Class',
          style: AppTextStyles.appTitle.copyWith(fontSize: 16),
        ),
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
              _fieldLabel('Subject'),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type Subject...',
                ),
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
              if (_selectedFileName != null)
                Text(
                  'Selected: $_selectedFileName',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              if (_attachments.isNotEmpty)
                Text(
                  '${_attachments.length} file(s) uploaded',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
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
              FilledButton(
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
                    : const Text('Send'),
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
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: _messageController,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: true,
              showFontSize: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showAlignmentButtons: true,
              showListBullets: true,
              showListNumbers: true,
              showLink: true,
              showCodeBlock: true,
              showQuote: true,
              showClearFormat: true,
            ),
          ),
          SizedBox(
            height: 190,
            child: QuillEditor.basic(
              controller: _messageController,
              config: const QuillEditorConfig(
                placeholder: 'Type your message...',
                padding: EdgeInsets.all(10),
              ),
            ),
          ),
        ],
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
