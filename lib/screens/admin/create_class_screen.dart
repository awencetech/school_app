import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../services/class_service.dart';
import '../../services/group_service.dart' show ApiException;
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class CreateClassesScreen extends StatefulWidget {
  const CreateClassesScreen({super.key});

  @override
  State<CreateClassesScreen> createState() => _CreateClassesScreenState();
}

class _CreateClassesScreenState extends State<CreateClassesScreen> {
  final ClassService _classService = ClassService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _selectedStatus = 'Active';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showForm = false;
  bool _isEditing = false;
  String? _editingClassId;
  String? _errorMessage;
  List<Group> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses(refresh: true);
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

  void _resetForm() {
    _nameController.clear();
    _idController.clear();
    _typeController.clear();
    _descriptionController.clear();
    _yearController.clear();
    _selectedStatus = 'Active';
    _showForm = false;
    _isEditing = false;
    _editingClassId = null;
    _isSaving = false;
    _errorMessage = null;
    setState(() {});
  }

  Future<void> _loadClasses({bool refresh = false}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final classes = await _classService.getClasses(refresh: refresh);
      if (!mounted) return;
      final classRecords = classes
          .where((group) => group.type.trim().toLowerCase() == 'class')
          .toList();
      if (kDebugMode) {
        debugPrint(
          'CreateClassesScreen -> records=${classes.length}, classes=${classRecords.length}',
        );
      }
      setState(() {
        _classes = classRecords
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'Unable to load classes.';
      });
    }
  }

  Future<void> _saveClass() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
      final duplicateExists = _classes.any((group) {
        final sameId = group.id.toLowerCase() == id.toLowerCase();
        final sameGroup =
            group.databaseId.isNotEmpty && group.databaseId == _editingClassId;
        return sameId && (!sameGroup || !_isEditing);
      });
      if (duplicateExists) {
        throw ApiException(409, 'Class ID already exists.', 'form');
      }

      if (_isEditing && (_editingClassId ?? '').isNotEmpty) {
        await _classService.updateClass(
          _editingClassId!,
          name: name,
          id: id,
          type: type,
          description: description,
          status: _selectedStatus,
          year: year,
        );
      } else {
        await _classService.createClass(
          name: name,
          id: id,
          type: type,
          description: description,
          status: _selectedStatus,
          year: year,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Class updated successfully'
                : 'Class created successfully',
          ),
        ),
      );
      await _loadClasses(refresh: true);
      if (mounted) _resetForm();
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Unable to save class. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _prepareEdit(Group group) {
    setState(() {
      _showForm = true;
      _isEditing = true;
      _editingClassId = group.databaseId.isNotEmpty
          ? group.databaseId
          : group.id;
      _selectedStatus = group.status.isNotEmpty ? group.status : 'Active';
      _nameController.text = group.name;
      _idController.text = group.id;
      _typeController.text = group.type;
      _descriptionController.text = group.description.isNotEmpty
          ? group.description
          : group.code;
      _yearController.text = group.year;
      _errorMessage = null;
    });
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text('Are you sure you want to delete this class?'),
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _classService.deleteClass(
        group.databaseId.isNotEmpty ? group.databaseId : group.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted successfully')),
      );
      await _loadClasses(refresh: true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Unable to delete class.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: const Text('Create Classes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => navigateBack(context),
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
                  label: const Text('+ Add Class'),
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
                          _isEditing ? 'Edit Class' : 'Create Class',
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
                            if ((value ?? '').trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'ID',
                          controller: _idController,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'ID is required';
                            }
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'Type',
                          controller: _typeController,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Type is required';
                            }
                            return null;
                          },
                        ),
                        _buildField(
                          label: 'Description',
                          controller: _descriptionController,
                          maxLines: 2,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Description is required';
                            }
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
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Not Active',
                              child: Text('Not Active'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _selectedStatus = value ?? 'Active',
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Year',
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Year is required';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveClass,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'Update Class' : 'Save Class',
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
              else if (_errorMessage != null && _classes.isEmpty)
                Column(
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => _loadClasses(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_classes.isEmpty)
                const Center(child: Text('No classes available'))
              else
                ...List.generate(_classes.length, (index) {
                  final item = _classes[index];
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
                          '${index + 1}. ${item.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blueButton,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: ${item.id}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        Text(
                          'Type: ${item.type}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        Text(
                          'Description: ${item.description}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        Text(
                          'Status: ${item.status}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        Text(
                          'Year: ${item.year}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _prepareEdit(item),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _deleteGroup(item),
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
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
