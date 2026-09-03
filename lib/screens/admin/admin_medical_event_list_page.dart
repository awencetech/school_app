import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medical_event.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/medical_event_service.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminMedicalEventListPage extends StatefulWidget {
  const AdminMedicalEventListPage({super.key});
  @override
  State<AdminMedicalEventListPage> createState() => _AdminMedicalEventListPageState();
}

class _AdminMedicalEventListPageState extends State<AdminMedicalEventListPage> {
  final _service = MedicalEventService();
  List<MedicalEvent> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final events = await _service.getAll();
      if (!mounted) return;
      setState(() { _events = events; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  Future<void> _openForm([MedicalEvent? event]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MedicalEventForm(existing: event),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(MedicalEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medical Event?'),
        content: const Text('Are you sure you want to delete this medical event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || event.id == null) return;
    try {
      await _service.delete(event.id!);
      if (!mounted) return;
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical event deleted.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Medical Event List'),
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: canEdit ? () => _openForm() : null, icon: const Icon(Icons.add), label: const Text('Add Medical Event'))),
            const SizedBox(height: 16),
            if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null) _MessageBox(icon: Icons.error_outline, text: _error!, action: TextButton(onPressed: _load, child: const Text('Retry')))
            else if (_events.isEmpty) const _MessageBox(icon: Icons.medical_services_outlined, text: 'No medical events available')
            else ..._events.map((event) => _EventCard(event: event, canEdit: canEdit, onView: () => _showDetails(event), onEdit: () => _openForm(event), onDelete: () => _delete(event))),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
            case 2: Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false); break;
            case 1: Navigator.of(context).pushNamed(AppRoutes.adminDashboard); break;
            case 3: Navigator.of(context).pushNamed(AppRoutes.supportQuery); break;
            case 4: Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false); break;
          }
        },
      ),
    );
  }

  bool _canEdit(BuildContext context) {
    final role = context.read<AppState>().currentUserRole?.toLowerCase();
    return role == null || role == 'admin' || role == 'staff';
  }

  Future<void> _showDetails(MedicalEvent event) => showDialog<void>(context: context, builder: (_) => _MedicalEventDetails(event: event));
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFDFE7F1)), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [Icon(icon, size: 42, color: AppColors.topBar), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center), if (action != null) action!]),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.canEdit, required this.onView, required this.onEdit, required this.onDelete});
  final MedicalEvent event;
  final bool canEdit;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFDEE5EE))),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${event.studentName.toUpperCase()} (${event.studentId})', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      const SizedBox(height: 5), Text(event.className), const SizedBox(height: 12),
      _value('Description', event.description), _value('Created by', event.reportedByLabel), _value('Last Modified By', event.lastModifiedByLabel), _value('Last Modified', _formatDate(event.lastModifiedAt ?? event.updatedAt)),
      const Divider(height: 22), Row(children: [TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_outlined, size: 17), label: const Text('View')), if (canEdit) ...[const Spacer(), IconButton(onPressed: onEdit, tooltip: 'Edit', icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: onDelete, tooltip: 'Delete', icon: const Icon(Icons.delete_outline, color: Colors.redAccent))]])
    ])),
  );

  static Widget _value(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text('$label:\n${value.isEmpty ? 'Not available' : value}', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))));
}

class _MedicalEventForm extends StatefulWidget {
  const _MedicalEventForm({this.existing});
  final MedicalEvent? existing;
  @override State<_MedicalEventForm> createState() => _MedicalEventFormState();
}

