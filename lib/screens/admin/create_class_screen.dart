import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class ClassItem {
  const ClassItem({
    required this.name,
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.year,
  });

  final String name;
  final String id;
  final String type;
  final String description;
  final String status;
  final String year;
}

class CreateClassesScreen extends StatefulWidget {
  const CreateClassesScreen({super.key});

  @override
  State<CreateClassesScreen> createState() => _CreateClassesScreenState();
}

class _CreateClassesScreenState extends State<CreateClassesScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _selectedStatus = 'Active';
  bool _isSaving = false;
  bool _showForm = false;
  String? _errorMessage;
  final List<ClassItem> _classes = [
    const ClassItem(
      name: 'Grade 6',
      id: 'G6',
      type: 'Class',
      description: 'Primary middle grade',
      status: 'Active',
      year: '2026',
    ),
    const ClassItem(
      name: 'Grade 7',
      id: 'G7',
      type: 'Class',
      description: 'Middle grade',
      status: 'Active',
      year: '2026',
    ),
  ];

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
    _isSaving = false;
    _errorMessage = null;
    setState(() {});
  }

  Future<void> _saveClass() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final duplicateExists = _classes.any((item) => item.id.toLowerCase() == _idController.text.trim().toLowerCase());

    if (duplicateExists) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Class ID already exists.';
      });
      return;
    }

    final addedClass = ClassItem(
      name: _nameController.text.trim(),
      id: _idController.text.trim(),
      type: _typeController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      year: _yearController.text.trim(),
    );

    setState(() {
      _classes.insert(0, addedClass);
      _isSaving = false;
      _showForm = false;
    });

    _resetForm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class created successfully')),
    );
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
                          'Create Class',
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
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Save Class',
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
