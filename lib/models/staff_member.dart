/// Staff profile data for the School tab.
class StaffMember {
  const StaffMember({
    required this.name,
    required this.designation,
    required this.heading,
    required this.description,
    required this.image,
    required this.imageOnLeft,
  });

  final String name;
  final String designation;
  final String heading;
  final String description;
  final String image;
  final bool imageOnLeft;

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      name: json['name'] as String? ?? '',
      designation: (json['designation'] as String?) ??
          (json['position'] as String? ?? ''),
      heading: (json['heading'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      image: (json['image'] as String?) ??
          (json['imageUrl'] as String? ?? ''),
      imageOnLeft: json['imageOnLeft'] as bool? ?? true,
    );
  }
}
