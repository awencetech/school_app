class GateRegister {
  const GateRegister({
    this.id,
    required this.gateNo,
    required this.personType,
    this.customGateNo = '',
    this.entryDate,
    this.status = 'Registered',
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String gateNo;
  final String customGateNo;
  final String personType;
  final DateTime? entryDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GateRegister.fromJson(Map<String, dynamic> json) => GateRegister(
    id: json['id']?.toString() ?? json['_id']?.toString(),
    gateNo: json['gateNo']?.toString() ?? '',
    customGateNo: json['customGateNo']?.toString() ?? '',
    personType: json['personType']?.toString() ?? '',
    entryDate: _date(json['entryDate']),
    status: json['status']?.toString() ?? 'Registered',
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() => {
    'gateNo': gateNo,
    'customGateNo': customGateNo,
    'personType': personType,
    'entryDate': (entryDate ?? DateTime.now()).toIso8601String(),
    'status': status,
  };
}
