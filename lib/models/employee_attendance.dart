class EmployeeAttendance {
  const EmployeeAttendance({
    this.id,
    required this.employeeId,
    required this.teacherId,
    required this.employeeName,
    required this.attendanceDate,
    this.timeRecorded,
    this.attendanceType = 'OnSite',
    this.distance,
    this.status = 'Pending Approval',
    this.approved = false,
    this.present = true,
    this.selfAttendance = true,
    this.isLate = false,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String employeeId;
  final String teacherId;
  final String employeeName;
  final String attendanceDate;
  final DateTime? timeRecorded;
  final String attendanceType;
  final double? distance;
  final String status;
  final bool approved;
  final bool present;
  final bool selfAttendance;
  final bool isLate;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) =>
      EmployeeAttendance(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        employeeId: json['employeeId']?.toString() ?? '',
        teacherId: json['teacherId']?.toString() ?? '',
        employeeName: json['employeeName']?.toString() ?? '',
        attendanceDate: json['attendanceDate']?.toString() ?? '',
        timeRecorded: _date(json['timeRecorded']),
        attendanceType: json['attendanceType']?.toString() ?? 'OnSite',
        distance: json['distance'] is num
            ? (json['distance'] as num).toDouble()
            : double.tryParse(json['distance']?.toString() ?? ''),
        status: json['status']?.toString() ?? 'Pending Approval',
        approved: json['approved'] == true,
        present: json['present'] != false,
        selfAttendance: json['selfAttendance'] != false,
        isLate: json['isLate'] == true,
        approvedBy: json['approvedBy']?.toString(),
        approvedAt: _date(json['approvedAt']),
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'teacherId': teacherId,
    'employeeName': employeeName,
    'attendanceDate': attendanceDate,
    'timeRecorded': (timeRecorded ?? DateTime.now()).toIso8601String(),
    'attendanceType': attendanceType,
    'distance': distance,
    'status': status,
    'approved': approved,
    'present': present,
    'selfAttendance': selfAttendance,
    'isLate': isLate,
  };
}
