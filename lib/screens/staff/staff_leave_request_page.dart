import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_leave_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';

class StaffLeaveRequestPage extends StatefulWidget {
  const StaffLeaveRequestPage({super.key});

  @override
  State<StaffLeaveRequestPage> createState() => _StaffLeaveRequestPageState();
}

class _StaffLeaveRequestPageState extends State<StaffLeaveRequestPage> {
  final _service = StaffLeaveService();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  static const _leaveTypes = ['Casual Leave', 'Sick Leave', 'Emergency Leave', 'Personal Leave', 'Other'];
  String _leaveType = _leaveTypes.first;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _sending = false;
  String? _error;

  String get _username => (context.read<AppState>().currentUserId ?? '').trim();

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
    );
    if (picked != null) setState(() => start ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final reason = _reasonController.text.trim();
    String? error;
    if (_username.isEmpty) error = 'Staff username is unavailable. Please log in again.';
    if ((state.currentAuthToken ?? '').trim().isEmpty) error = 'Your staff session has expired. Please log in again.';
    if (_startDate == null || _endDate == null) error = 'Please select both leave dates.';
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) error = 'End date cannot be before start date.';
    if (reason.isEmpty) error = 'Please enter a reason for leave.';
    if (state.currentUserRole?.trim().toLowerCase() != 'staff') error = 'Only staff can submit leave requests.';
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_sending) return;
    setState(() { _sending = true; _error = null; });
    try {
      await _service.submitStaffRequest(
        leaveType: _leaveType,
        startDate: _dateValue(_startDate!),
        endDate: _dateValue(_endDate!),
        reason: reason,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      _reasonController.clear();
      _notesController.clear();
      setState(() { _startDate = null; _endDate = null; _sending = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request sent successfully')));
    } catch (error) {
      if (mounted) setState(() { _sending = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const QuickAccessAppBar(title: 'Leave Request'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Apply for Leave', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('From', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(_username.isEmpty ? 'Staff' : _username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _leaveType,
              decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
              items: _leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) { if (value != null) setState(() => _leaveType = value); },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickDate(start: true), child: Text(_startDate == null ? 'Start Date' : _displayDate(_startDate!)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _pickDate(start: false), child: Text(_endDate == null ? 'End Date' : _displayDate(_endDate!)))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _reasonController, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Reason', alignLabelWithHint: true, border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notesController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Contact / Notes (optional)', alignLabelWithHint: true, border: OutlineInputBorder())),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _sending ? null : _submit, icon: const Icon(Icons.send), label: Text(_sending ? 'Sending...' : 'Send Request')),
          ]),
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(currentIndex: 2, onItemSelected: (index) { if (index == 4) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false); }, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
        BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
      ]),
    );
  }

  String _displayDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _dateValue(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
