import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final GroupService _groupService = GroupService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _selectedStatus = 'Active';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showForm = false;
  bool _isEditing = false;
  String? _editingGroupId;
  String? _errorMessage;
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups({bool refresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final groups = await _groupService.getGroups(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _groups = groups..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ApiException ? error.message : 'Unable to load groups.';
      });
    }
  }

  Future<void> _saveGroup() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final id = _idController.text.trim();
      final type = _typeController.text.trim();
      final description = _descriptionController.text.trim();
      final year = _yearController.text.trim();

      final duplicateExists = _groups.any((group) {
        final sameId = group.id.toLowerCase() == id.toLowerCase();
        if (!_isEditing) return sameId;
        final sameDocument = group.databaseId.isNotEmpty && _editingGroupId != null && group.databaseId == _editingGroupId;
        return !sameDocument && sameId;
      });

      if (duplicateExists) {
        throw ApiException(409, 'Group ID already exists', 'form');
      }

      if (_isEditing && (_editingGroupId ?? '').isNotEmpty) {
        await _groupService.updateGroup(
          _editingGroupId!,
          name: name,
          id: id,
          type: type,
          description: description,
          status: _selectedStatus,
          year: year,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      } else {
        await _groupService.createGroup(
          name: name,
          id: id,
          type: type,
          description: description,
          status: _selectedStatus,
          year: year,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
      }

      await _loadGroups(refresh: true);
      _resetForm();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to save group. Please try again.';
      });
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final databaseId = group.databaseId.isNotEmpty ? group.databaseId : group.id;
    setState(() => _isLoading = true);
    try {
      await _groupService.deleteGroup(databaseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully')),
      );
      await _loadGroups(refresh: true);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ApiException ? error.message : 'Unable to delete group.';
      });
    }
  }

  void _prepareEdit(Group group) {
    setState(() {
      _showForm = true;
      _isEditing = true;
      _editingGroupId = group.databaseId.isNotEmpty ? group.databaseId : group.id;
      _selectedStatus = group.status.isNotEmpty ? group.status : 'Active';
      _nameController.text = group.name;
      _idController.text = group.id;
      _typeController.text = group.type;
      _descriptionController.text = group.description.isNotEmpty ? group.description : group.code;
      _yearController.text = group.year;
      _errorMessage = null;
    });
  }

  void _resetForm() {
    _nameController.clear();
    _idController.clear();
    _typeController.clear();
    _descriptionController.clear();
    _yearController.clear();
    _selectedStatus = 'Active';
    _showForm = false;
    _isEditing = false;
    _editingGroupId = null;
    _isSaving = false;
    _errorMessage = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: const Text('Create Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showForm = !_showForm;
                      if (!_showForm) _resetForm();
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('+ Add Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_showForm) ...[
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Group' : 'Create Group',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Name',
                          controller: _nameController,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'ID',
                          controller: _idController,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'ID is required';
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'Type',
                          controller: _typeController,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Type is required';
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'Description',
                          controller: _descriptionController,
                          maxLines: 2,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Description is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Not Active', child: Text('Not Active')),
                          ],
                          onChanged: (value) => setState(() => _selectedStatus = value ?? 'Active'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Year',
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) return 'Year is required';
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueButton,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _isEditing ? 'Save Changes' : 'Save Group',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_groups.isEmpty)
                Center(
                  child: Text(
                    'No groups available yet.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                )
              else
                ...List.generate(_groups.length, (index) {
                  final group = _groups[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${group.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blueButton,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('ID: ${group.id}', style: GoogleFonts.poppins(fontSize: 12)),
                        Text('Type: ${group.type}', style: GoogleFonts.poppins(fontSize: 12)),
                        Text('Status: ${group.status}', style: GoogleFonts.poppins(fontSize: 12)),
                        Text('Year: ${group.year}', style: GoogleFonts.poppins(fontSize: 12)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _prepareEdit(group),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteGroup(group),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {},
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
