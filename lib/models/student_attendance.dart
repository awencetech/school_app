class StudentAttendance {
  const StudentAttendance({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.className,
    required this.section,
    this.attendanceDate = '',
    this.subject = '',
    this.classType = '',
    this.reason = '',
    this.status = 'Pending',
    this.present = false,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String className;
  final String section;
  final String attendanceDate;
  final String subject;
  final String classType;
  final String reason;
  final String status;
  final bool present;

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      admissionNumber: json['admissionNumber']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      attendanceDate: json['attendanceDate']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      classType: json['classType']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      present: json['present'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'admissionNumber': admissionNumber,
    'className': className,
    'section': section,
    'attendanceDate': attendanceDate,
    'subject': subject,
    'classType': classType,
    'reason': reason,
    'status': status,
    'present': present,
  };
}
