/// Management member item used in the School Content Management System.
class ManagementMember {
  ManagementMember({
    this.id = '',
    required this.photoBase64,
    required this.name,
    required this.designation,
    required this.title,
    required this.description,
  });

  final String id;
  final String photoBase64;
  final String name;
  final String designation;
  final String title;
  final String description;

  factory ManagementMember.fromJson(Map<String, dynamic> json) {
    return ManagementMember(
      id: json['id'] as String? ?? '',
      photoBase64: json['photoBase64'] as String? ?? json['photo'] as String? ?? '',
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoBase64': photoBase64,
      'photo': photoBase64,
      'name': name,
      'designation': designation,
      'title': title,
      'description': description,
    };
  }
}
