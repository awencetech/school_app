import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../models/management_member.dart';
import '../../services/school_config_service.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class SchoolContentManagementScreen extends StatefulWidget {
  const SchoolContentManagementScreen({super.key});

  @override
  State<SchoolContentManagementScreen> createState() => _SchoolContentManagementScreenState();
}

class _SchoolContentManagementScreenState extends State<SchoolContentManagementScreen> {
  final TextEditingController _founderNameController = TextEditingController();
  final TextEditingController _founderDesignationController = TextEditingController();
  final TextEditingController _founderVisionTitleController = TextEditingController();
  final TextEditingController _founderVisionDescriptionController = TextEditingController();
  final TextEditingController _secretaryNameController = TextEditingController();
  final TextEditingController _secretaryDesignationController = TextEditingController();
  final TextEditingController _secretaryWelcomeTitleController = TextEditingController();
  final TextEditingController _secretaryWelcomeMessageController = TextEditingController();
  final TextEditingController _headmasterNameController = TextEditingController();
  final TextEditingController _headmasterDesignationController = TextEditingController();
  final TextEditingController _headmasterMessageTitleController = TextEditingController();
  final TextEditingController _headmasterMessageController = TextEditingController();

  late final SchoolConfigService _config;
  String? _founderPhotoBase64;
  String? _secretaryPhotoBase64;
  String? _headmasterPhotoBase64;
  List<ManagementMember> _managementMembers = [];
  bool _hasUserEdited = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _config = context.read<SchoolConfigService>();
    _syncControllersFromConfig();
    _config.addListener(_syncControllersFromConfig);
    _addUserEditListeners();
  }

  @override
  void dispose() {
    _config.removeListener(_syncControllersFromConfig);
    _founderNameController.dispose();
    _founderDesignationController.dispose();
    _founderVisionTitleController.dispose();
    _founderVisionDescriptionController.dispose();
    _secretaryNameController.dispose();
    _secretaryDesignationController.dispose();
    _secretaryWelcomeTitleController.dispose();
    _secretaryWelcomeMessageController.dispose();
    _headmasterNameController.dispose();
    _headmasterDesignationController.dispose();
    _headmasterMessageTitleController.dispose();
    _headmasterMessageController.dispose();
    super.dispose();
  }

  void _addUserEditListeners() {
    for (final controller in [
      _founderNameController,
      _founderDesignationController,
      _founderVisionTitleController,
      _founderVisionDescriptionController,
      _secretaryNameController,
      _secretaryDesignationController,
      _secretaryWelcomeTitleController,
      _secretaryWelcomeMessageController,
      _headmasterNameController,
      _headmasterDesignationController,
      _headmasterMessageTitleController,
      _headmasterMessageController,
    ]) {
      controller.addListener(() {
        if (!_isSyncing) {
          _hasUserEdited = true;
        }
      });
    }
  }

  void _syncControllersFromConfig() {
    if (!mounted || _hasUserEdited) return;
    _isSyncing = true;
    _founderNameController.text = _config.founderName;
    _founderDesignationController.text = _config.founderDesignation;
    _founderVisionTitleController.text = _config.founderVisionTitle;
    _founderVisionDescriptionController.text = _config.founderVisionDescription;
    _secretaryNameController.text = _config.secretaryName;
    _secretaryDesignationController.text = _config.secretaryDesignation;
    _secretaryWelcomeTitleController.text = _config.secretaryWelcomeTitle;
    _secretaryWelcomeMessageController.text = _config.secretaryWelcomeMessage;
    _headmasterNameController.text = _config.headmasterName;
    _headmasterDesignationController.text = _config.headmasterDesignation;
    _headmasterMessageTitleController.text = _config.headmasterMessageTitle;
    _headmasterMessageController.text = _config.headmasterMessage;
    _founderPhotoBase64 = _config.founderPhotoBase64;
    _secretaryPhotoBase64 = _config.secretaryPhotoBase64;
    _headmasterPhotoBase64 = _config.headmasterPhotoBase64;
    _managementMembers = List<ManagementMember>.from(_config.managementMembers);
    _isSyncing = false;
    setState(() {});
  }

  Future<void> _pickImage(void Function(String?) updater) async {
    final result = await FilePicker.pickFiles(withData: true, type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    updater(base64Encode(bytes));
  }

  Future<void> _selectFounderPhoto() async {
    await _pickImage((base64) {
      setState(() {
        _founderPhotoBase64 = base64;
        _hasUserEdited = true;
      });
    });
  }

  Future<void> _selectSecretaryPhoto() async {
    await _pickImage((base64) {
      setState(() {
        _secretaryPhotoBase64 = base64;
        _hasUserEdited = true;
      });
    });
  }

  Future<void> _selectHeadmasterPhoto() async {
    await _pickImage((base64) {
      setState(() {
        _headmasterPhotoBase64 = base64;
        _hasUserEdited = true;
      });
    });
  }

  Future<void> _showMemberDialog({ManagementMember? member, int? index}) async {
    final nameController = TextEditingController(text: member?.name ?? '');
    final designationController = TextEditingController(text: member?.designation ?? '');
    final titleController = TextEditingController(text: member?.title ?? '');
    final descriptionController = TextEditingController(text: member?.description ?? '');
    String? memberPhotoBase64 = member?.photoBase64;
    bool memberEdited = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(index == null ? 'Add Member' : 'Edit Member'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await _pickImage((base64) {
                        setState(() {
                          memberPhotoBase64 = base64;
                          memberEdited = true;
                        });
                      });
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text(memberPhotoBase64 == null ? 'Upload Photo' : 'Replace Photo'),
                  ),
                  const SizedBox(height: 12),
                  if (memberPhotoBase64 != null)
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(memberPhotoBase64!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('No Photo Selected')),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: designationController,
                    decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedMember = ManagementMember(
                    photoBase64: memberPhotoBase64 ?? '',
                    name: nameController.text.trim(),
                    designation: designationController.text.trim(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                  setState(() {
                    memberEdited = true;
                  });
                  if (index == null) {
                    _managementMembers.add(updatedMember);
                  } else {
                    _managementMembers[index] = updatedMember;
                  }
                  _hasUserEdited = true;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (memberEdited) {
      setState(() {});
    }
  }

  void _removeMember(int index) {
    setState(() {
      _managementMembers.removeAt(index);
      _hasUserEdited = true;
    });
  }

  void _reorderMembers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _managementMembers.removeAt(oldIndex);
      _managementMembers.insert(newIndex, item);
      _hasUserEdited = true;
    });
  }

  Future<void> _saveContent() async {
    final founderVisionText = _founderVisionDescriptionController.text.trim();
    final secretaryVisionText = _secretaryWelcomeMessageController.text.trim();
    final headmasterVisionText = _headmasterMessageController.text.trim();

    final config = context.read<SchoolConfigService>();
    await config.save(
      founderPhotoBase64: _founderPhotoBase64,
      founderName: _founderNameController.text.trim(),
      founderDesignation: _founderDesignationController.text.trim(),
      founderVisionTitle: _founderVisionTitleController.text.trim(),
      founderVisionDescription: founderVisionText,
      secretaryPhotoBase64: _secretaryPhotoBase64,
      secretaryName: _secretaryNameController.text.trim(),
      secretaryDesignation: _secretaryDesignationController.text.trim(),
      secretaryWelcomeTitle: _secretaryWelcomeTitleController.text.trim(),
      secretaryWelcomeMessage: secretaryVisionText,
      headmasterPhotoBase64: _headmasterPhotoBase64,
      headmasterName: _headmasterNameController.text.trim(),
      headmasterDesignation: _headmasterDesignationController.text.trim(),
      headmasterMessageTitle: _headmasterMessageTitleController.text.trim(),
      headmasterMessage: headmasterVisionText,
      managementMembers: _managementMembers,
    );

    if (!mounted) return;
    setState(() {
      _hasUserEdited = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School content saved successfully.')),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildImageCard(String title, String? base64, VoidCallback onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: base64 != null
                      ? Image.memory(base64Decode(base64), fit: BoxFit.contain)
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Text('No image selected')),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file),
                    label: Text(base64 == null ? 'Upload Image' : 'Replace Image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('School Content Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeading('Founder Details'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCard('Founder Photo', _founderPhotoBase64, _selectFounderPhoto),
                    const SizedBox(height: 16),
                    _buildTextField(_founderNameController, 'Founder Name'),
                    const SizedBox(height: 12),
                    _buildTextField(_founderDesignationController, 'Designation'),
                    const SizedBox(height: 12),
                    _buildTextField(_founderVisionTitleController, 'Vision Title'),
                    const SizedBox(height: 12),
                    _buildTextField(_founderVisionDescriptionController, 'Vision Description', maxLines: 3),
                  ],
                ),
              ),
            ),
            _buildSectionHeading('Secretary Details'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCard('Secretary Photo', _secretaryPhotoBase64, _selectSecretaryPhoto),
                    const SizedBox(height: 16),
                    _buildTextField(_secretaryNameController, 'Secretary Name'),
                    const SizedBox(height: 12),
                    _buildTextField(_secretaryDesignationController, 'Designation'),
                    const SizedBox(height: 12),
                    _buildTextField(_secretaryWelcomeTitleController, 'Vision Title'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _secretaryWelcomeMessageController,
                      'Vision Description (20-100 words)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeading('Headmaster Details'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCard('Headmaster Photo', _headmasterPhotoBase64, _selectHeadmasterPhoto),
                    const SizedBox(height: 16),
                    _buildTextField(_headmasterNameController, 'Headmaster Name'),
                    const SizedBox(height: 12),
                    _buildTextField(_headmasterDesignationController, 'Designation'),
                    const SizedBox(height: 12),
                    _buildTextField(_headmasterMessageTitleController, 'Vision Title'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _headmasterMessageController,
                      'Vision Description (20-100 words)',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeading('Management Members'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showMemberDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Member'),
                    ),
                    const SizedBox(height: 16),
                    _managementMembers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('No management members added yet.')),
                          )
                        : ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _managementMembers.length,
                            onReorderItem: _reorderMembers,
                            itemBuilder: (context, index) {
                              final member = _managementMembers[index];
                              return ListTile(
                                key: ValueKey(member.hashCode ^ index),
                                leading: CircleAvatar(
                                  backgroundImage: member.photoBase64.isNotEmpty
                                      ? MemoryImage(base64Decode(member.photoBase64))
                                      : null,
                                  child: member.photoBase64.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                title: Text(member.name.isNotEmpty ? member.name : 'Unnamed Member'),
                                subtitle: Text(member.designation.isNotEmpty
                                    ? '${member.designation} · ${member.title}'
                                    : member.title.isNotEmpty
                                        ? member.title
                                        : 'No designation/title'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showMemberDialog(member: member, index: index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeMember(index),
                                    ),
                                    const Icon(Icons.drag_handle),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveContent,
              icon: const Icon(Icons.save),
              label: const Text('Save Content'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
