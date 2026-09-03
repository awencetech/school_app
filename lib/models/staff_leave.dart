class StaffLeaveRequest {
  const StaffLeaveRequest({this.id, required this.leaveType, required this.year, required this.startDate, required this.endDate, required this.beginHalfDay, required this.endHalfDay, required this.effectiveDays, required this.reason, required this.status, this.createdAt});
  final String? id;
  final String leaveType;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final bool beginHalfDay;
  final bool endHalfDay;
  final double effectiveDays;
  final String reason;
  final String status;
  final DateTime? createdAt;

  factory StaffLeaveRequest.fromJson(Map<String, dynamic> json) => StaffLeaveRequest(
    id: json['id']?.toString() ?? json['_id']?.toString(), leaveType: json['leaveType']?.toString() ?? '', year: int.tryParse(json['applicableYear'].toString()) ?? 0,
    startDate: DateTime.tryParse(json['startDate'].toString()) ?? DateTime(1970), endDate: DateTime.tryParse(json['endDate'].toString()) ?? DateTime(1970),
    beginHalfDay: json['beginHalfDay'] == true, endHalfDay: json['endHalfDay'] == true, effectiveDays: double.tryParse(json['effectiveDays'].toString()) ?? 0,
    reason: json['reason']?.toString() ?? '', status: json['status']?.toString() ?? 'Pending', createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class StaffLeaveEntitlement {
  const StaffLeaveEntitlement({required this.leaveType, required this.year, required this.totalLeaves, required this.adjustment, required this.leaveTaken});
  final String leaveType;
  final int year;
  final double totalLeaves;
  final double adjustment;
  final double leaveTaken;
  factory StaffLeaveEntitlement.fromJson(Map<String, dynamic> json) => StaffLeaveEntitlement(leaveType: json['leaveType']?.toString() ?? '', year: int.tryParse(json['year'].toString()) ?? 0, totalLeaves: double.tryParse(json['totalLeaves'].toString()) ?? 0, adjustment: double.tryParse(json['adjustment'].toString()) ?? 0, leaveTaken: double.tryParse(json['leaveTaken'].toString()) ?? 0);
}
