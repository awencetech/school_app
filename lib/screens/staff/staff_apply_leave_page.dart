import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_leave.dart';
import '../../services/app_state.dart';
import '../../services/staff_leave_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

class StaffApplyLeavePage extends StatefulWidget {
  const StaffApplyLeavePage({super.key});
  @override State<StaffApplyLeavePage> createState() => _StaffApplyLeavePageState();
}

class _StaffApplyLeavePageState extends State<StaffApplyLeavePage> {
  final _service = StaffLeaveService();
  List<StaffLeaveRequest> _requests = const [];
  List<StaffLeaveEntitlement> _entitlements = const [];
  bool _loading = true;
  String? _error;
  int _year = DateTime.now().year;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final staffId = context.read<AppState>().currentUserId?.trim() ?? '';
    if (staffId.isEmpty) { setState(() { _loading = false; _error = 'No signed-in staff member was found.'; }); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_service.requests(staffId), _service.entitlements(staffId, _year)]);
      if (!mounted) return;
      setState(() { _requests = results[0] as List<StaffLeaveRequest>; _entitlements = results[1] as List<StaffLeaveEntitlement>; _loading = false; });
    } catch (error) { if (mounted) setState(() { _error = error.toString(); _loading = false; }); }
  }

  Future<void> _openApply() async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _ApplyLeaveDialog(entitlements: _entitlements));
    if (saved == true) { await _load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted successfully'))); }
  }
  Future<void> _openAdjust() async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _AdjustLeaveDialog(entitlements: _entitlements));
    if (saved == true) await _load();
  }
  Future<void> _cancel(StaffLeaveRequest request) async {
    if (request.id == null) return;
    try { await _service.cancel(request.id!); await _load(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(backgroundColor: AppColors.topBar, foregroundColor: Colors.white, toolbarHeight: 45, leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back, size: 20)), title: const Text('Staff Leave', style: TextStyle(fontSize: 15)), centerTitle: true),
    body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(10, 10, 10, 24), children: [
      Align(alignment: Alignment.centerRight, child: Wrap(spacing: 9, children: [TextButton(onPressed: _loading ? null : _openApply, child: const Text('Apply for Leave', style: TextStyle(fontSize: 10))), TextButton(onPressed: _loading ? null : _openAdjust, child: const Text('Adjust Leave', style: TextStyle(fontSize: 10)))])),
      if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Loading leave information...')))
      else if (_error != null) _StateBox(text: _error!, action: TextButton(onPressed: _load, child: const Text('Retry')))
      else ...[
        _EntitlementSection(entitlements: _entitlements, year: _year),
        const SizedBox(height: 14),
        _RequestSection(
          title: 'Leave Requests',
          requests: _requests.where((item) => item.status.toLowerCase() == 'pending').toList(),
          onCancel: _cancel,
        ),
        const SizedBox(height: 14),
        _RequestSection(
          title: 'Leave History',
          requests: _requests.where((item) => item.status.toLowerCase() != 'pending').toList(),
          onCancel: _cancel,
          onClear: () {
            setState(() {
              _requests = _requests
                  .where((item) => item.status.toLowerCase() == 'pending')
                  .toList();
            });
          },
        ),
      ],
    ])),
    bottomNavigationBar: const StaffFooter(),
  );
}

class _EntitlementSection extends StatelessWidget {
  const _EntitlementSection({required this.entitlements, required this.year});
  final List<StaffLeaveEntitlement> entitlements; final int year;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _SectionTitle('Leave entitlements'), Padding(padding: const EdgeInsets.only(left: 4, top: 4, bottom: 3), child: Text('Year: $year', style: const TextStyle(fontSize: 10))), if (entitlements.isEmpty) const _StateBox(text: 'No leave entitlement data available') else Table(border: TableBorder.all(color: const Color(0xFFD1D5DB)), columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.1)}, children: [_row(['Type of Leave', 'Number of Leaves', 'Adjustment', 'Leave Taken'], true), ...entitlements.map((item) => _row([item.leaveType, _number(item.totalLeaves), _number(item.adjustment), _number(item.leaveTaken)], false))])]);
  TableRow _row(List<String> values, bool header) => TableRow(decoration: header ? const BoxDecoration(color: Color(0xFFE5E7EB)) : null, children: values.map((value) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: Text(value, style: TextStyle(fontSize: 8, fontWeight: header ? FontWeight.w700 : FontWeight.w400)))).toList());
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.title, required this.requests, required this.onCancel, this.onClear});
  final String title;
  final List<StaffLeaveRequest> requests; final Future<void> Function(StaffLeaveRequest) onCancel;
  final VoidCallback? onClear;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_SectionTitle(title), const Spacer(), if (onClear != null && requests.isNotEmpty) TextButton(onPressed: onClear, child: const Text('Clear', style: TextStyle(fontSize: 10)))]), const SizedBox(height: 5), if (requests.isEmpty) _StateBox(text: title == 'Leave History' ? 'No completed leave requests available' : 'No leave requests available') else ...requests.map((request) => _StaffLeaveRequestCard(request: request, onCancel: () => onCancel(request))) ]);
}

