import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentFullDetailsPage extends StatelessWidget {
  const StudentFullDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final student = _demoStudent();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        elevation: 0,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: Text(
          'Student Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(student),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Personal Information',
                children: [
                  _buildFieldRow('Student Name', student.name),
                  _buildFieldRow('Student ID', student.studentId),
                  _buildFieldRow('Admission Number', student.admissionNo),
                  _buildFieldRow('Date of Joining', student.dateOfJoining),
                  _buildFieldRow('Gender', student.gender),
                  _buildFieldRow('Date of Birth', student.dateOfBirth),
                  _buildFieldRow('Blood Group', student.bloodGroup),
                  _buildFieldRow('Nationality', student.nationality),
                  _buildFieldRow('Mother Tongue', student.motherTongue),
                  _buildFieldRow('Religion', student.religion),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Contact Information',
                children: [
                  _buildFieldRow('Mobile Number', student.mobile),
                  _buildFieldRow('Email Address', student.email),
                  _buildFieldRow('Address', student.address),
                  _buildFieldRow('City', student.city),
                  _buildFieldRow('District', student.district),
                  _buildFieldRow('State', student.state),
                  _buildFieldRow('Pincode', student.pincode),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Government Information',
                children: [
                  _buildFieldRow('Aadhaar Number', student.aadhaarNumber),
                  _buildFieldRow('EMIS Number', student.emisNumber),
                  _buildFieldRow('Other ID', student.otherId),
                  _buildFieldRow('Transport ID', student.transportId),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Medical Information',
                children: [
                  _buildFieldRow('Special Needs', student.specialNeeds),
                  _buildFieldRow('Allergy Details', student.allergyDetails),
                  _buildFieldRow('Medical Notes', student.medicalNotes),
                  _buildFieldRow('Medical Status', student.medicalStatus),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Transport Details',
                children: [
                  _buildFieldRow('Mode of Transport', student.transportMode),
                  _buildFieldRow('Bus Number', student.busNumber),
                  _buildFieldRow('Pickup Point', student.pickupPoint),
                  _buildFieldRow('Drop Point', student.dropPoint),
                  _buildFieldRow('Driver Name', student.driverName),
                  _buildFieldRow('Driver Contact', student.driverContact),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Parent Details',
                children: [
                  _buildFieldRow('Father Name', student.fatherName),
                  _buildFieldRow('Mother Name', student.motherName),
                  _buildFieldRow('Guardian Name', student.guardianName),
                  _buildFieldRow('Parent Mobile', student.parentMobile),
                  _buildFieldRow('Parent Email', student.parentEmail),
                  _buildFieldRow('Occupation', student.occupation),
                  _buildFieldRow('Parent Employee', student.parentEmployee),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Academic Details',
                children: [
                  _buildFieldRow('Current Class', student.currentClass),
                  _buildFieldRow('Previous Class', student.previousClass),
                  _buildFieldRow('Admission Date', student.admissionDate),
                  _buildFieldRow('Student Status', student.studentStatus),
                  _buildFieldRow('Roll Number', student.rollNumber),
                  _buildFieldRow('House', student.house),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Sibling Information',
                children: student.siblings.map((sibling) => _buildFieldRow('${sibling.name} (${sibling.className})', sibling.studentId)).toList(),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Location',
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE8F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB8D0EA)),
                    ),
                    child: const Center(
                      child: Text(
                        'Google Map Placeholder',
                        style: TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldRow('Last Updated', student.lastUpdated),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildProfileCard(_DemoStudent student) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF2F3352)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2F3352))),
                  const SizedBox(height: 6),
                  _buildInfoText('Student ID', student.studentId),
                  _buildInfoText('Admission No', student.admissionNo),
                  _buildInfoText('Status', student.studentStatus),
                  _buildInfoText('Class', student.currentClass),
                  _buildInfoText('Section', student.section),
                  _buildInfoText('Academic Year', student.academicYear),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2F3352)),
            ),
            const SizedBox(height: 12),
            ...children.expand((child) => [child, const SizedBox(height: 8)]).toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280))),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Text(
      '$label: $value',
      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
    );
  }

  _DemoStudent _demoStudent() {
    return _DemoStudent(
      name: 'MOHAMED AZEEMSHA A',
      studentId: 'S1746',
      admissionNo: '1746',
      dateOfJoining: '01-06-2023',
      gender: 'Male',
      dateOfBirth: '15-08-2012',
      bloodGroup: 'O+',
      nationality: 'Indian',
      motherTongue: 'Tamil',
      religion: 'Islam',
      mobile: '9578647982',
      email: 'student@example.com',
      address: 'Plot No 12, Main Road',
      city: 'Chennai',
      district: 'Chennai',
      state: 'Tamil Nadu',
      pincode: '600001',
      aadhaarNumber: 'XXXX-XXXX-1234',
      emisNumber: 'EMIS-1746',
      otherId: 'ID-987',
      transportId: 'TR-1002',
      specialNeeds: 'Yes',
      allergyDetails: 'No Known Allergies',
      medicalNotes: 'Routine checkup done',
      medicalStatus: 'Healthy',
      transportMode: 'School Bus',
      busNumber: 'TN-09-AB-1234',
      pickupPoint: 'Main Gate',
      dropPoint: 'Home Pickup',
      driverName: 'Mr. Kumar',
      driverContact: '9876543210',
      fatherName: 'Ajumunisha',
      motherName: 'Asha',
      guardianName: 'Ajumunisha',
      parentMobile: '9876543210',
      parentEmail: 'parent@example.com',
      occupation: 'Teacher',
      parentEmployee: 'Yes',
      currentClass: 'Grade 10',
      previousClass: 'Grade 9',
      admissionDate: '01-06-2023',
      studentStatus: 'Active',
      rollNumber: '14',
      house: 'Green',
      section: 'A',
      academicYear: '2026-2027',
      lastUpdated: 'Aug 07, 2026',
      siblings: [
        _DemoSibling(name: 'Aisha', className: 'Grade 7', studentId: 'S1201'),
        _DemoSibling(name: 'Mohan', className: 'Grade 5', studentId: 'S1102'),
      ],
    );
  }
}

