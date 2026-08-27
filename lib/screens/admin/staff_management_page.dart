import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/staff_info.dart';
import '../../routes/app_routes.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final StaffService _service = StaffService();
  List<StaffInfo> _staff = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() { _loading = true; _error = null; });
    try {
      final staff = await _service.getStaff();
      if (!mounted) return;
      setState(() => _staff = staff);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([StaffInfo? staff]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StaffFormPage(staff: staff)),
    );
    if (saved == true) _loadStaff();
  }

  Future<void> _deleteStaff(StaffInfo staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Staff'),
        content: const Text('Are you sure you want to delete this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || staff.id == null) return;
    try {
      await _service.deleteStaff(staff.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deleted successfully.')));
        _loadStaff();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff')),
      body: RefreshIndicator(
        onRefresh: _loadStaff,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add Staff'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red))
                  else if (_staff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 100),
                      child: Center(child: Text('No Staff information available.')),
                    )
                  else
                    ..._staff.map((staff) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: _StaffThumbnail(url: staff.imageUrl),
                            title: Text(staff.name),
                            subtitle: Text('${staff.designation}\n${staff.employeeId}'),
                            isThreeLine: true,
                            trailing: Wrap(
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => _openForm(staff)),
                                IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () => _deleteStaff(staff)),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
      ),
      bottomNavigationBar: _AdminStaffNav(),
    );
  }
}

class StaffFormPage extends StatefulWidget {
  const StaffFormPage({super.key, this.staff});

  final StaffInfo? staff;

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  final StaffService _service = StaffService();
  late final Map<String, TextEditingController> _controllers;
  Uint8List? _imageBytes;
  String _imageName = '';
  String _imageUrl = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final staff = widget.staff;
    _controllers = {
      'Name': TextEditingController(text: staff?.name ?? ''),
      'Designation': TextEditingController(text: staff?.designation ?? ''),
      'Employee Category': TextEditingController(text: staff?.employeeCategory ?? ''),
      'Employee ID': TextEditingController(text: staff?.employeeId ?? ''),
      'Teaches': TextEditingController(text: staff?.teaches ?? ''),
      'About': TextEditingController(text: staff?.about ?? ''),
      'Hobbies & Interest': TextEditingController(text: staff?.hobbiesAndInterest ?? ''),
      'Role': TextEditingController(text: staff?.role ?? ''),
    };
    _imageUrl = staff?.imageUrl ?? '';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result.isEmpty) return;
    final file = result.first;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  void _removeImage() => setState(() { _imageBytes = null; _imageUrl = ''; _imageName = ''; });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var imageUrl = _imageUrl;
      if (_imageBytes != null) {
        imageUrl = await _service.uploadImage(fileName: _imageName, bytes: _imageBytes!);
      }
      final staff = StaffInfo(
        id: widget.staff?.id,
        name: _value('Name'), designation: _value('Designation'),
        employeeCategory: _value('Employee Category'), employeeId: _value('Employee ID'),
        teaches: _value('Teaches'), about: _value('About'),
        hobbiesAndInterest: _value('Hobbies & Interest'), role: _value('Role'), imageUrl: imageUrl,
      );
      if (widget.staff == null) {
        await _service.createStaff(staff);
      } else {
        await _service.updateStaff(staff);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff saved successfully.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _value(String key) => _controllers[key]!.text.trim();

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: Text(widget.staff == null ? 'Add Staff' : 'Edit Staff')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final entry in _controllers.entries) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: entry.value,
                validator: ['About', 'Hobbies & Interest'].contains(entry.key) ? null : _required,
                maxLines: ['About', 'Hobbies & Interest'].contains(entry.key) ? 4 : 1,
                decoration: InputDecoration(labelText: entry.key, border: const OutlineInputBorder()),
              ),
            ),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: _saving ? null : _pickImage, icon: const Icon(Icons.upload_file), label: Text(_imageBytes != null || _imageUrl.isNotEmpty ? 'Replace Image' : 'Upload Image'))),
                if (_imageBytes != null || _imageUrl.isNotEmpty) IconButton(onPressed: _removeImage, icon: const Icon(Icons.delete_outline), tooltip: 'Remove image'),
              ],
            ),
            if (_imageBytes != null || _imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(height: 140, child: _imageBytes != null ? Image.memory(_imageBytes!, fit: BoxFit.contain) : Image.network(_imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.broken_image))),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Staff')),
          ],
        ),
      ),
    );
  }
}

class _StaffThumbnail extends StatelessWidget {
  const _StaffThumbnail({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const CircleAvatar(child: Icon(Icons.person_outline));
    return CircleAvatar(backgroundImage: NetworkImage(url));
  }
}

class _AdminStaffNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          } else if (index == 3) Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          else Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
        },
      );
}