class _StaffLeaveRequestCard extends StatelessWidget {
  const _StaffLeaveRequestCard({required this.request, required this.onCancel});
  final StaffLeaveRequest request; final VoidCallback onCancel;
  @override Widget build(BuildContext context) { final status = request.status.toLowerCase(); final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : status == 'cancelled' ? Colors.grey : const Color(0xFFE08A00); return Container(margin: const EdgeInsets.only(bottom: 9, left: 2, right: 2), padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9DEE7)), borderRadius: BorderRadius.circular(4)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.leaveType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)), Text('From: ${_date(request.startDate)} to ${_date(request.endDate)}', style: const TextStyle(fontSize: 9)), Text('Begin Half Day: ${request.beginHalfDay ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 9)), Text('End Half Day: ${request.endHalfDay ? 'Yes' : 'No'}', style: const TextStyle(fontSize: 9)), Text('Reason: ${request.reason}', style: const TextStyle(fontSize: 9)), Text('Effective Days: ${_number(request.effectiveDays)}', style: const TextStyle(fontSize: 9)), Row(children: [Text('Status: ${_displayStatus(request.status)}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)), const Spacer(), if (status == 'pending') TextButton(onPressed: onCancel, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('Cancel', style: TextStyle(fontSize: 8)))]) , Text('Requested On: ${_date(request.createdAt)}', style: const TextStyle(fontSize: 9))])); }
}

class _ApplyLeaveDialog extends StatefulWidget {
  const _ApplyLeaveDialog({required this.entitlements}); final List<StaffLeaveEntitlement> entitlements;
  @override State<_ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}
class _ApplyLeaveDialogState extends State<_ApplyLeaveDialog> {
  final _key = GlobalKey<FormState>(); final _reason = TextEditingController(); final _service = StaffLeaveService();
  String? _type; int? _year; DateTime? _start; DateTime? _end; bool _begin = false; bool _endHalf = false; bool _saving = false;
  List<String> get _types => _availableLeaveTypes(widget.entitlements);
  List<int> get _years { final values = widget.entitlements.map((item) => item.year).where((item) => item > 0).toSet(); values.add(DateTime.now().year); return values.toList()..sort(); }
  double get _days { if (_start == null || _end == null || _end!.isBefore(_start!)) return 0; var value = _end!.difference(_start!).inDays + 1.0; if (_begin) value -= .5; if (_endHalf) value -= .5; return value; }
  Future<void> _pick(bool start) async { final picked = await showDatePicker(context: context, initialDate: (start ? _start : _end) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null && mounted) setState(() { if (start) _start = picked; else _end = picked; }); }
  Future<void> _submit() async { if (!_key.currentState!.validate() || _type == null || _year == null || _start == null || _end == null || _days <= 0 || _end!.isBefore(_start!)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete valid leave details.'))); return; } setState(() => _saving = true); try { final state = context.read<AppState>(); await _service.submit({'staffId': state.currentUserId, 'staffName': state.currentUserEmail ?? state.currentUserId, 'leaveType': _type, 'applicableYear': _year, 'startDate': _start!.toIso8601String(), 'endDate': _end!.toIso8601String(), 'beginHalfDay': _begin, 'endHalfDay': _endHalf, 'effectiveDays': _days, 'reason': _reason.text.trim()}); if (mounted) Navigator.pop(context, true); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); } finally { if (mounted) setState(() => _saving = false); } }
  @override
  Widget build(BuildContext context) => _DialogShell(
    title: 'Apply for leave',
    child: Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown('Please select type of leave', _types, _type, (value) => setState(() => _type = value)),
          _dropdown('Please enter Year Applicable for', _years.map((item) => item.toString()).toList(), _year?.toString(), (value) => setState(() => _year = int.tryParse(value ?? ''))),
          _dateField('Leave Start Date', _start, () => _pick(true)),
          CheckboxListTile(value: _begin, onChanged: _saving ? null : (value) => setState(() => _begin = value ?? false), contentPadding: EdgeInsets.zero, dense: true, title: const Text('Begin Half Day', style: TextStyle(fontSize: 10))),
          _dateField('Leave End Date', _end, () => _pick(false)),
          CheckboxListTile(value: _endHalf, onChanged: _saving ? null : (value) => setState(() => _endHalf = value ?? false), contentPadding: EdgeInsets.zero, dense: true, title: const Text('End Half Day', style: TextStyle(fontSize: 10))),
          Text('Effective Days: ${_number(_days)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextFormField(controller: _reason, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Enter the reason', border: OutlineInputBorder()), validator: (value) => (value ?? '').trim().isEmpty ? 'Reason is required.' : null),
          const SizedBox(height: 14),
          Row(children: [FilledButton(onPressed: _saving ? null : _submit, child: Text(_saving ? 'Saving...' : 'Leave Request', style: const TextStyle(fontSize: 10))), const SizedBox(width: 10), TextButton(onPressed: _saving ? null : () { _reason.clear(); setState(() { _type = null; _year = null; _start = null; _end = null; _begin = false; _endHalf = false; }); }, child: const Text('Reset', style: TextStyle(fontSize: 10)))]),
        ],
      ),
    ),
  );
  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) => Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(initialValue: items.contains(value) ? value : null, items: [const DropdownMenuItem(value: null, child: Text('(Select One)')), ...items.map((item) => DropdownMenuItem(value: item, child: Text(item)))], onChanged: _saving ? null : onChanged, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()), validator: (value) => value == null ? 'Selection is required.' : null));
  Widget _dateField(String label, DateTime? date, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: _saving ? null : onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today), isDense: true, border: const OutlineInputBorder()), child: Text(date == null ? 'dd-mm-yyyy' : _date(date)))));
}

