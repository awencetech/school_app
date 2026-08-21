import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class OnlineAssessmentPage extends StatefulWidget {
  const OnlineAssessmentPage({super.key, required this.group});

  final Group group;

  @override
  State<OnlineAssessmentPage> createState() => _OnlineAssessmentPageState();
}

class _OnlineAssessmentPageState extends State<OnlineAssessmentPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Today in Class',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 27,
              child: Padding(
                padding: const EdgeInsets.only(left: 7, top: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.group.name} - ${widget.group.year} - Assessments, Quizzes',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff1d3557),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showCreateAssessment,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(27, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xff0066cc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            SizedBox(
              height: 31,
              child: Row(
                children: [
                  _Tab(
                    label: 'List',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _Tab(
                    label: 'Chart',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                  _Tab(
                    label: 'Folder',
                    selected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                  _Tab(
                    label: 'Analyse',
                    selected: _selectedTab == 3,
                    onTap: () => setState(() => _selectedTab = 3),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _listTab(),
                  _chartTab(),
                  _folderTab(),
                  _analyseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Future<void> _showCreateAssessment() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => const _CreateAssessmentForm(),
    );
  }

  Widget _listTab() => const Center(
    child: Text(
      'No Data available',
      style: TextStyle(fontSize: 10, color: Color(0xff222222)),
    ),
  );

  Widget _chartTab() => const Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.only(left: 5, top: 8),
      child: Row(
        children: [
          Text('Skyline View', style: TextStyle(fontSize: 10)),
          SizedBox(width: 8),
          _SmallAction(icon: Icons.refresh, label: 'Refresh'),
        ],
      ),
    ),
  );

  Widget _folderTab() => const Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.only(left: 2, top: 8),
      child: Row(
        children: [
          Text('List of Resources', style: TextStyle(fontSize: 10)),
          SizedBox(width: 8),
          _SmallAction(icon: Icons.refresh),
        ],
      ),
    ),
  );

  Widget _analyseTab() => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 2, top: 10),
      child: Row(
        children: [
          const Text('Report from Date:', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 4),
          SizedBox(
            width: 96,
            height: 19,
            child: TextField(
              controller: TextEditingController(text: '2026-07-22'),
              style: const TextStyle(fontSize: 8),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 3),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const _SmallAction(label: 'Run Report'),
          const SizedBox(width: 4),
          const _SmallAction(icon: Icons.upload),
        ],
      ),
    ),
  );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({this.icon, this.label = ''});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 19,
    child: OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xff00a0df)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 10, color: const Color(0xff008ad8)),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(fontSize: 7, color: Color(0xff008ad8)),
            ),
        ],
      ),
    ),
  );
}

class _CreateAssessmentForm extends StatefulWidget {
  const _CreateAssessmentForm();

  @override
  State<_CreateAssessmentForm> createState() => _CreateAssessmentFormState();
}

class _CreateAssessmentFormState extends State<_CreateAssessmentForm> {
  final _shortDescription = TextEditingController();
  final _assessmentDescription = TextEditingController();
  final _lesson = TextEditingController();
  final _subTopic = TextEditingController();
  final _keywords = TextEditingController();
  String _subject = '(Select One)';
  String _grade = '(Select One)';

  @override
  void dispose() {
    _shortDescription.dispose();
    _assessmentDescription.dispose();
    _lesson.dispose();
    _subTopic.dispose();
    _keywords.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: EdgeInsets.zero,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 42,
        automaticallyImplyLeading: false,
        title: const Text(
          'Today in Class',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 17, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Assessment',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            _label('Short Description'),
            _input(_shortDescription),
            _label('Subject'),
            _dropdown(_subject, (value) => setState(() => _subject = value!)),
            _label('Lesson/Topic'),
            _input(_lesson),
            _label('Sub Topic'),
            _input(_subTopic),
            _label('Keywords or Key Areas covered'),
            _input(_keywords),
            _label('Grade Applicable for'),
            _dropdown(_grade, (value) => setState(() => _grade = value!)),
            _label('Assessment Description'),
            Container(
              height: 155,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd2d9df)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: [
                  _editorToolbar(),
                  Expanded(
                    child: TextField(
                      controller: _assessmentDescription,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(6),
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _formButton('Save', _save),
                const SizedBox(width: 6),
                _formButton('Reset', _reset),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    ),
  );

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assessment saved')));
  }

  void _reset() {
    _shortDescription.clear();
    _assessmentDescription.clear();
    _lesson.clear();
    _subTopic.clear();
    _keywords.clear();
    setState(() {
      _subject = '(Select One)';
      _grade = '(Select One)';
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 9, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
    ),
  );
  Widget _input(TextEditingController controller) => SizedBox(
    height: 26,
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 10),
      decoration: _decoration(),
    ),
  );
  Widget _dropdown(String value, ValueChanged<String?> onChanged) => SizedBox(
    height: 26,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
      decoration: _decoration(),
      items: const [
        DropdownMenuItem(value: '(Select One)', child: Text('(Select One)')),
      ],
      onChanged: onChanged,
    ),
  );
  Widget _editorToolbar() => Container(
    height: 58,
    color: const Color(0xfff2f3f4),
    padding: const EdgeInsets.all(3),
    child: Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        _tool(Icons.auto_fix_high, 'Insert', '• '),
        _tool(Icons.format_bold, 'Bold', '**'),
        _tool(Icons.format_underlined, 'Underline', '__'),
        _tool(Icons.format_italic, 'Italic', '_'),
        _tool(Icons.format_list_bulleted, 'Bullet list', '\n• '),
        _tool(Icons.format_list_numbered, 'Numbered list', '\n1. '),
        _tool(Icons.link, 'Link', '[text](url)'),
        _tool(Icons.image, 'Image', '![image](url)'),
        _tool(Icons.close, 'Clear', ''),
        _tool(Icons.code, 'Code', '`code`'),
        _tool(Icons.help_outline, 'Help', ' '),
      ],
    ),
  );
  Widget _tool(IconData icon, String tooltip, String insertion) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: () {
        if (insertion.isEmpty) {
          _assessmentDescription.clear();
          return;
        }
        final text = _assessmentDescription.text;
        final selection = _assessmentDescription.selection;
        final start = selection.start < 0 ? text.length : selection.start;
        final end = selection.end < 0 ? start : selection.end;
        final selected = text.substring(start, end);
        final replacement = selected.isEmpty
            ? insertion
            : '$insertion$selected$insertion';
        _assessmentDescription.value = TextEditingValue(
          text: text.replaceRange(start, end, replacement),
          selection: TextSelection.collapsed(
            offset: start + replacement.length,
          ),
        );
        setState(() {});
      },
      child: Container(
        width: 25,
        height: 23,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffccd2d8)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 14, color: const Color(0xff333333)),
      ),
    ),
  );
  Widget _formButton(String label, VoidCallback onPressed) => SizedBox(
    height: 22,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff087ff5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 8)),
    ),
  );
  InputDecoration _decoration() => const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffd2d9df)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xffd2d9df)),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: selected ? Border.all(color: const Color(0xffd9e2ec)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: selected ? const Color(0xff333333) : const Color(0xff0066cc),
          ),
        ),
      ),
    );
  }
}
