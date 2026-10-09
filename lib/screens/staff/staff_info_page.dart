import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

/// Staff profile and employment details screen.
class StaffInfoPage extends StatefulWidget {
  const StaffInfoPage({super.key, this.staff, this.initialEditing = false});

  final StaffInfo? staff;
  final bool initialEditing;

  @override
  State<StaffInfoPage> createState() => _StaffInfoPageState();
}

class _StaffInfoPageState extends State<StaffInfoPage> {
  late bool _isEditing;
  StaffInfo? _staff;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditing;
    _staff = widget.staff;
    if (_staff == null) _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      final staffList = await StaffService().getStaff();
      if (!mounted || staffList.isEmpty) return;
      final currentUserId = context.read<AppState>().currentUserId?.trim().toLowerCase();
      final matchingStaff = currentUserId == null || currentUserId.isEmpty
          ? null
          : staffList.where((item) => item.employeeId.trim().toLowerCase() == currentUserId).firstOrNull;
      setState(() => _staff = matchingStaff);
    } catch (_) {
      // Keep the legacy fallback content when the service is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    final staff = _staff;
    final staffName = staff?.name ?? '';
    final staffEmail = staff?.mailId ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: const Text('Staff Info', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _isEditing
            ? _StaffEditForm(
                staff: staff,
                onClose: () => setState(() => _isEditing = false),
              )
            : staff == null
            ? const Center(
                child: Text('Staff information is currently unavailable.'),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Employee Info',
                          action: TextButton(
                            onPressed: () async {
                              final saved = await Navigator.of(context).pushNamed(
                                AppRoutes.staffInfoEdit,
                                arguments: staff,
                              );
                              if (saved is StaffInfo && mounted) {
                                setState(() => _staff = saved);
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _EmployeeDetails(
                                name: staffName,
                                email: staffEmail,
                                staff: staff,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _ProfilePhoto(
                              imageSource: staff.imageUrl.trim().isNotEmpty
                                  ? staff.imageUrl
                                  : config.secretaryPhotoBase64 ?? '',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: 'Classes and Groups of $staffName',
                          action: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh, size: 16),
                            color: const Color(0xFF1976D2),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            tooltip: 'Refresh classes and groups',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const _ClassesTable(),
                        const SizedBox(height: 24),
                        _OtherDetails(staff: staff),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _StaffEditForm extends StatefulWidget {
  const _StaffEditForm({required this.staff, required this.onClose});

  final StaffInfo? staff;
  final VoidCallback onClose;

  @override
  State<_StaffEditForm> createState() => _StaffEditFormState();
}

class _StaffEditFormState extends State<_StaffEditForm> {
  final StaffService _service = StaffService();
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final staff = widget.staff;
    String value(String? current) => current ?? '';
    _controllers = {
      'Employee Name': TextEditingController(text: value(staff?.name)),
      'Mobile No': TextEditingController(text: value(staff?.mobileNo)),
      'Shareable Contact No': TextEditingController(
        text: value(staff?.shareableContactNo),
      ),
      'Mail Id': TextEditingController(text: value(staff?.mailId)),
      'Address': TextEditingController(text: value(staff?.address)),
      'Brief Introduction - Something about yourself':
          TextEditingController(text: value(staff?.briefIntroduction)),
      'Hobbies and Interest':
          TextEditingController(text: value(staff?.hobbiesAndInterest)),
      'Sport/s you actively participate':
          TextEditingController(text: value(staff?.sports)),
      'Sports - Training School/Trained by details':
          TextEditingController(text: value(staff?.sportsTrainingDetails)),
      'Sports - Name the Team/s or Club/s you are associated with':
          TextEditingController(text: value(staff?.sportsTeamClub)),
      'Achievements- Academic or Non-Academic outside of School':
          TextEditingController(text: value(staff?.achievements)),
      'Extra-Curricular activity/s that you actively participate':
          TextEditingController(text: value(staff?.extraCurricularActivities)),
      'Extra-Curricular - Training School/Trained by details':
          TextEditingController(),
      'Extra-Curricular - Name the Team/s or Club/s you are associated with':
          TextEditingController(text: value(staff?.extraCurricularTeamClub)),
      'Professional Body Association':
          TextEditingController(text: value(staff?.professionalBodyAssociation)),
      'What you do': TextEditingController(text: value(staff?.whatYouDo)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String label) => _controllers[label]!.text.trim();

  Future<void> _save() async {
    final staff = widget.staff;
    if (staff?.id == null || _value('Employee Name').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee record is not available to save.')),
      );
      return;
    }
    setState(() => _saving = true);
    final updated = StaffInfo(
      id: staff!.id,
      name: _value('Employee Name'),
      designation: staff.designation,
      employeeCategory: staff.employeeCategory,
      employeeId: staff.employeeId,
      teaches: staff.teaches,
      about: staff.about,
      hobbiesAndInterest: _value('Hobbies and Interest'),
      role: staff.role,
      imageUrl: staff.imageUrl,
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
      final saved = await _service.updateStaff(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee information saved.')),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.staffInfo,
        arguments: saved,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[label],
        maxLines: maxLines,
        minLines: maxLines,
        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Close edit form',
                ),
              ),
              _field('Employee Name'),
              _field('Mobile No'),
              _field('Shareable Contact No'),
              _field('Mail Id'),
              _field('Address'),
              _field('Brief Introduction - Something about yourself', maxLines: 4),
              _field('Hobbies and Interest', maxLines: 3),
              const _EditGroupHeading('Sports'),
              _field('Sport/s you actively participate', maxLines: 3),
              _field('Sports - Training School/Trained by details', maxLines: 3),
              _field('Sports - Name the Team/s or Club/s you are associated with', maxLines: 3),
              const _EditGroupHeading('Achievements'),
              _field('Achievements- Academic or Non-Academic outside of School', maxLines: 3),
              const _EditGroupHeading('Extra-curricular activities'),
              _field('Extra-Curricular activity/s that you actively participate', maxLines: 3),
              _field('Extra-Curricular - Training School/Trained by details', maxLines: 3),
              _field('Extra-Curricular - Name the Team/s or Club/s you are associated with', maxLines: 3),
              const _EditGroupHeading('Professional body association'),
              _field('Professional Body Association', maxLines: 3),
              _field('What you do', maxLines: 3),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditGroupHeading extends StatelessWidget {
  const _EditGroupHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF234E9B),
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _EmployeeDetails extends StatelessWidget {
  const _EmployeeDetails({required this.name, required this.email, this.staff});

  final String name;
  final String email;
  final StaffInfo? staff;

  @override
  Widget build(BuildContext context) {
    final details = <({String label, String value})>[
      (label: 'Employee Id', value: staff?.employeeId ?? ''),
      (label: 'Employee Category', value: staff?.employeeCategory ?? ''),
      (label: 'Role', value: staff?.role ?? ''),
      (label: 'Mail Id', value: email),
      (label: 'Mobile No', value: staff?.mobileNo ?? ''),
      (label: 'Shareable Contact No', value: staff?.shareableContactNo ?? ''),
      (label: 'Designation', value: staff?.designation ?? ''),
    ].where((detail) => detail.value.trim().isNotEmpty);

    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF4B5563),
        height: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.trim().isNotEmpty)
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          for (final detail in details)
            Text('${detail.label} : ${detail.value}'),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({this.imageSource});

  final String? imageSource;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(width: 96, height: 96, child: _safeImage(imageSource)),
        const SizedBox(height: 2),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, size: 11),
            SizedBox(width: 2),
            Text('Take photo', style: TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _safeImage(String? source) {
    final value = source?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoFallback(),
      );
    }
    if (value.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(value),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _PhotoFallback(),
        );
      } on FormatException {
        return const _PhotoFallback();
      }
    }
    return const _PhotoFallback();
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.person, size: 54, color: Color(0xFF6B7280)),
    );
  }
}

class _ClassesTable extends StatelessWidget {
  const _ClassesTable();

  @override
  Widget build(BuildContext context) {
    const headers = ['Group/Class', 'Year', 'Type', 'Role', 'Class Status'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          border: TableBorder.all(color: const Color(0xFFD1D5DB)),
          columnWidths: const {
            0: FlexColumnWidth(1.7),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(0.8),
            3: FlexColumnWidth(0.8),
            4: FlexColumnWidth(1.3),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
              children: headers
                  .map((header) => _TableCell(header, bold: true))
                  .toList(),
            ),
            const TableRow(
              children: [
                _TableCell('No class or group information available.'),
                _TableCell(''),
                _TableCell(''),
                _TableCell(''),
                _TableCell(''),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: bold ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

class _OtherDetails extends StatelessWidget {
  const _OtherDetails({this.staff});

  final StaffInfo? staff;

  @override
  Widget build(BuildContext context) {
    final employee = staff;
    final details = <({String label, String value})>[
      (label: 'Employee Category', value: employee?.employeeCategory ?? ''),
      (label: 'Address', value: employee?.address ?? ''),
      (label: 'About', value: employee?.about ?? ''),
      (label: 'Interested Area', value: employee?.hobbiesAndInterest ?? ''),
      (label: 'Sports', value: employee?.sports ?? ''),
      (label: 'Sports training', value: employee?.sportsTrainingDetails ?? ''),
      (label: 'Sports team or club', value: employee?.sportsTeamClub ?? ''),
      (label: 'Achievements', value: employee?.achievements ?? ''),
      (
        label: 'Extra-curricular activities',
        value: employee?.extraCurricularActivities ?? '',
      ),
      (
        label: 'Extra-curricular team or club',
        value: employee?.extraCurricularTeamClub ?? '',
      ),
      (
        label: 'Professional body association',
        value: employee?.professionalBodyAssociation ?? '',
      ),
      (label: 'What you do', value: employee?.whatYouDo ?? ''),
    ].where((detail) => detail.value.trim().isNotEmpty);

    return Padding(
      padding: EdgeInsets.zero,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF4B5563),
          height: 1.45,
          fontWeight: FontWeight.w400,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF234E9B),
              ),
            ),
            if (details.isEmpty)
              const Text('Additional staff information is unavailable.')
            else
              for (final detail in details) ...[
                Text(
                  detail.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(detail.value),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
