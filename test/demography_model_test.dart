import 'package:flutter_test/flutter_test.dart';

import '../lib/models/demography.dart';

void main() {
  test('demography model serializes grouped members', () {
    final item = Demography(
      id: 'demo-1',
      groupId: 'group-1',
      groupName: 'NCC2022 NCC-2026 - FIRST YEAR',
      teachers: [
        DemographyMember(name: 'ABIRAHM', staffId: 'S235'),
      ],
      otherTeachers: [
        DemographyMember(name: 'IRAHNA PARVEEN', staffId: 'SAMCBENT5330'),
      ],
      students: [
        DemographyMember(name: 'ADAFATHIMA', studentId: 'S1197'),
      ],
    );

    expect(item.groupName, 'NCC2022 NCC-2026 - FIRST YEAR');
    expect(item.toJson()['teachers'][0]['name'], 'ABIRAHM');
    expect(item.toJson()['students'][0]['studentId'], 'S1197');
  });
}
