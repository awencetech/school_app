import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/staff_info.dart';
import '../../models/staff_resource.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_resource_service.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminStaffResourcePage extends StatefulWidget {
  const AdminStaffResourcePage({super.key});

  @override
  State<AdminStaffResourcePage> createState() => _AdminStaffResourcePageState();
}

class _AdminStaffResourcePageState extends State<AdminStaffResourcePage> {
  final _staffService = StaffService();
  final _resourceService = StaffResourceService();
  List<StaffInfo> _staff = const [];
  List<StaffResource> _resources = const [];
  bool _staffLoading = true;
  bool _resourcesLoading = true;
  String? _staffError;
  String? _resourcesError;

  String? get _token => context.read<AppState>().currentAuthToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _staffLoading = true;
      _resourcesLoading = true;
      _staffError = null;
      _resourcesError = null;
    });
    await Future.wait([_loadStaff(), _loadResources()]);
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _staffService.getStaff();
      if (mounted) setState(() { _staff = staff; _staffLoading = false; });
    } catch (error, stackTrace) {
      debugPrint('Unable to load staff information: $error\n$stackTrace');
      if (mounted) setState(() { _staffLoading = false; _staffError = 'Unable to load staff information.'; });
    }
  }

  Future<void> _loadResources() async {
    try {
      final resources = await _resourceService.getAll(token: _token);
      if (mounted) setState(() { _resources = resources; _resourcesLoading = false; });
    } catch (error, stackTrace) {
      debugPrint('Unable to load staff resources: $error\n$stackTrace');
      if (mounted) setState(() { _resourcesLoading = false; _resourcesError = _message(error); });
    }
  }

  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');

  Future<void> _openForm([StaffResource? resource]) async {
    if (_staffLoading) {
      _toast('Staff members are still loading.', error: true);
      return;
    }
    if (_staff.isEmpty) {
      _toast('Add a staff profile before creating a resource.', error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StaffResourceForm(
        staff: _staff,
        resource: resource,
        onSave: (value) async {
          if (resource == null) {
            await _resourceService.create(value, token: _token);
          } else {
            await _resourceService.update(value, token: _token);
          }
        },
      ),
    );
    if (saved == true) {
      await _load();
      if (mounted) _toast(resource == null ? 'Resource saved successfully.' : 'Resource updated successfully.');
    }
  }

  Future<void> _delete(StaffResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resource?'),
        content: const Text('This resource will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || resource.id == null) return;
    try {
      await _resourceService.delete(resource.id!, token: _token);
      await _load();
      if (mounted) _toast('Resource deleted successfully.');
    } catch (error) {
      if (mounted) _toast(_message(error), error: true);
    }
  }

  void _toast(String message, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: error ? Colors.red.shade700 : null),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Staff Resources')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _staffLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  const Text('Staff Resources', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Manage and share staff resources, reports and documents.'),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Add Resource')),
                  ),
                  const SizedBox(height: 22),
                  const Text('Staff Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Select a staff member to view their resources'),
                  const SizedBox(height: 8),
                  if (_staffError != null)
                    _ErrorState(message: _staffError!, onRetry: _loadStaff)
                  else if (_staff.isEmpty)
                    const _EmptyState('No staff members available.')
                  else
                    ..._staff.map((staff) => Card(
                          child: ListTile(
                            onTap: () => _openHistory(staff),
                            leading: _StaffAvatar(url: staff.imageUrl),
                            title: Text(staff.name.isEmpty ? 'Unnamed staff' : staff.name),
                            subtitle: Text(staff.employeeId.isEmpty ? 'Staff ID unavailable' : 'Staff ID: ${staff.employeeId}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 17),
                          ),
                        )),
                  const SizedBox(height: 22),
                  const Text('All Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_resourcesLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_resourcesError != null)
                    _ErrorState(message: _resourcesError!, onRetry: _loadResources)
                  else if (_resources.isEmpty)
                    const _EmptyState('No staff resources available.')
                  else
                    ..._resources.map((resource) => _ResourceCard(resource: resource, onEdit: () => _openForm(resource), onDelete: () => _delete(resource))),
                ],
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
          if (index == 3) Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          if (index == 4) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        },
      ),
    );
  }

  void _openHistory(StaffInfo staff) => Navigator.of(context).pushNamed(
        AppRoutes.adminOtherStaffResourceHistory,
        arguments: staff,
      );
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url.trim();
    if (imageUrl.isEmpty) return const CircleAvatar(child: Icon(Icons.person_outline));
    return CircleAvatar(
      backgroundImage: NetworkImage(imageUrl),
      child: const SizedBox.shrink(),
      onBackgroundImageError: (_, error) {},
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
}

