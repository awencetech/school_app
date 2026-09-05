import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class PickDropEntryPage extends StatefulWidget {
  const PickDropEntryPage({super.key, required this.group});

  final Group group;

  @override
  State<PickDropEntryPage> createState() => _PickDropEntryPageState();
}

class _PickDropEntryPageState extends State<PickDropEntryPage> {
  final List<_PickDropStudent> _students = [
    const _PickDropStudent(
      'VEDARSH VISAKA MOORTHY P',
      'N(S1319)',
      'Pick & Drop',
    ),
    const _PickDropStudent(
      'VAISHAVI K M',
      'M(S1346)',
      'UNL - Route SP9 - 2026',
    ),
    const _PickDropStudent(
      'SHRIDHARSHINI M',
      'M(S875)',
      'UNL - Route Z3 2026,UNI - ROUTE SP7 - 2026',
    ),
  ];

  Future<void> _addPickDropType() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _PickDropForm(),
    );
  }

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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text(
          'Pick & Drop Entry',
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
              padding: const EdgeInsets.fromLTRB(7, 7, 3, 6),
              child: Text(
                '${widget.group.name} - Pick up and Drop Entry for the Class',
                style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _smallButton(
                  'Add Pick Drop Type for Student',
                  _addPickDropType,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 430,
                  child: Column(
                    children: [
                      _tableRow(const [
                        'Name',
                        'Pick & Drop Type',
                        'Action',
                        'Pick/Drop',
                      ], header: true),
                      ..._students.map(_studentRow),
                    ],
                  ),
                ),
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

  Widget _studentRow(_PickDropStudent student) {
    return Row(
      children: [
        _cell('${student.name}\n${student.id}', 105),
        _cell(student.type, 105),
        SizedBox(
          width: 65,
          height: 62,
          child: Container(
            decoration: _border(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton('Pick', Icons.keyboard_arrow_up),
                _actionButton('Drop', Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 155,
          height: 62,
          child: Container(decoration: _border()),
        ),
      ],
    );
  }

  Widget _tableRow(List<String> values, {bool header = false}) {
    const widths = [105.0, 105.0, 65.0, 155.0];
    return Row(
      children: List.generate(
        values.length,
        (index) => _cell(values[index], widths[index], header: header),
      ),
    );
  }

  Widget _cell(String text, double width, {bool header = false}) {
    return SizedBox(
      width: width,
      height: header ? 26 : 62,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: header ? const Color(0xffe9edf1) : const Color(0xfff4f4f4),
          border: Border.all(color: const Color(0xffd8dde1), width: 0.5),
        ),
        child: Text(
          text,
          maxLines: header ? 2 : 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: header ? 8 : 7,
            color: header ? const Color(0xff333333) : const Color(0xff164f86),
            fontWeight: header ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  BoxDecoration _border() {
    return BoxDecoration(
      color: const Color(0xfff4f4f4),
      border: Border.all(color: const Color(0xffd8dde1), width: 0.5),
    );
  }

  Widget _actionButton(String label, IconData icon) {
    return SizedBox(
      height: 20,
      width: 54,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 12, color: const Color(0xff008ac5)),
        label: Text(
          label,
          style: const TextStyle(fontSize: 8, color: Color(0xff008ac5)),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xff66cde5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }

  Widget _smallButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 20,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, size: 11),
        label: Text(label, style: const TextStyle(fontSize: 8)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff008ac5),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          elevation: 0,
          side: const BorderSide(color: Color(0xff66cde5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

class _PickDropStudent {
  const _PickDropStudent(this.name, this.id, this.type);

  final String name;
  final String id;
  final String type;
}

class _PickDropForm extends StatefulWidget {
  const _PickDropForm();

  @override
  State<_PickDropForm> createState() => _PickDropFormState();
}

class _PickDropFormState extends State<_PickDropForm> {
  String _pickDropType = '(Select One)';
  final _studentsController = TextEditingController();

  @override
  void dispose() {
    _studentsController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _pickDropType = '(Select One)';
      _studentsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        height: 252,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 31,
              color: const Color(0xfff8f8f8),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Pick and Drop Type for Student',
                      style: TextStyle(fontSize: 11, color: Color(0xff333333)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xff777777),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffdddddd)),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 16, 11, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pick Drop Type',
                    style: TextStyle(fontSize: 10, color: Color(0xff333333)),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: _pickDropType,
                    isDense: true,
                    decoration: _inputDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: '(Select One)',
                        child: Text(
                          '(Select One)',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Pick & Drop',
                        child: Text(
                          'Pick & Drop',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Pick Only',
                        child: Text(
                          'Pick Only',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Drop Only',
                        child: Text(
                          'Drop Only',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _pickDropType = value ?? '(Select One)'),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Select Students to Add',
                    style: TextStyle(fontSize: 10, color: Color(0xff333333)),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _studentsController,
                    style: const TextStyle(fontSize: 10),
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        height: 21,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: _buttonStyle(),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontSize: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _reset,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(30, 21),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 8,
                            color: Color(0xff444444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 8, color: Color(0xff333333)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xffbfc6cc)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xffbfc6cc)),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff087ff5),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    );
  }
}
