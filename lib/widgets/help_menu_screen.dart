import 'package:flutter/material.dart';

class HelpMenuScreen extends StatefulWidget {
  const HelpMenuScreen({super.key});

  @override
  State<HelpMenuScreen> createState() => _HelpMenuScreenState();
}

class _HelpMenuScreenState extends State<HelpMenuScreen> {
  final List<String?> _healthResponses = [null, null];
  final List<String?> _feelingResponses = [null, null];

  static const _feelings = [
    ('\u{1f601}', 'Excited'),
    ('\u{1f642}', 'Happy'),
    ('\u{1f610}', 'OK'),
    ('\u{1f622}', 'Sad'),
    ('\u{1f621}', 'Angry'),
    ('\u{1f61f}', 'Scared'),
    ('NONE OF\nTHE\nABOVE', 'None of the\nabove'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Can we have a moment?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _healthResponses.fillRange(0, 2, null);
                    _feelingResponses.fillRange(0, 2, null);
                  }),
                ),
              ],
            ),
            const Text(
              'Please take time and respond, it is important',
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 14),
            _checkIn(
              index: 0,
              name: 'MOHAMED TADJHEEN R',
              healthQuestion:
                  'Do you or any of your family members have cold or fever like\nsymptoms or feeling unwell?',
            ),
            const SizedBox(height: 14),
            _checkIn(
              index: 1,
              name: 'MOHAMED AZEEMSHA A',
              healthQuestion:
                  'Is MOHAMED AZEEMSHA A or any family member have cold\nor fever like symptoms or feeling unwell?',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response submitted')),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(34, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    textStyle: const TextStyle(fontSize: 9),
                  ),
                  child: const Text('Submit'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _healthResponses.fillRange(0, 2, null);
                    _feelingResponses.fillRange(0, 2, null);
                  }),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(34, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    textStyle: const TextStyle(fontSize: 9),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkIn({
    required int index,
    required String name,
    required String healthQuestion,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '# How are $name feeling ..',
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            for (
              var feelingIndex = 0;
              feelingIndex < _feelings.length;
              feelingIndex++
            )
              _FeelingChoice(
                emoji: _feelings[feelingIndex].$1,
                label: _feelings[feelingIndex].$2,
                selected:
                    _feelingResponses[index] == _feelings[feelingIndex].$2,
                onTap: () => setState(
                  () => _feelingResponses[index] = _feelings[feelingIndex].$2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          healthQuestion,
          style: const TextStyle(fontSize: 11, height: 1.15),
        ),
        Row(
          children: [
            _AnswerRadio(
              label: 'Yes',
              selected: _healthResponses[index] == 'Yes',
              onTap: () => setState(() => _healthResponses[index] = 'Yes'),
            ),
            _AnswerRadio(
              label: 'No',
              selected: _healthResponses[index] == 'No',
              onTap: () => setState(() => _healthResponses[index] = 'No'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeelingChoice extends StatelessWidget {
  const _FeelingChoice({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        child: Column(
          children: [
            Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xffffe082) : Colors.transparent,
              ),
              child: Text(
                emoji,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: label.startsWith('None') ? 7 : 27),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, height: 1.05),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerRadio extends StatelessWidget {
  const _AnswerRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, top: 5, bottom: 5),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 15,
              color: const Color(0xffb7c0c8),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class HelpContentScreen extends StatelessWidget {
  const HelpContentScreen({super.key});

  static const _homeItems = [
    _HelpItem(
      'Website',
      Icons.menu_book,
      Color(0xff4cae27),
      'Takes you to your School Menu that gives information on the School. School Menu you can access the School Website, School Announcements, School Newsletter, School Demography, School Resources.',
    ),
    _HelpItem(
      'Calendar, Events, Holidays',
      Icons.calendar_month,
      Color(0xffb51b1b),
      'Gives a consolidated view of some important information sent from the school. New unread messages will appear in News Messages pane.',
    ),
    _HelpItem(
      'Dashboard Summary Info',
      Icons.pie_chart,
      Color(0xff0c458b),
      'Gives a consolidated view of some important information about School.',
    ),
    _HelpItem(
      'Messages HW, CW',
      Icons.mail,
      Color(0xffff6847),
      'On click of this tile it will show you all the messages meant for you. It could be reminders, homework, news, emergency alerts, awareness, holiday messages, parent-teacher meeting, results announcements.',
    ),
    _HelpItem(
      'Student!',
      Icons.person,
      Color(0xff43af52),
      'On click of this tile, you will be taken Student related menu/options where the student/parent can view student related information.',
    ),
    _HelpItem(
      'Class/Group Bus',
      Icons.groups,
      Color(0xffd85c5c),
      'Takes you to the Group/Class Menu. You will be shown groups/classes you are associated with and can access related functionalities.',
    ),
    _HelpItem(
      'Check Approve',
      Icons.thumb_up,
      Color(0xffe0c900),
      'Find messages that you have been waiting for approval. You can edit, delete or resend message for approval.',
    ),
    _HelpItem(
      'Request',
      Icons.inventory_2,
      Color(0xff916e39),
      'Raise request to the school for enrolment to classes or groups, enquiries, fee related information or additional access.',
    ),
    _HelpItem(
      'PTM',
      Icons.camera_alt,
      Color(0xff3985c9),
      'Takes you to PTM menu.',
    ),
    _HelpItem(
      'School Handbook',
      Icons.handshake,
      Color(0xffe0b400),
      'Takes you to School handbook menu.',
    ),
    _HelpItem(
      'Events, Celebrations',
      Icons.camera_alt,
      Color(0xffff1010),
      'Takes you to Events menu.',
    ),
    _HelpItem(
      'Facebook',
      Icons.facebook,
      Color(0xff395b9b),
      "Takes you to your School's Facebook page.",
    ),
    _HelpItem(
      'Youtube',
      Icons.ondemand_video,
      Color(0xffff1b25),
      "Takes you to your School's Youtube page.",
    ),
  ];

  static const _classItems = [
    _HelpItem(
      'Group Info',
      Icons.info,
      Color(0xff1da6a6),
      'Get information about class - Class description, Seats filled/maximum seats, Gender distribution of students, Teacher and support staff for the class, Subject and Teacher details.',
    ),
    _HelpItem(
      'Future Event Events',
      Icons.calendar_month,
      Color(0xffc62828),
      'Shows upcoming holidays, events, reminders pertaining to the group/class.',
    ),
    _HelpItem(
      'HW, Today in Class',
      Icons.assignment,
      Color(0xff9bd77b),
      'Find homework pertaining to this class here. You can also view homework given in the past or for future.',
    ),
    _HelpItem(
      'Group Messages',
      Icons.mail,
      Color(0xffff741d),
      'See all messages for the class from here. It can be attendance, homework, class happenings, or related class news.',
    ),
    _HelpItem(
      'Write Msg!, Communicate',
      Icons.edit,
      Color(0xffff1515),
      'From here write messages. A parent can write message to the Teacher or School Management.',
    ),
    _HelpItem(
      'Class Demography',
      Icons.public,
      Color(0xff7d14e8),
      'Shows on a map from which part of the city the students and teachers come from.',
    ),
    _HelpItem(
      'Class Resources',
      Icons.folder,
      Color(0xff35a9ec),
      'Here find resources like sample papers, links, contents related to the class.',
    ),
    _HelpItem(
      'Photo News',
      Icons.image,
      Color(0xff999999),
      'Place where one find class related image gallery.',
    ),
    _HelpItem(
      'Class TimeTable',
      Icons.schedule,
      Color(0xffd54ac0),
      'Shows the class time table in Calendar format if entered by the school.',
    ),
    _HelpItem(
      'Class Planner',
      Icons.view_agenda,
      Color(0xff4cae00),
      'Class planner, weekly/daily plans for the class.',
    ),
    _HelpItem(
      'Class FipLearn',
      Icons.format_list_bulleted,
      Color(0xff687b88),
      'Shows subject content curated by teacher. It can be reading assignment shared by teacher for the class.',
    ),
    _HelpItem(
      'Diary Summary',
      Icons.article,
      Color(0xff555555),
      'Here the teacher can give observation about students for each class.',
    ),
    _HelpItem(
      'Write Reviews',
      Icons.rate_review,
      Color(0xff104786),
      "Facility for teachers to give feedback regarding student's behaviour, activities, academics.",
    ),
    _HelpItem(
      'Take Attendance',
      Icons.check_box,
      Color(0xfff04444),
      'Facility only for teachers to enter Attendance for the class.',
    ),
    _HelpItem(
      'Write Medical',
      Icons.medical_services,
      Color(0xff9b8400),
      'Facility available to teachers only. This allows data to be entered against a student when a medical test is conducted.',
    ),
    _HelpItem(
      'Appreciate Student',
      Icons.card_giftcard,
      Color(0xffff6b12),
      'Facility available only for teachers. Use this to give badges to student to appreciate and recognise them.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 5),
            child: Text('Home Menu', style: TextStyle(fontSize: 11)),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              'Please find below information about the tiles shown at Home menu.\nFor more detailed help you can go to our help site at\nhttp://help.stppeity.com.',
              style: TextStyle(fontSize: 9, height: 1.15),
            ),
          ),
          for (final item in _homeItems) _HelpTile(item: item),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Text('Class Menu', style: TextStyle(fontSize: 11)),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              'Please find below information about the tiles shown at Class menu.\nFor more detailed help you can go to our help site at\nhttp://help.stppeity.com.',
              style: TextStyle(fontSize: 9, height: 1.15),
            ),
          ),
          for (final item in _classItems) _HelpTile(item: item),
        ],
      ),
    );
  }
}

class _HelpItem {
  const _HelpItem(this.title, this.icon, this.color, this.description);
  final String title;
  final IconData icon;
  final Color color;
  final String description;
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.item});
  final _HelpItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd9d9d9)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: item.color,
            child: Icon(item.icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff333333),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 8.5,
                    height: 1.1,
                    color: Color(0xff333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
