// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';

import '../../models/group.dart';
import '../../models/today_in_class.dart';
import '../../routes/app_routes.dart';
import '../../services/today_in_class_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/slug_generator.dart';
import '../../widgets/admin_bottom_nav.dart';

class HomeworkTodayInClassPage extends StatefulWidget {
  const HomeworkTodayInClassPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
    this.isEdit = false,
    this.initialTabIndex = 1,
  });

  final String groupId;
  final String groupName;
  final String groupYear;
  final bool isEdit;
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

  String get _effectiveGroupId {
    if (widget.groupId.trim().isNotEmpty &&
        widget.groupId.toLowerCase() != 'samuni-2022-unknown') {
      return widget.groupId.trim();
    }
    return generateGroupDatabaseId(widget.groupName);
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(
        AppRoutes.teacherGroupClasses,
        arguments: Group(id: widget.groupId, name: widget.groupName),
      );
    }
  }

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
      final records = await _service.getRecords(_effectiveGroupId);
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
            _TodayInClassForm(
              service: _service,
              groupId: _effectiveGroupId,
              isHomework: _tabIndex == 0,
            ),
      ),
    );
    if (saved == true) _loadRecords();
  }

  Future<void> _openEditForm(TodayInClassRecord record) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TodayInClassForm(
          service: _service,
          groupId: _effectiveGroupId,
          record: record,
          isHomework: _tabIndex == 0,
        ),
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
          onPressed: _goBack,
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
                  if (widget.isEdit)
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xffeeeeee),
                  child: Icon(Icons.school, size: 20, color: Color(0xff9e9e9e)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Homework: ${record.subject}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'For: ${_formatDate(record.date)}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isEdit)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openEditForm(record),
                    icon: const Icon(Icons.edit_outlined, size: 19),
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
            const SizedBox(height: 6),
            Text(
              'Message for: ${_recipients(record)}',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 4),
            Text(
              record.message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryText,
              ),
            ),
            if (record.attachments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Column(
                children: record.attachments
                    .map(
                      (attachment) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ResponsiveAttachmentPreview(
                          url: attachment,
                          onTap: () => _showAttachment(attachment),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 6),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    record.commentsAllowed ? Icons.comment_outlined : Icons.comments_disabled_outlined,
                    size: 15,
                    color: record.commentsAllowed ? Colors.green : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.commentsAllowed ? 'Comments allowed' : 'Comments not allowed',
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.secondaryText),
                  ),
                  const Spacer(),
                  const Icon(Icons.visibility_outlined, size: 14, color: AppColors.secondaryText),
                  const SizedBox(width: 3),
                  Text('Viewed', style: GoogleFonts.poppins(fontSize: 9, color: AppColors.secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _recipients(TodayInClassRecord record) {
    if (record.sendToStudents && record.sendToTeachers) return 'Students, Teachers';
    if (record.sendToStudents) return 'Students';
    if (record.sendToTeachers) return 'Teachers';
    return 'None selected';
  }

  Future<void> _showAttachment(String url) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, imageUrl) => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, imageUrl, error) => const SizedBox(
              height: 160,
              child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
            ),
          ),
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

class _ResponsiveAttachmentPreview extends StatefulWidget {
  const _ResponsiveAttachmentPreview({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  State<_ResponsiveAttachmentPreview> createState() =>
      _ResponsiveAttachmentPreviewState();
}

class _ResponsiveAttachmentPreviewState
    extends State<_ResponsiveAttachmentPreview> {
  double _aspectRatio = 1.5;

  @override
  void initState() {
    super.initState();
    final stream = CachedNetworkImageProvider(widget.url).resolve(
      const ImageConfiguration(),
    );
    stream.addListener(
      ImageStreamListener((imageInfo, synchronousCall) {
        final image = imageInfo.image;
        if (!mounted || image.width == 0 || image.height == 0) return;
        setState(() => _aspectRatio = image.width / image.height);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 240.0;
        const maxHeight = 360.0;
        final width = maxWidth < maxHeight * _aspectRatio
            ? maxWidth
            : maxHeight * _aspectRatio;
        final height = width / _aspectRatio;
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: GestureDetector(
                onTap: widget.onTap,
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  placeholder: (_, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, url, error) => const Center(
                    child: Icon(Icons.attach_file, size: 22),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayInClassForm extends StatefulWidget {
  const _TodayInClassForm({
    required this.service,
    required this.groupId,
    this.record,
    this.isHomework = false,
  });

  final TodayInClassService service;
  final String groupId;
  final TodayInClassRecord? record;
  final bool isHomework;

  @override
  State<_TodayInClassForm> createState() => _TodayInClassFormState();
}

class _TodayInClassFormState extends State<_TodayInClassForm> {
  final _subjectController = TextEditingController();
  late final QuillController _messageController;
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
  void initState() {
    super.initState();
    _messageController = QuillController.basic();
    final record = widget.record;
    if (record != null) {
      _subjectController.text = record.subject;
      _messageController.document.insert(0, record.message);
      _date = record.date;
      _sendStudents = record.sendToStudents;
      _sendTeachers = record.sendToTeachers;
      _commentsAllowed = record.commentsAllowed;
      _attachments.addAll(record.attachments);
    }
  }

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
    final result = await FilePicker.pickFiles();
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

  MediaType? _contentTypeFor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    final types = {
      'jpg': MediaType('image', 'jpeg'),
      'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'),
      'webp': MediaType('image', 'webp'),
      'gif': MediaType('image', 'gif'),
    };
    return types[extension];
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
            contentType: _contentTypeFor(_selectedFileName!),
          ),
        );
      }
      if (widget.record == null) {
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
      } else {
        await widget.service.updateRecord(
          groupId: widget.groupId,
          recordId: widget.record!.id,
          date: _date,
          subject: subject,
          message: message,
          sendToStudents: _sendStudents,
          sendToTeachers: _sendTeachers,
          commentsAllowed: _commentsAllowed,
          attachments: _attachments,
        );
      }
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
        contentType: _contentTypeFor(_selectedFileName!),
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
          widget.isHomework ? 'Homework' : 'Classwork',
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
