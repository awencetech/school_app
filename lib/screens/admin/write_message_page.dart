import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/group_message_service.dart';

class WriteMessagePage extends StatefulWidget {
  const WriteMessagePage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupYear,
  });

  final String groupId;
  final String groupName;
  final String groupYear;

  @override
  State<WriteMessagePage> createState() => _WriteMessagePageState();
}

class _WriteMessagePageState extends State<WriteMessagePage> {
  final GroupMessageService _service = GroupMessageService();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _studentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final QuillController _messageController = QuillController.basic();
  String? _selectedType;
  String? _typeError;
  String? _submitError;
  bool _isSending = false;
  bool _allStudents = false;
  bool _allTeachers = false;
  bool _commentsAllowed = true;
  List<PlatformFile> _selectedFiles = [];
  bool _filesUploaded = false;

  static const _messageTypes = [
    'School',
    'Class/es',
    'Teacher/s',
    'Student/s',
  ];

  void _normalizeSelectedType() {
    if (_selectedType != null && !_messageTypes.contains(_selectedType)) {
      _selectedType = null;
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _teacherController.dispose();
    _studentController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    setState(() {
      _typeError = _selectedType == null ? 'Please select a message type.' : null;
      _submitError = null;
    });
    if (_typeError != null) return;

    final appState = context.read<AppState>();
    setState(() => _isSending = true);
    try {
      await _service.createMessage(
        groupId: widget.groupId,
        groupName: widget.groupName,
        messageType: _selectedType!,
        message: _messageController.document.toPlainText().trim(),
        senderId: appState.currentUserId ?? '',
        senderName: appState.currentUserEmail ?? appState.currentUserId ?? 'User',
        senderRole: appState.currentUserRole ?? '',
      );
      if (!mounted) return;
      setState(() {
        _selectedType = null;
        _isSending = false;
        _subjectController.clear();
        _messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent successfully.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _submitError = 'Unable to send message: $error';
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles();
    if (result.isEmpty || !mounted) return;
    setState(() {
      _selectedFiles = result;
      _filesUploaded = false;
    });
  }

  void _uploadFiles() {
    if (_selectedFiles.isEmpty) return;
    setState(() => _filesUploaded = true);
  }

  @override
  Widget build(BuildContext context) {
    _normalizeSelectedType();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text('Today in Class', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 75),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Write Message', style: TextStyle(fontSize: 12, color: Color(0xff222222), fontWeight: FontWeight.w400)),
            Text('of ${widget.groupName} in ${widget.groupName} - ${widget.groupYear}', style: const TextStyle(fontSize: 12, height: 1.05)),
            const SizedBox(height: 2),
            const Text('Message for', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 2),
            _selectField(
              value: _selectedType,
              hint: '(Select One)',
              items: _messageTypes,
              onChanged: (value) => setState(() { _selectedType = value; _typeError = null; }),
              errorText: _typeError,
            ),
            if (_selectedType == null) ...[
              const SizedBox(height: 9),
              _sendButton(),
            ] else ...[
              const SizedBox(height: 8),
              _buildRecipientForm(),
            ],
            if (_submitError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_submitError!, style: const TextStyle(color: Colors.red, fontSize: 11))),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xffd90087),
        elevation: 4,
        onPressed: () {},
        child: const Icon(Icons.menu, size: 19, color: Colors.white),
      ),
      floatingActionButtonLocation: const _ReferenceFabLocation(),
      bottomNavigationBar: const _WriteMessageBottomNavigation(),
    );
  }