class _MedicalEventFormState extends State<_MedicalEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _symptomController = TextEditingController();
  final _needsController = TextEditingController();
  final _studentService = StudentService();
  final _service = MedicalEventService();
  List<StudentRecord> _students = const [];
  StudentRecord? _student;
  PlatformFile? _file;
  Uint8List? _fileBytes;
  String _imageUrl = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    final event = widget.existing;
    if (event != null) {
      _classController.text = event.className;
      _descriptionController.text = event.description;
      _symptomController.text = event.symptomReported;
      _needsController.text = event.specialNeedsKnown;
      _imageUrl = event.reportImage;
    }
    _loadStudents();
  }

  @override
  void dispose() { _classController.dispose(); _descriptionController.dispose(); _symptomController.dispose(); _needsController.dispose(); super.dispose(); }

  Future<void> _loadStudents() async {
    try {
      final students = await _studentService.getStudents();
      if (!mounted) return;
      StudentRecord? selected;
      if (widget.existing != null) {
        for (final item in students) { if (item.studentId == widget.existing!.studentId) { selected = item; break; } }
      }
      setState(() { _students = students; _student = selected; _loading = false; });
    } catch (error) { if (mounted) setState(() { _loadError = error.toString(); _loading = false; }); }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;
    final bytes = await result.first.readAsBytes();
    if (mounted) setState(() { _file = result.first; _fileBytes = bytes; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _student == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.'))); return; }
    setState(() => _saving = true);
    try {
      var imageUrl = _imageUrl;
      if (_file != null && _fileBytes != null) imageUrl = await _service.uploadReport(_file!.name, _fileBytes!);
      final state = context.read<AppState>();
      final userId = (state.currentUserId ?? '').trim();
      final name = (state.currentUserEmail ?? '').trim();
      final actor = {'userId': userId, 'name': name.isEmpty ? userId : name};
      await _service.save(MedicalEvent(id: widget.existing?.id, studentId: _student!.studentId, studentName: _student!.name, className: _classController.text.trim(), description: _descriptionController.text.trim(), symptomReported: _symptomController.text.trim(), specialNeedsKnown: _needsController.text.trim(), reportImage: imageUrl, reportedBy: widget.existing?.reportedBy ?? actor, lastModifiedBy: actor));
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical event saved successfully.')));
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) content = const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    else if (_loadError != null) content = Text(_loadError!);
    else content = Form(key: _formKey, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<StudentRecord>(value: _student, isExpanded: true, decoration: const InputDecoration(labelText: 'Student', border: OutlineInputBorder()), items: _students.map((student) => DropdownMenuItem(value: student, child: Text('${student.name} (${student.studentId})'))).toList(), onChanged: _saving ? null : (value) => setState(() => _student = value), validator: (value) => value == null ? 'Student is required.' : null),
      const SizedBox(height: 12), _field(_classController, 'Class', true), const SizedBox(height: 12), _field(_descriptionController, 'Description', true, 3), const SizedBox(height: 16),
      const Text('First Observations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), const SizedBox(height: 10), _field(_symptomController, 'Symptom Reported', true, 3), const SizedBox(height: 12), _field(_needsController, 'Special Needs Known', false, 3), const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _saving ? null : _pickImage, icon: const Icon(Icons.upload_file), label: const Text('Upload Medical Report Image (Optional)')),
      if (_fileBytes != null) _imagePreview(_fileBytes!, _file!.name, () => setState(() { _file = null; _fileBytes = null; })) else if (_imageUrl.isNotEmpty) _networkPreview(),
    ])));
    return AlertDialog(title: Text(widget.existing == null ? 'Add Medical Event' : 'Edit Medical Event'), content: SizedBox(width: 540, child: content), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save), label: Text(_saving ? 'Saving...' : 'Save Medical Event'))]);
  }

  Widget _field(TextEditingController controller, String label, bool required, [int lines = 1]) => TextFormField(controller: controller, minLines: lines, maxLines: lines == 1 ? 1 : 5, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), validator: required ? (value) => (value ?? '').trim().isEmpty ? '$label is required.' : null : null);
  Widget _imagePreview(Uint8List bytes, String name, VoidCallback remove) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 10), Image.memory(bytes, height: 140, fit: BoxFit.contain), Row(children: [Expanded(child: Text(name, overflow: TextOverflow.ellipsis)), IconButton(onPressed: remove, icon: const Icon(Icons.close))])]);
  Widget _networkPreview() => Column(children: [const SizedBox(height: 10), Image.network(_imageUrl, height: 140, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('Unable to load image')), Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => setState(() => _imageUrl = ''), icon: const Icon(Icons.close)))]);
}

class _MedicalEventDetails extends StatelessWidget {
  const _MedicalEventDetails({required this.event});
  final MedicalEvent event;
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Medical Event Display - Details of a Medical Event'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Student: ${event.studentName} (${event.studentId})'), Text('Class: ${event.className}'), _detail('Last modified by:', event.lastModifiedByLabel), _detail('Description:', event.description), const SizedBox(height: 14), const Text('First Observations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), _detail('Symptom Reported:', event.symptomReported), _detail('Special Needs Known:', event.specialNeedsKnown.isEmpty ? 'None recorded' : event.specialNeedsKnown), if (event.reportImage.isNotEmpty) ...[const SizedBox(height: 10), const Text('Medical Report', style: TextStyle(fontWeight: FontWeight.w700)), Image.network(event.reportImage, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('Unable to load medical report image.'))], _detail('Reported by:', event.reportedByLabel), _detail('Reported Date:', _formatDate(event.createdAt)), _detail('Last Modified:', _formatDate(event.lastModifiedAt ?? event.updatedAt))]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]);
  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.only(top: 10), child: Text('$label\n${value.isEmpty ? 'Not available' : value}', style: const TextStyle(color: Color(0xFF374151))));
}

String _formatDate(DateTime? date) => date == null ? 'Not available' : '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
