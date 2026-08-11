/// Topper item used for Grade X and Grade XII sections in the School Content Management System.
class TopperEntry {
  TopperEntry({
    required this.photoBase64,
    required this.studentName,
    required this.marks,
    this.imageFit = 'cover',
    this.cropData,
  });

  final String photoBase64;
  final String studentName;
  final String marks;
  final String imageFit;
  final Map<String, dynamic>? cropData;

  factory TopperEntry.fromJson(Map<String, dynamic> json) {
    return TopperEntry(
      photoBase64: json['photoBase64'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      marks: json['marks'] as String? ?? '',
      imageFit: json['imageFit'] as String? ?? 'cover',
      cropData: json['cropData'] is Map<String, dynamic> ? json['cropData'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoBase64': photoBase64,
      'studentName': studentName,
      'marks': marks,
      'imageFit': imageFit,
      if (cropData != null) 'cropData': cropData,
    };
  }
}
