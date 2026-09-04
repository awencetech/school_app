class BusGps {
  const BusGps({
    this.id,
    required this.busRouteCode,
    required this.busRouteStatus,
    required this.year,
    required this.busRouteDescription,
    required this.busRouteDriver,
    required this.busNo,
    required this.hasGpsDevice,
    this.gpsStatus = 'Offline',
    this.engineStatus = 'OFF',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String busRouteCode;
  final String busRouteStatus;
  final String year;
  final String busRouteDescription;
  final String busRouteDriver;
  final String busNo;
  final String hasGpsDevice;
  final String gpsStatus;
  final String engineStatus;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BusGps.fromJson(Map<String, dynamic> json) => BusGps(
    id: json['id']?.toString() ?? json['_id']?.toString(),
    busRouteCode: json['busRouteCode']?.toString() ?? '',
    busRouteStatus: json['busRouteStatus']?.toString() ?? 'Active',
    year: json['year']?.toString() ?? '',
    busRouteDescription: json['busRouteDescription']?.toString() ?? '',
    busRouteDriver: json['busRouteDriver']?.toString() ?? '',
    busNo: json['busNo']?.toString() ?? '',
    hasGpsDevice: json['hasGpsDevice']?.toString() ?? 'No',
    gpsStatus: json['gpsStatus']?.toString() ?? 'Offline',
    engineStatus: json['engineStatus']?.toString() ?? 'OFF',
    isActive: json['isActive'] is bool
        ? json['isActive'] as bool
        : (json['busRouteStatus']?.toString().toLowerCase() != 'inactive'),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() => {
    'busRouteCode': busRouteCode,
    'busRouteStatus': busRouteStatus,
    'year': year,
    'busRouteDescription': busRouteDescription,
    'busRouteDriver': busRouteDriver,
    'busNo': busNo,
    'hasGpsDevice': hasGpsDevice,
    'gpsStatus': gpsStatus,
    'engineStatus': engineStatus,
    'isActive': isActive,
  };
}
