/// Management member item used in the School Content Management System.
class ManagementMember {
  ManagementMember({
    required this.photoBase64,
    required this.name,
    required this.designation,
    required this.title,
    required this.description,
  });

  final String photoBase64;
  final String name;
  final String designation;
  final String title;
  final String description;

  factory ManagementMember.fromJson(Map<String, dynamic> json) {
    return ManagementMember(
      photoBase64: json['photoBase64'] as String? ?? '',
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoBase64': photoBase64,
      'name': name,
      'designation': designation,
      'title': title,
      'description': description,
    };
  }
}
