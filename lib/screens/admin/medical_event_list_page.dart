import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class MedicalEventListPage extends StatefulWidget {
  const MedicalEventListPage({super.key, required this.group});

  final Group group;

  @override
  State<MedicalEventListPage> createState() => _MedicalEventListPageState();
}

class _MedicalEventListPageState extends State<MedicalEventListPage> {
  final List<_MedicalEvent> _events = [
    const _MedicalEvent(
      student: 'Aarav Sharma',
      shortDescription: 'Fever and fatigue',
      details: 'Student reported low fever and tiredness after lunch.',
      visibility: 'School Nurse',
    ),
  ];

  Future<void> _openEntryForm() async {
    final event = await showDialog<_MedicalEvent>(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => _MedicalEventForm(),
    );

    if (!mounted || event == null) return;
    setState(() => _events.insert(0, event));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f9),
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
          onPressed: () => navigateBack(context),
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
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 7, top: 7, right: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.group.name} - ${widget.group.year} - Medical Events list',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff1d3557),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openEntryForm,
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
            const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
            const Padding(
              padding: EdgeInsets.only(left: 3, top: 5),
              child: Text(
                'Actionable Items - Please edit and release or delete it',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 3, top: 10),
              child: Text(
                'Medical events List in Class',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                itemCount: _events.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xffe7eaef)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.student,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff111827),
                                ),
                              ),
                            ),
                            IconButton(
                              splashRadius: 12,
                              onPressed: () {},
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: Color(0xff0066cc),
                              ),
                            ),
                            IconButton(
                              splashRadius: 12,
                              onPressed: () => setState(() => _events.removeAt(index)),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Color(0xffdc2626),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.shortDescription,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.details,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xff475569),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visible to: ${event.visibility}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xff0f766e),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
}

class _MedicalEvent {
  const _MedicalEvent({
    required this.student,
    required this.shortDescription,
    required this.details,
    required this.visibility,
  });

  final String student;
  final String shortDescription;
  final String details;
  final String visibility;
}

class _MedicalEventForm extends StatefulWidget {
  const _MedicalEventForm();

  @override
  State<_MedicalEventForm> createState() => _MedicalEventFormState();
}

class _MedicalEventFormState extends State<_MedicalEventForm> {
  final _shortDescription = TextEditingController();
  final _details = TextEditingController();
  final List<String> _students = const [
    '(Select One)',
    'Aarav Sharma',
    'Diya Kapoor',
    'Rohan Singh',
    'Meera Joshi',
  ];
  final List<String> _visibilityOptions = const [
    '(Select One)',
    'School Nurse',
    'School Doctor',
    'Parent',
  ];

  String _student = '(Select One)';
  String _visibility = '(Select One)';

  @override
  void dispose() {
    _shortDescription.dispose();
    _details.dispose();
    super.dispose();
  }

  void _reset() {
    _shortDescription.clear();
    _details.clear();
    setState(() {
      _student = '(Select One)';
      _visibility = '(Select One)';
    });
  }

  void _insert() {
    final short = _shortDescription.text.trim();
    if (short.isEmpty) return;

    final event = _MedicalEvent(
      student: _student == '(Select One)' ? 'Not selected' : _student,
      shortDescription: short,
      details: _details.text.trim().isEmpty
          ? 'No further details provided.'
          : _details.text.trim(),
      visibility: _visibility == '(Select One)' ? 'School Nurse' : _visibility,
    );

    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff333333),
          elevation: 0,
          toolbarHeight: 38,
          automaticallyImplyLeading: false,
          title: const Text(
            'First Information Record of a Medical Event',
            style: TextStyle(fontSize: 11, color: Color(0xff222222)),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 16, color: Color(0xff777777)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Student'),
              _dropdown(
                value: _student,
                items: _students,
                onChanged: (value) {
                  if (value != null) setState(() => _student = value);
                },
              ),
              _label('Short Description of the Medical Problem'),
              _input(_shortDescription),
              _label('Describe in detail the Medical Problem'),
              _editor(),
              _label('To be seen by Inhouse Nurse or Doctor'),
              _dropdown(
                value: _visibility,
                items: _visibilityOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _visibility = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _button('Insert', _insert),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 8, color: Color(0xff333333)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 10, 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: _button('Close', () => Navigator.pop(context)),
          ),
        ),
      ),
    );
  }

  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(top: 9, bottom: 5),
    child: Text(
      label,
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

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => SizedBox(
    height: 26,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
      decoration: _decoration(),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );

  Widget _editor() => Container(
    height: 170,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffd2d9df)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Column(
      children: [
        _toolbar(),
        Expanded(
          child: TextField(
            controller: _details,
            expands: true,
            maxLines: null,
            style: const TextStyle(fontSize: 10),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(6),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _toolbar() => Container(
    height: 58,
    color: const Color(0xfff2f3f4),
    padding: const EdgeInsets.all(3),
    child: Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        Icons.format_bold,
        Icons.format_italic,
        Icons.format_underlined,
        Icons.format_list_bulleted,
        Icons.format_list_numbered,
        Icons.link,
        Icons.image,
        Icons.close,
        Icons.code,
        Icons.help_outline,
      ].map((icon) => _tool(icon)).toList(),
    ),
  );

  Widget _tool(IconData icon) => InkWell(
    onTap: () {
      if (icon == Icons.close) {
        _details.clear();
        return;
      }

      final text = _details.text;
      if (icon == Icons.format_bold) {
        _details.text = '$text**bold** ';
      } else if (icon == Icons.format_italic) {
        _details.text = '$text*italic* ';
      } else if (icon == Icons.format_underlined) {
        _details.text = '${text}__underlined__ ';
      }

      _details.selection = TextSelection.fromPosition(
        TextPosition(offset: _details.text.length),
      );
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
  );

  Widget _button(String text, VoidCallback onPressed) => SizedBox(
    height: 20,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff087ff5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 8)),
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
