import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/models/main_page_info.dart';

void main() {
  test('MainPageInfo loads all nested admin settings from JSON', () {
    const json = {
      'splashScreen': {
        'title': 'Welcome',
        'subtitle': 'Learning for life',
        'image': 'https://cdn.example.com/splash.jpg',
        'sinceYear': '1995',
        'enabled': true,
      },
      'schoolSettings': {
        'schoolName': 'My New School',
        'schoolLogo': 'https://cdn.example.com/logo.png',
        'schoolPoster': 'https://cdn.example.com/poster.jpg',
        'selectedLanguage': 'en',
        'themeColor': '#336699',
      },
      'schoolContent': {
        'founder': {
          'photo': 'https://cdn.example.com/founder.jpg',
          'name': 'Founder Name',
          'designation': 'Chairman',
          'visionTitle': 'Our Vision',
          'visionDescription': 'We empower every learner.'
        },
        'secretary': {
          'photo': 'https://cdn.example.com/secretary.jpg',
          'name': 'Secretary Name',
          'designation': 'Secretary',
          'welcomeTitle': 'Welcome',
          'welcomeMessage': 'We welcome all students.'
        },
        'headmaster': {
          'photo': 'https://cdn.example.com/headmaster.jpg',
          'name': 'Headmaster Name',
          'designation': 'Headmaster',
          'messageTitle': 'Message',
          'message': 'The future begins here.'
        },
        'members': [
          {'id': 'm1', 'photo': 'https://cdn.example.com/m1.jpg', 'name': 'Manager', 'designation': 'Manager', 'title': 'Leadership', 'description': 'Supports students', 'order': 0}
        ]
      },
      'gradePage': {
        'grade10': {'students': [{'photo': 'https://cdn.example.com/g10.jpg', 'studentName': 'Alice', 'marks': '98%'}]},
        'grade12': {'students': [{'photo': 'https://cdn.example.com/g12.jpg', 'studentName': 'Bob', 'marks': '96%'}]},
        'sportsAchievements': [
          {'image': 'https://cdn.example.com/achievement.jpg', 'studentName': 'Charlie', 'achievementDescription': 'Won district cricket cup'}
        ]
      }
    };

    final info = MainPageInfo.fromJson(json);

    expect(info.splashScreen.title, 'Welcome');
    expect(info.schoolSettings.schoolName, 'My New School');
    expect(info.schoolContent.founder.name, 'Founder Name');
    expect(info.gradePage.grade10.students.length, 1);
    expect(info.gradePage.sportsAchievements.first.studentName, 'Charlie');
  });
}