class _DemoStudent {
  _DemoStudent({
    required this.name,
    required this.studentId,
    required this.admissionNo,
    required this.dateOfJoining,
    required this.gender,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.nationality,
    required this.motherTongue,
    required this.religion,
    required this.mobile,
    required this.email,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.aadhaarNumber,
    required this.emisNumber,
    required this.otherId,
    required this.transportId,
    required this.specialNeeds,
    required this.allergyDetails,
    required this.medicalNotes,
    required this.medicalStatus,
    required this.transportMode,
    required this.busNumber,
    required this.pickupPoint,
    required this.dropPoint,
    required this.driverName,
    required this.driverContact,
    required this.fatherName,
    required this.motherName,
    required this.guardianName,
    required this.parentMobile,
    required this.parentEmail,
    required this.occupation,
    required this.parentEmployee,
    required this.currentClass,
    required this.previousClass,
    required this.admissionDate,
    required this.studentStatus,
    required this.rollNumber,
    required this.house,
    required this.section,
    required this.academicYear,
    required this.lastUpdated,
    required this.siblings,
  });

  final String name;
  final String studentId;
  final String admissionNo;
  final String dateOfJoining;
  final String gender;
  final String dateOfBirth;
  final String bloodGroup;
  final String nationality;
  final String motherTongue;
  final String religion;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String aadhaarNumber;
  final String emisNumber;
  final String otherId;
  final String transportId;
  final String specialNeeds;
  final String allergyDetails;
  final String medicalNotes;
  final String medicalStatus;
  final String transportMode;
  final String busNumber;
  final String pickupPoint;
  final String dropPoint;
  final String driverName;
  final String driverContact;
  final String fatherName;
  final String motherName;
  final String guardianName;
  final String parentMobile;
  final String parentEmail;
  final String occupation;
  final String parentEmployee;
  final String currentClass;
  final String previousClass;
  final String admissionDate;
  final String studentStatus;
  final String rollNumber;
  final String house;
  final String section;
  final String academicYear;
  final String lastUpdated;
  final List<_DemoSibling> siblings;
}

class _DemoSibling {
  _DemoSibling({required this.name, required this.className, required this.studentId});

  final String name;
  final String className;
  final String studentId;
}
