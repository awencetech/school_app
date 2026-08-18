/// Model for a student/activity group in the school.
class Group {
  final String databaseId;
  final String id;
  final String name;
  final String code;
  final String description;
  final String type;
  final String status;
  final String year;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Group({
    this.databaseId = '',
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    this.type = 'Other',
    this.status = 'Active',
    this.year = '2022',
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['groupId'] ?? '').toString();
    final description = (json['description'] ?? json['code'] ?? '').toString();
    final code = (json['code'] ?? description).toString();
    final databaseId = (json['_id'] ?? json['databaseId'] ?? '').toString();
    final orderValue = json['order'];

    return Group(
      databaseId: databaseId,
      id: rawId,
      name: (json['name'] ?? '').toString(),
      code: code,
      description: description,
      type: (json['type'] ?? 'Other').toString(),
      status: (json['status'] ?? 'Active').toString(),
      year: (json['year'] ?? '2022').toString(),
      order: orderValue is int ? orderValue : int.tryParse(orderValue?.toString() ?? '') ?? 0,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (databaseId.isNotEmpty) '_id': databaseId,
      'id': id,
      'name': name,
      'code': code.isNotEmpty ? code : description,
      'description': description.isNotEmpty ? description : code,
      'type': type,
      'status': status,
      'year': year,
      'order': order,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
