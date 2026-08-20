import 'package:latlong2/latlong.dart';

enum MarkerType { school, teacher, student }

class MapLocation {
  const MapLocation({required this.name, required this.latitude, required this.longitude, required this.type});

  final String name;
  final double latitude;
  final double longitude;
  final MarkerType type;

  LatLng get point => LatLng(latitude, longitude);
}

class ClassDemography {
  const ClassDemography({
    required this.className,
    required this.academicYear,
    required this.schoolName,
    required this.classTeachers,
    required this.otherTeachers,
    required this.students,
    required this.locations,
  });

  final String className;
  final String academicYear;
  final String schoolName;
  final List<String> classTeachers;
  final List<String> otherTeachers;
  final List<String> students;
  final List<MapLocation> locations;
}
