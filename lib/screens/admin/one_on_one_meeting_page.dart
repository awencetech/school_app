import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class OneOnOneMeetingPage extends StatefulWidget {
  const OneOnOneMeetingPage({super.key, required this.group});

  final Group group;

  @override
  State<OneOnOneMeetingPage> createState() => _OneOnOneMeetingPageState();
}

class _OneOnOneMeetingPageState extends State<OneOnOneMeetingPage> {
  final List<_MeetingStudent> _students = [
    const _MeetingStudent('S1197', 'SADAF FATHIMA.I', 'No Connect'),
    const _MeetingStudent('S1289', 'MIRASHI SINGH.J', 'No Connect'),
    const _MeetingStudent('S1319', 'ENDARSH VISHKA MOORTHY N', 'No Connect'),
    const _MeetingStudent('S1346', 'VAISHAVI K M', 'No Connect'),
    const _MeetingStudent('S1378', 'Ashish Kumar M', 'No Connect'),
    const _MeetingStudent('S1388', 'HARIPRAKASH M', 'No Connect'),
    const _MeetingStudent('S270', 'SURIYA VISWANATHAN K', 'No Connect'),
    const _MeetingStudent('S875', 'SRIDHARSHINI M', 'No Connect'),
    const _MeetingStudent('S1654', 'HARINI N', 'No Connect'),
    const _MeetingStudent('S1618', 'VAJINI K R', 'No Connect'),
    const _MeetingStudent('S1670', 'SANOFAR A', 'No Connect'),
    const _MeetingStudent('S1765', 'DWARAGA S', 'No Connect'),
    const _MeetingStudent('S1288', 'MITHUSHI SINGH J', 'No Connect'),
    const _MeetingStudent('S1288', 'MITHUSHI SINGH J', 'No Connect'),
    const _MeetingStudent('S1662', 'INIEYAA V.S', 'No Connect'),
    const _MeetingStudent('S1726', 'SAHANA SRI G', 'No Connect'),
    const _MeetingStudent('S1603', 'RICHIKKA R', 'No Connect'),
  ];

  Future<void> _setupMeeting() async {
    final student = await showDialog<String>(
      context: context,
      barrierColor: Colors.white,
      builder: (_) => const _MeetingForm(),
    );
    if (!mounted || student == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meeting setup for $student')),
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
          'Today in Class',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
                '${widget.group.name} - ${widget.group.year} - One on One Meetings',
                style: const TextStyle(fontSize: 11, color: Color(0xff1d3557)),
              ),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            Padding(
              padding: const EdgeInsets.only(left: 3, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _smallButton('Setup a Meeting', _setupMeeting, green: true),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(3, 5, 3, 3),
              child: Text.rich(
                TextSpan(
                  text: 'Meetings Color code legend: ',
                  style: TextStyle(fontSize: 9, color: Color(0xff333333)),
                  children: [
                    TextSpan(text: '●', style: TextStyle(color: Color(0xff00695c))),
                    TextSpan(text: ' Completed ', style: TextStyle(color: Color(0xff333333))),
                    TextSpan(text: '●', style: TextStyle(color: Color(0xffef6c00))),
                    TextSpan(text: ' To be done ', style: TextStyle(color: Color(0xff333333))),
                    TextSpan(text: '●', style: TextStyle(color: Color(0xffc62828))),
                    TextSpan(text: ' Meeting missed', style: TextStyle(color: Color(0xff333333))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _meetingTable(),
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

  Widget _meetingTable() {
    return Column(
      children: [
        _tableRow(
          const [
            'Student\nID',
            'Student Name',
            'Status',
            'Meetings',
            'Action',
          ],
          header: true,
        ),
        ..._students.map(
          (student) => _tableRow([
            student.id,
            student.name,
            student.status,
            '',
            '▧ View',
          ]),
        ),
      ],
    );
  }

  Widget _tableRow(List<String> values, {bool header = false}) {
    const widths = [44.0, 117.0, 58.0, 45.0, 40.0];
    return Row(
      children: List.generate(values.length, (index) {
        return SizedBox(
          width: widths[index],
          child: Container(
            height: header ? 29 : 16,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: header ? const Color(0xfff5f5f5) : Colors.white,
              border: Border.all(color: const Color(0xffe1e5e8), width: 0.5),
            ),
            child: Text(
              values[index],
              maxLines: header ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: header ? 8 : 7,
                color: header ? const Color(0xff333333) : const Color(0xff164f86),
                fontWeight: header ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _smallButton(String label, VoidCallback onPressed, {bool green = false}) {
    return SizedBox(
      height: 20,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green ? const Color(0xff168b4b) : const Color(0xff087ff5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 8)),
      ),
    );
  }
}

class _MeetingStudent {
  const _MeetingStudent(this.id, this.name, this.status);

  final String id;
  final String name;
  final String status;
}

class _MeetingForm extends StatefulWidget {
  const _MeetingForm();

  @override
  State<_MeetingForm> createState() => _MeetingFormState();
}

class _MeetingFormState extends State<_MeetingForm> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _info = TextEditingController();
  final _url = TextEditingController();
  String _student = '(Select One)';

  final _studentOptions = const [
    '(Select One)',
    'SADAF FATHIMA.I',
    'MIRASHI SINGH.J',
    'ENDARSH VISHKA MOORTHY N',
    'VAISHAVI K M',
  ];

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _info.dispose();
    _url.dispose();
    super.dispose();
  }

  void _reset() {
    _start.clear();
    _end.clear();
    _info.clear();
    _url.clear();
    setState(() => _student = '(Select One)');
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
          title: const Text('Setup Meeting', style: TextStyle(fontSize: 12, color: Color(0xff222222))),
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 16, color: Color(0xff777777)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Select Student'),
              _dropdown(),
              _label('Start Date/Time'),
              _input(_start),
              _label('End Date/Time'),
              _input(_end),
              _label('Meeting Info (How and where)'),
              SizedBox(height: 40, child: _input(_info, maxLines: 2)),
              _label('Meeting URL link for Voice/Video Conference'),
              _input(_url),
              const SizedBox(height: 23),
              Row(
                children: [
                  _button('Insert', () {
                    if (_student != '(Select One)') Navigator.pop(context, _student);
                  }),
                  const SizedBox(width: 9),
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Reset', style: TextStyle(fontSize: 8, color: Color(0xff333333))),
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
    padding: const EdgeInsets.only(top: 11, bottom: 5),
    child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff333333))),
  );

  Widget _dropdown() => SizedBox(
    height: 26,
    child: DropdownButtonFormField<String>(
      initialValue: _student,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 10, color: Color(0xff333333)),
      decoration: _decoration(),
      items: _studentOptions.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _student = value);
      },
    ),
  );

  Widget _input(TextEditingController controller, {int maxLines = 1}) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 10),
    decoration: _decoration(),
  );

  Widget _button(String label, VoidCallback onPressed) => SizedBox(
    height: 20,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff087ff5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 7), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
      child: Text(label, style: const TextStyle(fontSize: 8)),
    ),
  );

  InputDecoration _decoration() => const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xffd2d9df))),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xffd2d9df))),
  );
}