class _AdjustLeaveDialog extends StatefulWidget { const _AdjustLeaveDialog({required this.entitlements}); final List<StaffLeaveEntitlement> entitlements; @override State<_AdjustLeaveDialog> createState() => _AdjustLeaveDialogState(); }
class _AdjustLeaveDialogState extends State<_AdjustLeaveDialog> {
  final _service = StaffLeaveService(); final _days = TextEditingController(); String? _type; int? _year; bool _saving = false;
  List<String> get _types => _availableLeaveTypes(widget.entitlements);
  List<int> get _years { final values = widget.entitlements.map((item) => item.year).where((item) => item > 0).toSet(); values.add(DateTime.now().year); return values.toList()..sort(); }
  Future<void> _add() async { final days = double.tryParse(_days.text.trim()); if (_type == null || _year == null || days == null || days <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a leave type and enter positive days.'))); return; } setState(() => _saving = true); try { final state = context.read<AppState>(); await _service.adjust({'staffId': state.currentUserId, 'leaveType': _type, 'year': _year, 'days': days}); if (mounted) Navigator.pop(context, true); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); } finally { if (mounted) setState(() => _saving = false); } }
  @override
  Widget build(BuildContext context) => _DialogShell(
    title: 'Adjust Leaves',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown('Leave Type', _types, _type, (value) => setState(() => _type = value)),
        _dropdown('Year', _years.map((item) => item.toString()).toList(), _year?.toString(), (value) => setState(() => _year = int.tryParse(value ?? ''))),
        TextField(controller: _days, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Days', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: _saving ? null : _add, child: Text(_saving ? 'Saving...' : 'Add'))),
      ],
    ),
  );
  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      items: [const DropdownMenuItem<String>(value: null, child: Text('(Select One)')), ...items.map((item) => DropdownMenuItem(value: item, child: Text(item)))],
      onChanged: _saving ? null : onChanged,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      validator: (selected) => selected == null ? 'Selection is required.' : null,
    ),
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18))]),
          const Divider(),
          child,
          const Divider(height: 24),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(fontSize: 9)))),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)));
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.text, this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9DEE7)), borderRadius: BorderRadius.circular(4)), child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 10))), if (action != null) action!]));
}
String _date(DateTime? value) => value == null ? 'Not available' : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
String _displayStatus(String status) => status.toLowerCase() == 'pending' ? 'Waiting' : status;

List<String> _availableLeaveTypes(List<StaffLeaveEntitlement> entitlements) {
  final types = <String>{'ML (Medical Leave)', 'Other'};
  types.addAll(
    entitlements
        .map((item) => item.leaveType.trim())
        .where((item) => item.isNotEmpty),
  );
  return types.toList();
}
