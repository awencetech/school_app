import 'package:flutter/material.dart';

import '../../models/gate_register.dart';
import '../../routes/app_routes.dart';
import '../../services/gate_register_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class GateRegisterPage extends StatefulWidget {
  const GateRegisterPage({super.key});

  @override
  State<GateRegisterPage> createState() => _GateRegisterPageState();
}

class _GateRegisterPageState extends State<GateRegisterPage> {
  final _service = GateRegisterService();
  static const _types = ['Student', 'Staff', 'Parent', 'Others'];
  List<GateRegister> _records = const [];
  int _tab = 0;
  bool _loading = true;
  String? _error;

  List<GateRegister> get _visible =>
      _records.where((record) => record.personType == _types[_tab]).toList();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openForm([GateRegister? record]) async {
    final result = await showDialog<GateRegister>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GateRegisterForm(record: record),
    );
    if (result == null) return;
    try {
      final saved = await _service.save(result);
      if (!mounted) return;
      setState(() {
        final index = _records.indexWhere((item) => item.id == saved.id);
        _records = index == -1 ? [saved, ..._records] : [..._records]
          ..[index] = saved;
        _tab = _types.indexOf(saved.personType).clamp(0, _types.length - 1);
      });
      _snack(
        record == null
            ? 'Gate record added successfully.'
            : 'Gate record updated successfully.',
      );
    } catch (error) {
      if (mounted) {
        _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _delete(GateRegister record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gate Register Record'),
        content: const Text(
          'Are you sure you want to delete this Gate Register record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || record.id == null) return;
    try {
      await _service.delete(record.id!);
      if (!mounted) return;
      setState(
        () =>
            _records = _records.where((item) => item.id != record.id).toList(),
      );
      _snack('Gate record deleted successfully.');
    } catch (error) {
      if (mounted) {
        _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  void _snack(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Entry Gate Register'),
        actions: [
          IconButton(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? 16.0 : 32.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Entry Gate Register',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _loadRecords,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<int>(
                    segments: _types
                        .asMap()
                        .entries
                        .map(
                          (entry) => ButtonSegment<int>(
                            value: entry.key,
                            label: Text(entry.value),
                          ),
                        )
                        .toList(),
                    selected: {_tab},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    _StateMessage(message: _error!, action: _loadRecords)
                  else if (_visible.isEmpty)
                    _StateMessage(
                      message:
                          'No ${_types[_tab].toLowerCase()} gate records available.',
                    )
                  else
                    ..._visible.map(
                      (record) => GateRecordCard(
                        record: record,
                        onEdit: () => _openForm(record),
                        onDelete: () => _delete(record),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminDashboard,
              (route) => false,
            );
          }
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          }
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
      ),
    );
  }
}

class GateRecordCard extends StatelessWidget {
  const GateRecordCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final GateRegister record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = record.entryDate;
    final gate = record.gateNo == 'Other' && record.customGateNo.isNotEmpty
        ? record.customGateNo
        : record.gateNo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.meeting_room_outlined, size: 28),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gate No: $gate',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Person: ${record.personType}'),
                  Text('Entry Date: ${_date(date)}'),
                  Text('Entry Time: ${_time(date, context)}'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(label: Text(record.status)),
                Wrap(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime? value) => value == null
      ? 'Not available'
      : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
  String _time(DateTime? value, BuildContext context) => value == null
      ? 'Not available'
      : TimeOfDay.fromDateTime(value).format(context);
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.action});
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class GateRegisterForm extends StatefulWidget {
  const GateRegisterForm({super.key, this.record});
  final GateRegister? record;

  @override
  State<GateRegisterForm> createState() => _GateRegisterFormState();
}

class _GateRegisterFormState extends State<GateRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _gateNo;
  late String? _personType;
  late final TextEditingController _customGate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _gateNo = widget.record?.gateNo;
    _personType = widget.record?.personType;
    _customGate = TextEditingController(
      text: widget.record?.customGateNo ?? '',
    );
  }

  @override
  void dispose() {
    _customGate.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _gateNo = null;
    _personType = null;
    _customGate.clear();
  });

  void _submit() {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final old = widget.record;
    Navigator.pop(
      context,
      GateRegister(
        id: old?.id,
        gateNo: _gateNo!,
        customGateNo: _gateNo == 'Other' ? _customGate.text.trim() : '',
        personType: _personType!,
        entryDate: old?.entryDate ?? DateTime.now(),
        status: old?.status ?? 'Registered',
        createdAt: old?.createdAt,
        updatedAt: old?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.record != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(editing ? 'Edit record' : 'Add a record')),
          IconButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gate No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioGroup<String>(
                  groupValue: _gateNo,
                  onChanged: (value) => setState(() => _gateNo = value),
                  child: const Column(
                    children: [
                      RadioListTile<String>(value: '1', title: Text('1')),
                      RadioListTile<String>(value: '2', title: Text('2')),
                      RadioListTile<String>(value: '3', title: Text('3')),
                      RadioListTile<String>(
                        value: 'Other',
                        title: Text('Other'),
                      ),
                    ],
                  ),
                ),
                if (_gateNo == 'Other')
                  TextFormField(
                    controller: _customGate,
                    decoration: const InputDecoration(
                      labelText: 'Enter Gate Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _gateNo == 'Other' &&
                            (value == null || value.trim().isEmpty)
                        ? 'Enter a custom gate number.'
                        : null,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Person',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioGroup<String>(
                  groupValue: _personType,
                  onChanged: (value) => setState(() => _personType = value),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'Student',
                        title: Text('Student'),
                      ),
                      RadioListTile<String>(
                        value: 'Staff',
                        title: Text('Staff'),
                      ),
                      RadioListTile<String>(
                        value: 'Parent',
                        title: Text('Parent'),
                      ),
                      RadioListTile<String>(
                        value: 'Others',
                        title: Text('Others'),
                      ),
                    ],
                  ),
                ),
                if (_gateNo == null || _personType == null)
                  Text(
                    'Gate number and person type are required.',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : _reset,
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editing ? 'Update' : 'Insert'),
        ),
      ],
    );
  }
}