  Widget _buildRecipientForm() {
    switch (_selectedType) {
      case 'School':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_recipientChecks(), _commonFields(subject: 'School Notice', includeDate: true)]);
      case 'Class/es':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_label('Class'), _input(_classController), _recipientChecks(), _commonFields(includeDate: true)]);
      case 'Teacher/s':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_label('Select All Employee/Teachers'), _selectField(value: 'False', items: const ['False', 'True'], onChanged: (_) {}), _label('Teacher'), _input(_teacherController), _commonFields(includeDate: true)]);
      case 'Student/s':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Align(alignment: Alignment.centerLeft, child: Text('Please select one class only', style: TextStyle(fontSize: 11))), _label('Select All Students'), _selectField(value: 'False', items: const ['False', 'True'], onChanged: (_) {}), _label('Student Name/s'), _input(_studentController), _commonFields(subjectHint: 'Subject...', includeDate: true)]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _recipientChecks() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _label('Send Messages to'),
        Row(children: [
          Expanded(child: _check('All Students', _allStudents, (value) => setState(() => _allStudents = value ?? false))),
          const SizedBox(width: 8),
          Expanded(child: _check('All Teachers', _allTeachers, (value) => setState(() => _allTeachers = value ?? false))),
        ]),
      ]);

  Widget _commonFields({String? subject, String? subjectHint, required bool includeDate}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _label('Msg type'), _selectField(value: 'WebApp', items: const ['WebApp'], onChanged: (_) {}),
        if (includeDate) ...[_label(_selectedType == 'School' ? 'Valid for' : 'For Date'), _input(null, value: '19-08-2026', isDate: true)],
        _label('Subject'), _input(_subjectController, value: subject, hint: subjectHint ?? 'Type Subject...'),
        _label('Message for mail and webapp'),
        _editor(),
        _attachmentSection(),
      ]);

  Widget _attachmentSection() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(padding: EdgeInsets.only(top: 10, bottom: 6), child: Text('Attach Files', style: TextStyle(fontSize: 11))),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file, size: 16),
                label: Text(_selectedFiles.isEmpty ? 'Click to upload' : '${_selectedFiles.length} file(s) selected', style: const TextStyle(fontSize: 10)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xff555555), side: const BorderSide(color: Color(0xff555555)), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 30,
            width: 75,
            child: OutlinedButton(
              onPressed: _selectedFiles.isEmpty ? null : _uploadFiles,
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xff777777), backgroundColor: const Color(0xffdedfe3), side: BorderSide.none, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: Text(_filesUploaded ? 'Uploaded' : 'Upload', style: const TextStyle(fontSize: 10)),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Row(children: [
            const Text('Comments Allowed', style: TextStyle(fontSize: 11)),
            const Spacer(),
            DropdownButton<bool>(value: _commentsAllowed, underline: const SizedBox.shrink(), iconSize: 15, style: const TextStyle(fontSize: 11, color: Color(0xff333333)), items: const [DropdownMenuItem(value: true, child: Text('True')), DropdownMenuItem(value: false, child: Text('False'))], onChanged: (value) => setState(() => _commentsAllowed = value ?? true)),
          ]),
        ),
        SizedBox(
          height: 30,
          child: ElevatedButton(onPressed: _isSending ? null : _sendMessage, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff343957), foregroundColor: Colors.white, padding: EdgeInsets.zero, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: _isSending ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white)) : const Text('Send', style: TextStyle(fontSize: 11))),
        ),
        const SizedBox(height: 10),
      ]);

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(top: 7, bottom: 2), child: Text(text, style: const TextStyle(fontSize: 11)));

  Widget _input(TextEditingController? controller, {String? value, String? hint, bool isDate = false}) => SizedBox(height: 27, child: TextField(controller: controller, readOnly: value != null && isDate, style: const TextStyle(fontSize: 11, color: Color(0xff555555)), decoration: _decoration(hint: hint, value: value, suffix: isDate ? const Icon(Icons.calendar_today, size: 13) : null)));

  Widget _selectField({String? value, String? hint, required List<String> items, required ValueChanged<String?> onChanged, String? errorText}) => SizedBox(height: errorText == null ? 28 : 44, child: DropdownButtonFormField<String>(initialValue: value, isExpanded: true, iconSize: 16, style: const TextStyle(fontSize: 11, color: Color(0xff333333)), decoration: _decoration(hint: hint, errorText: errorText), items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(), onChanged: onChanged));

  InputDecoration _decoration({String? hint, String? value, Widget? suffix, String? errorText}) => InputDecoration(hintText: value ?? hint, errorText: errorText, suffixIcon: suffix, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Color(0xffcccccc))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Color(0xffcccccc))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: const BorderSide(color: Color(0xff91c8f6), width: 2)));

  Widget _check(String text, bool value, ValueChanged<bool?> onChanged) => Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 17, height: 17, child: Checkbox(value: value == true, tristate: false, onChanged: onChanged, visualDensity: VisualDensity.compact)), Text(text, style: const TextStyle(fontSize: 10))]);

  Widget _sendButton() => Align(alignment: Alignment.centerLeft, child: SizedBox(height: 19, width: 29, child: ElevatedButton(onPressed: _isSending ? null : _sendMessage, style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: const Color(0xff087ff5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))), child: _isSending ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white)) : const Text('Send', style: TextStyle(fontSize: 8)))));

  Widget _editor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          width: width,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xffcccccc)), borderRadius: BorderRadius.circular(2), color: Colors.white),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: width,
                child: QuillSimpleToolbar(
                  controller: _messageController,
                  config: const QuillSimpleToolbarConfig(
                    multiRowsDisplay: true,
                    axis: Axis.horizontal,
                    toolbarSize: 22,
                    toolbarRunSpacing: 0,
                    toolbarSectionSpacing: 1,
                    showDividers: false,
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
                    showUndo: true,
                    showRedo: true,
                  ),
                ),
              ),
              SizedBox(
                height: 145,
                width: double.infinity,
                child: QuillEditor.basic(
                  controller: _messageController,
                  config: const QuillEditorConfig(
                    placeholder: 'Type your message...',
                    padding: EdgeInsets.all(6),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _WriteMessageBottomNavigation extends StatelessWidget {
  const _WriteMessageBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xff34395f),
      ),
      child: Row(
        children: const [
          _NavigationItem(icon: Icons.home_outlined, label: 'Home', active: false),
          _NavigationItem(icon: Icons.person_outline, label: 'User'),
          _NavigationItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          _NavigationItem(icon: Icons.help_outline, label: 'Support'),
          _NavigationItem(icon: Icons.logout, label: 'Logout'),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.icon, required this.label, this.active = false});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xbfffffff);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _ReferenceFabLocation extends FloatingActionButtonLocation {
  const _ReferenceFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) => Offset(geometry.scaffoldSize.width - 52, geometry.scaffoldSize.height - geometry.floatingActionButtonSize.height - 67);
}
