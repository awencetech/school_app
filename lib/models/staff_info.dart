class StaffInfo {
  const StaffInfo({
    this.id,
    required this.name,
    required this.designation,
    required this.employeeCategory,
    required this.employeeId,
    required this.teaches,
    required this.about,
    required this.hobbiesAndInterest,
    required this.role,
    required this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String designation;
  final String employeeCategory;
  final String employeeId;
  final String teaches;
  final String about;
  final String hobbiesAndInterest;
  final String role;
  final String imageUrl;
  final String? createdAt;
  final String? updatedAt;

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      employeeCategory: json['employeeCategory']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      teaches: json['teaches']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      hobbiesAndInterest: json['hobbiesAndInterest']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'designation': designation,
        'employeeCategory': employeeCategory,
        'employeeId': employeeId,
        'teaches': teaches,
        'about': about,
        'hobbiesAndInterest': hobbiesAndInterest,
        'role': role,
        'imageUrl': imageUrl,
      };
}