class StaffResourceForm extends StatefulWidget {
  const StaffResourceForm({super.key, required this.staff, required this.onSave, this.resource});
  final List<StaffInfo> staff;
  final StaffResource? resource;
  final Future<void> Function(StaffResource value) onSave;

  @override
  State<StaffResourceForm> createState() => _StaffResourceFormState();
}

class _StaffResourceFormState extends State<StaffResourceForm> {
  final _formKey = GlobalKey<FormState>();
  late StaffInfo? _selectedStaff;
  late final TextEditingController _description;
  late final TextEditingController _link;
  late final TextEditingController _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStaff = widget.staff.where((staff) => staff.employeeId == widget.resource?.staffId).firstOrNull ?? (widget.staff.isEmpty ? null : widget.staff.first);
    _description = TextEditingController(text: widget.resource?.description);
    _link = TextEditingController(text: widget.resource?.link);
    _image = TextEditingController(text: widget.resource?.slipReportImageUrl);
    _image.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    _link.dispose();
    _image.dispose();
    super.dispose();
  }

  bool _validUrlOrPath(String value) {
    if (value.isEmpty) return true;
    final uri = Uri.tryParse(value);
    return (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) || value.startsWith('/');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedStaff == null || _saving) return;
    setState(() => _saving = true);
    try {
      final staff = _selectedStaff!;
      await widget.onSave(StaffResource(
        id: widget.resource?.id,
        staffId: staff.employeeId,
        staffName: staff.name,
        description: _description.text.trim(),
        link: _link.text.trim(),
        slipReportImageUrl: _image.text.trim(),
        createdAt: widget.resource?.createdAt,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedStaff = widget.staff.isEmpty ? null : widget.staff.first;
      _description.clear();
      _link.clear();
      _image.clear();
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.resource == null ? 'Add Staff Resource' : 'Edit Staff Resource'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StaffInfo>(
                    initialValue: _selectedStaff,
                    decoration: const InputDecoration(labelText: 'Staff Name'),
                    items: widget.staff.map((staff) => DropdownMenuItem(value: staff, child: Text('${staff.name} - ${staff.employeeId}'))).toList(),
                    onChanged: _saving ? null : (value) => setState(() => _selectedStaff = value),
                    validator: (value) => value == null ? 'Select a staff member.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _description, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (value) => value == null || value.trim().isEmpty ? 'Description is required.' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _link, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Links (Optional)', hintText: 'https://example.com', border: OutlineInputBorder()), validator: (value) => _validUrlOrPath(value?.trim() ?? '') ? null : 'Enter a valid URL.'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _image, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Upload Slip Report Image URL (Optional)', border: OutlineInputBorder()), validator: (value) => _validUrlOrPath(value?.trim() ?? '') ? null : 'Enter a valid image URL or path.'),
                  if (_image.text.trim().startsWith('http')) ...[
                    const SizedBox(height: 10),
                    SizedBox(height: 120, child: Image.network(_image.text.trim(), fit: BoxFit.contain, errorBuilder: (_, error, stack) => const Center(child: Text('Image preview unavailable.')))),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : _reset, child: const Text('Reset')),
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.resource == null ? 'Save' : 'Update')),
        ],
      );
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onEdit, required this.onDelete});
  final StaffResource resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(resource.staffName, style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red))]),
            Text(resource.description),
            if (resource.link.isNotEmpty) TextButton.icon(onPressed: () => launchUrl(Uri.parse(resource.link), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const Text('Open resource')),
            if (resource.slipReportImageUrl.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(height: 90, child: Image.network(resource.slipReportImageUrl, fit: BoxFit.contain, errorBuilder: (_, error, stack) => const Text('Image unavailable.')))),
            const SizedBox(height: 6),
            Text(_formatDate(resource.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

String _formatDate(String? value) {
  final date = value == null ? null : DateTime.tryParse(value)?.toLocal();
  if (date == null) return 'Date unavailable';
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(message)));
}
