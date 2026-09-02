import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Model for user profile data
class UserProfileData {
  String? profilePhotoUrl;
  String fullName;
  String email;
  String phoneNumber;
  String username;
  String classRole;

  UserProfileData({
    this.profilePhotoUrl,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.username,
    required this.classRole,
  });

  UserProfileData copyWith({
    String? profilePhotoUrl,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? username,
    String? classRole,
  }) {
    return UserProfileData(
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      classRole: classRole ?? this.classRole,
    );
  }
}

class AdminUserProfilePage extends StatefulWidget {
  const AdminUserProfilePage({super.key});

  @override
  State<AdminUserProfilePage> createState() => _AdminUserProfilePageState();
}

class _AdminUserProfilePageState extends State<AdminUserProfilePage> {
  // Mock user data - initialized with default values
  late UserProfileData _profileData;
  bool _isEditing = false;

  // Form controllers for editing
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _fullNameController = TextEditingController(text: _profileData.fullName);
    _emailController = TextEditingController(text: _profileData.email);
    _phoneController = TextEditingController(text: _profileData.phoneNumber);
    _usernameController = TextEditingController(text: _profileData.username);
  }

  void _initializeMockData() {
    _profileData = UserProfileData(
      profilePhotoUrl: null,
      fullName: 'Admin User',
      email: 'admin@school.com',
      phoneNumber: '+1-800-123-4567',
      username: 'admin_user',
      classRole: 'Administrator',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // Cancel editing - reset to original values
      _fullNameController.text = _profileData.fullName;
      _emailController.text = _profileData.email;
      _phoneController.text = _profileData.phoneNumber;
      _usernameController.text = _profileData.username;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorDialog('Full Name cannot be empty');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Email cannot be empty');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorDialog('Phone Number cannot be empty');
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showErrorDialog('Username cannot be empty');
      return;
    }

    // Validate email format
    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    // Update the profile data
    setState(() {
      _profileData = _profileData.copyWith(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
      );
      _isEditing = false;
    });

    _showSuccessDialog('Profile updated successfully');
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('User Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: _profileData.profilePhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              _profileData.profilePhotoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.hintText,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement image picker
                        _showErrorDialog('Image upload feature coming soon');
                      },
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Change Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueButton,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Information Section
            if (!_isEditing)
              _buildViewMode()
            else
              _buildEditMode(),

            const SizedBox(height: 24),

            // Action Buttons
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing ? AppColors.border : AppColors.blueButton,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isEditing ? 'Cancel' : 'Edit Profile',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileField('Full Name', _profileData.fullName),
        const SizedBox(height: 16),
        _buildProfileField('Email', _profileData.email),
        const SizedBox(height: 16),
        _buildProfileField('Phone Number', _profileData.phoneNumber),
        const SizedBox(height: 16),
        _buildProfileField('Username', _profileData.username),
        const SizedBox(height: 16),
        _buildProfileField('Class / Role', _profileData.classRole),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditField('Full Name', _fullNameController),
        const SizedBox(height: 16),
        _buildEditField('Email', _emailController),
        const SizedBox(height: 16),
        _buildEditField('Phone Number', _phoneController),
        const SizedBox(height: 16),
        _buildEditField('Username', _usernameController),
        const SizedBox(height: 16),
        _buildProfileField('Class / Role', _profileData.classRole),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.hintText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.hintText),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.blueButton, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
