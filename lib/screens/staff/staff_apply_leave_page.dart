import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

class StaffApplyLeavePage extends StatelessWidget {
  const StaffApplyLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        toolbarHeight: 45,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('Staff Leave', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PageHeading('Staff Leave'),
                  const SizedBox(height: 8),
                  _LeaveLinks(
                    onLeaveRequest: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _LeaveRequestDialog(),
                    ),
                    onAdjustLeave: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _AdjustLeaveDialog(),
                    ),
                  ),
                  SizedBox(height: 12),
                  _Entitlements(),
                  SizedBox(height: 14),
                  _Requests(),
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

class _PageHeading extends StatelessWidget {
  const _PageHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF234E9B)),
    ),
  );
}

class _LeaveLinks extends StatelessWidget {
  _LeaveLinks({
    required this.onLeaveRequest,
    required this.onAdjustLeave,
  });

  final VoidCallback onLeaveRequest;
  final VoidCallback onAdjustLeave;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: EdgeInsets.only(right: 3),
      child: Wrap(
        spacing: 9,
        children: [
          _ActionLink('Leave Request', onLeaveRequest),
          _ActionLink('Adjust Leave', onAdjustLeave),
        ],
      ),
    ),
  );
}

const _linkStyle = TextStyle(fontSize: 8, color: Color(0xFF087FF5));

class _LeaveRequestDialog extends StatelessWidget {
  const _LeaveRequestDialog();
  @override
  Widget build(BuildContext context) => const _LeaveFormDialog(
    title: 'Apply for leave',
    buttonText: 'Leave Request',
    fields: [
      'Please select type of leave',
      'Please enter Year Applicable for',
      'Leave Start Date',
      'Begin Half Day',
      'Leave End Date',
      'End Half Day',
      'Effective Days',
      'Enter the reason',
    ],
  );
}

class _AdjustLeaveDialog extends StatelessWidget {
  const _AdjustLeaveDialog();
  @override
  Widget build(BuildContext context) => const _LeaveFormDialog(
    title: 'Adjust Leaves',
    buttonText: 'Add',
    fields: ['Leave Type', 'Year', 'Days'],
  );
}

class _LeaveFormDialog extends StatelessWidget {
  const _LeaveFormDialog({
    required this.title,
    required this.buttonText,
    required this.fields,
  });
  final String title;
  final String buttonText;
  final List<String> fields;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const Divider(),
          ...fields.map(_field),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(buttonText, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 12),
              const Text('Reset', style: TextStyle(fontSize: 9)),
            ],
          ),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(String label) {
    if (label.contains('Half Day')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(value: false, onChanged: (_) {}),
            ),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
    }
    final isDropdown =
        label.contains('select') || label == 'Leave Type' || label == 'Year';
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          if (isDropdown)
            DropdownButtonFormField<String>(
              initialValue: '(Select One)',
              items: const [
                DropdownMenuItem(
                  value: '(Select One)',
                  child: Text('(Select One)'),
                ),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            )
          else
            TextFormField(
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Entitlements extends StatelessWidget {
  const _Entitlements();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      _SectionLabel('Leave entitlements'),
      _YearTable(year: '2020'),
      SizedBox(height: 10),
      _YearTable(year: '2023'),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _YearTable extends StatelessWidget {
  const _YearTable({required this.year});
  final String year;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          'Year: $year',
          style: const TextStyle(fontSize: 10, color: Color(0xFF111827)),
        ),
      ),
      Table(
        border: TableBorder.all(color: const Color(0xFFD1D5DB)),
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.1),
        },
        children: const [
          TableRow(
            decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
            children: [
              _Cell('Type Of Leave', bold: true),
              _Cell('Number Of Leaves', bold: true),
              _Cell('Adjustment', bold: true),
              _Cell('Leave Taken', bold: true),
            ],
          ),
          TableRow(
            children: [
              _Cell('Other Other'),
              _Cell('0'),
              _Cell('0'),
              _Cell('2'),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Requests extends StatelessWidget {
  const _Requests();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      _SectionLabel('Leave requests'),
      SizedBox(height: 5),
      _RequestCard(
        type: 'Other',
        dates: 'From 09-Sep-20 to 09-Sep-20',
        reason: 'Had Day No',
        approved: true,
      ),
      SizedBox(height: 9),
      _RequestCard(
        type: 'Other',
        dates: 'From 27-Nov-20 to 27-Nov-20',
        reason: 'Day No',
        approved: true,
      ),
    ],
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.type,
    required this.dates,
    required this.reason,
    required this.approved,
  });
  final String type;
  final String dates;
  final String reason;
  final bool approved;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFD9DEE7)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Text(
          dates,
          style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
        ),
        Text(
          'Begin Half Day: No',
          style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
        ),
        Text(
          'End Half Day: No',
          style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
        ),
        Text(
          'Reason: $reason',
          style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
        ),
        Row(
          children: [
            Text(
              'Status: ${approved ? 'approved' : 'applied'}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
            ),
            const SizedBox(width: 3),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: approved
                    ? const Color(0xFF62D878)
                    : const Color(0xFFFFB74D),
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.cancel,
                size: 11,
                color: Color(0xFF9CA3AF),
              ),
              label: const Text(
                'Cancel',
                style: TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const Text(
          'Effective Days requested : 1',
          style: TextStyle(fontSize: 9, color: Color(0xFF4B5563)),
        ),
      ],
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 8,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}

class _ActionLink extends StatelessWidget {
  const _ActionLink(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Text(label, style: _linkStyle),
  );
}
