import 'package:flutter/material.dart';

import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class StaffDetailsPage extends StatefulWidget {
  const StaffDetailsPage({super.key, required this.staff});

  final StaffInfo staff;

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late StaffInfo _staff;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _staff = widget.staff;
    final staff = _staff;
    _fields = {
      'Employee Name': TextEditingController(text: staff.name),
      'Mobile No': TextEditingController(text: staff.mobileNo),
      'Shareable Contact No': TextEditingController(text: staff.shareableContactNo),
      'Mail Id': TextEditingController(text: staff.mailId),
      'Address': TextEditingController(text: staff.address),
      'Brief Introduction - Something about yourself': TextEditingController(text: staff.briefIntroduction),
      'Hobbies and Interest': TextEditingController(text: staff.hobbiesAndInterest),
      'Sport/s you actively participate': TextEditingController(text: staff.sports),
      'Sports - Training School/Trained by details': TextEditingController(text: staff.sportsTrainingDetails),
      'Sports - Name the Team/s or Club/s you are associated with': TextEditingController(text: staff.sportsTeamClub),
      'Achievements- Academic or Non-Academic outside of School': TextEditingController(text: staff.achievements),
      'Extra-Curricular activity/s that you actively participate': TextEditingController(text: staff.extraCurricularActivities),
      'Extra-Curricular - Name the Team/s or Club/s you are associated with': TextEditingController(text: staff.extraCurricularTeamClub),
      'Professional Body Association': TextEditingController(text: staff.professionalBodyAssociation),
      'What you do': TextEditingController(text: staff.whatYouDo),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _staff.id == null) return;
    setState(() => _saving = true);
    final staff = StaffInfo(
      id: _staff.id,
      name: _value('Employee Name'),
      designation: _staff.designation,
      employeeCategory: _staff.employeeCategory,
      employeeId: _staff.employeeId,
      teaches: _staff.teaches,
      about: _staff.about,
      hobbiesAndInterest: _value('Hobbies and Interest'),
      role: _staff.role,
      imageUrl: _staff.imageUrl,
      mobileNo: _value('Mobile No'),
      shareableContactNo: _value('Shareable Contact No'),
      mailId: _value('Mail Id'),
      address: _value('Address'),
      briefIntroduction: _value('Brief Introduction - Something about yourself'),
      sports: _value('Sport/s you actively participate'),
      sportsTrainingDetails: _value('Sports - Training School/Trained by details'),
      sportsTeamClub: _value('Sports - Name the Team/s or Club/s you are associated with'),
      achievements: _value('Achievements- Academic or Non-Academic outside of School'),
      extraCurricularActivities: _value('Extra-Curricular activity/s that you actively participate'),
      extraCurricularTeamClub: _value('Extra-Curricular - Name the Team/s or Club/s you are associated with'),
      professionalBodyAssociation: _value('Professional Body Association'),
      whatYouDo: _value('What you do'),
    );
    try {
      final savedStaff = await StaffService().updateStaff(staff);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee information saved.')));
      setState(() {
        _staff = savedStaff;
        _editing = false;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String label) => _fields[label]!.text.trim();

  Widget _field(String label, {bool multiline = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: TextFormField(
        controller: _fields[label],
        minLines: multiline ? 2 : 1,
        maxLines: multiline ? 4 : 1,
        validator: label == 'Employee Name' ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget _editBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _field('Employee Name', multiline: false),
          _field('Mobile No', multiline: false),
          _field('Shareable Contact No', multiline: false),
          _field('Mail Id', multiline: false),
          _field('Address'),
          _field('Brief Introduction - Something about yourself'),
          _field('Hobbies and Interest'),
          const _SectionTitle('Sports'),
          _field('Sport/s you actively participate'),
          _field('Sports - Training School/Trained by details'),
          _field('Sports - Name the Team/s or Club/s you are associated with'),
          const _SectionTitle('Achievements'),
          _field('Achievements- Academic or Non-Academic outside of School'),
          const _SectionTitle('Extra-curricular activities'),
          _field('Extra-Curricular activity/s that you actively participate'),
          _field('Extra-Curricular - Name the Team/s or Club/s you are associated with'),
          const _SectionTitle('Professional body association'),
          _field('Professional Body Association'),
          _field('What you do'),
          FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save')),
        ],
      ),
    );
  }

  Widget _viewBody() {
    final staff = _staff;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Employee Info'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: _editing ? _editBody() : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Employee Info', style: TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
              const Divider(height: 8, color: Color(0xFFE5E5E5)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        _line('Employee Id', staff.employeeId),
                        _line('Employee Category', staff.employeeCategory),
                        _line('Designation', staff.designation),
                        _line('Mobile No', staff.mobileNo),
                        _line('Shareable Contact No', staff.shareableContactNo),
                        _line('Mail Id', staff.mailId),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StaffPhoto(url: staff.imageUrl),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _StaffShortcut(
                    icon: Icons.info,
                    label: 'Staff Info',
                    color: const Color(0xFF22C8C8),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.staffInfo,
                      arguments: staff,
                    ),
                  ),
                  const SizedBox(width: 28),
                  _StaffShortcut(
                    icon: Icons.folder,
                    label: 'Staff Resources',
                    color: const Color(0xFF8D6E63),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.staffResources),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _section('Teaches', staff.teaches),
              _section('About', staff.about),
              _section('Hobbies & Interest', staff.hobbiesAndInterest),
              _section('Role', staff.role),
              _section('Address', staff.address),
              _section('Brief Introduction - Something about yourself', staff.briefIntroduction),
              _section('Sports', staff.sports),
              _section('Sports Training', staff.sportsTrainingDetails),
              _section('Sports Team/Club', staff.sportsTeamClub),
              _section('Achievements', staff.achievements),
              _section('Extra-curricular activities', staff.extraCurricularActivities),
              _section('Extra-curricular Team/Club', staff.extraCurricularTeamClub),
              _section('Professional Body Association', staff.professionalBodyAssociation),
              _section('What you do', staff.whatYouDo),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          } else if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _viewBody();

  Widget _line(String label, String value) {
    return Text('$label : $value', style: const TextStyle(fontSize: 11, color: Color(0xFF333333)));
  }

  Widget _section(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}

class _StaffShortcut extends StatelessWidget {
  const _StaffShortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Color(0xFF444444)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffPhoto extends StatelessWidget {
  const _StaffPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const SizedBox(
        width: 100,
        height: 120,
        child: ColoredBox(
          color: Color(0xFFE6E6E6),
          child: Icon(Icons.person, size: 42, color: Colors.white),
        ),
      );
    }
    return SizedBox(
      width: 100,
      height: 160,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFE6E6E6),
          child: Icon(Icons.person, size: 42, color: Colors.white),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
