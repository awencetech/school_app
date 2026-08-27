import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

/// Staff profile and employment details screen.
class StaffInfoPage extends StatefulWidget {
  const StaffInfoPage({super.key});

  @override
  State<StaffInfoPage> createState() => _StaffInfoPageState();
}

class _StaffInfoPageState extends State<StaffInfoPage> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    const staffName = 'MOHAMED TADJHEEN R';
    const staffEmail = 'secretary.pr.universals@sriaurobindomira.org';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: const Text('Staff Info', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isEditing
            ? _StaffEditForm(onClose: () => setState(() => _isEditing = false))
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
                            onPressed: () => setState(() => _isEditing = true),
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            _ProfilePhoto(
                              imageSource: config.secretaryPhotoBase64,
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
                        const _OtherDetails(),
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

class _StaffEditForm extends StatelessWidget {
  const _StaffEditForm({required this.onClose});

  final VoidCallback onClose;

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
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Close edit form',
                ),
              ),
              _EditField(label: 'Employee Name', value: 'MOHAMED TADJHEEN R'),
              _EditField(label: 'Mobile No', value: '9500468146'),
              _EditField(label: 'Shareable Contact No', value: '9500468146'),
              _EditField(
                label: 'Mail Id',
                value: 'secretary.pr.universals@sriaurobindomira.org',
              ),
              _EditField(
                label: 'Address',
                value:
                    '36, Palani Andavar Kovil Street, Thiruparankundram, Madurai-05.',
              ),
              _EditField(
                label: 'Brief Introduction - Something about yourself',
                value:
                    'This is R. Mohamed Tadjheen, working as Designer & Secretary to principal at Sri Aurobindo Mira Universal School, Keelamathur, Madurai.',
                maxLines: 4,
              ),
              _EditField(
                label: 'Hobbies and Interest',
                value:
                    'My hobbies is to Watch Movies & Playing Games. Interest in Taking Photography.',
                maxLines: 3,
              ),
              const _EditGroupHeading('Sports'),
              _EditField(
                label: 'Sport/s you actively participate',
                value: 'Cricket, Football, Carrom, kho-kho and chess.',
                maxLines: 3,
              ),
              _EditField(
                label: 'Sports - Training School/Trained by details',
                value: 'Football and kho-kho',
                maxLines: 3,
              ),
              _EditField(
                label:
                    'Sports - Name the Team/s or Club/s you are associated with',
                value: 'No team',
                maxLines: 3,
              ),
              const _EditGroupHeading('Achievements'),
              _EditField(
                label:
                    'Achievements- Academic or Non-Academic outside of School',
                value: 'Zonal Level Runner in kho-kho.',
                maxLines: 3,
              ),
              const _EditGroupHeading('Extra-curricular activities'),
              _EditField(
                label:
                    'Extra-Curricular activity/s that you actively participate',
                value: 'Photography, Art & Craft and Dancing',
                maxLines: 3,
              ),
              _EditField(
                label: 'Extra-Curricular - Training School/Trained by details',
                value: 'No',
                maxLines: 3,
              ),
              _EditField(
                label:
                    'Extra-Curricular - Name the Team/s or Club/s you are associated with',
                value: 'no team',
                maxLines: 3,
              ),
              const _EditGroupHeading('Professional body association'),
              _EditField(
                label: 'Professional Body Association',
                value: 'No Professional body association',
                maxLines: 3,
              ),
              _EditField(
                label: 'What you do',
                value:
                    'I am Designer & Secretary to principal in SAM Universal, Photographer and System Admin work.',
                maxLines: 3,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087FF5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 11)),
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

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: value,
            maxLines: maxLines,
            minLines: maxLines,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
  const _EmployeeDetails({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF4B5563),
        height: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const Text('Employee Id : SAMNTS56'),
          const Text('Alternate Id : S56'),
          const Text('Gender : MALE'),
          Text('Mail Id : $email'),
          const Text('Mobile No : 9500468146'),
          const Text('Phone No : 9500468146'),
          const Text('Designation : Secretary'),
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
                _TableCell('Not associated with any class or group.'),
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
  const _OtherDetails();

  @override
  Widget build(BuildContext context) {
    return const Padding(
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
            Text(
              'Other Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF234E9B),
              ),
            ),
            Text('Employee Category: NTS-Grade 1'),
            SizedBox(height: 10),
            Text(
              'Address',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              '36, Palani Andavar Kovil Street, Thiruparankundram, Madurai-05.',
            ),
            SizedBox(height: 10),
            Text(
              'About',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'This is R. Mohamed Tajdheen, working as Designer & Secretary to principal at Sri Aurobindo Mira Universal School, Keelamathur.',
            ),
            SizedBox(height: 10),
            Text(
              'Interested Area:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'My hobbies is to Watch Movies & Playing Games. Interest in Taking Photography.',
            ),
            SizedBox(height: 10),
            Text(
              'Sports',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'Actively Participates in : Cricket, Football, Carrom, kho-kho and chess.',
            ),
            Text('Training School : Football and kho-kho'),
            Text('Part of Team/Club : No team'),
            SizedBox(height: 10),
            Text(
              'Achievements-Academic or Non-Academic outside of School',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text('Zonal Level Runner in kho-kho.'),
            SizedBox(height: 10),
            Text(
              'Extra-Curricular',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'Actively Participates in : Photography, Art & Craft and Dancing',
            ),
            Text('Training School : No team'),
            Text('Part of Team/Club : no team'),
            SizedBox(height: 10),
            Text(
              'Professional Body Association',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text('No Professional body association'),
            SizedBox(height: 10),
            SizedBox(height: 10),
            Text(
              'What you do:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text('I am Designer & Secretary to principal in SAM Universal,'),
            Text('Photographer and System Admin work.'),
          ],
        ),
      ),
    );
  }
}
