import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentFacultyFeedbackPage extends StatelessWidget {
  const StudentFacultyFeedbackPage({super.key});

  static const _reviews = [
    'Mohamed Azeemsha is a sincere learner who shows interest in understanding new ideas. His steady efforts and positive approach help him make gradual progress in his studies. He is willing to experiment with different approaches and demonstrates creativity while applying what he has learned. His determination to improve is appreciable. Working on accuracy, completing tasks within the given time, and practising regularly will help him enhance both confidence and academic performance.',
    'Mohamed Azeemsha is an inquisitive and energetic learner who enjoys exploring new ideas and approaches every lesson with enthusiasm. He demonstrates a positive attitude towards learning and actively participates in classroom activities. His creativity, curiosity, and cooperative nature make him a valuable member of the class, and he continues to show encouraging academic development. Mohamed Azeemsha can further strengthen his academic performance by improving consistency in his study habits and revising lessons on a regular basis. Paying closer attention to accuracy and completing tasks with greater confidence will help him achieve even better results. His determination, positive attitude, and eagerness to improve will undoubtedly support his future success.',
    'Mohamed Azeemsha is an inquisitive and enthusiastic learner who continues to show a positive attitude towards learning and classroom activities.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 7),
            child: Text(
              'Reviews',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 7, 4, 5),
            child: Text(
              'For MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.note_alt_outlined,
                  size: 9,
                  color: Color(0xff008dcc),
                ),
                label: const Text(
                  'View Meeting Notes',
                  style: TextStyle(fontSize: 7, color: Color(0xff008dcc)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Color(0xff00a4d6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 2),
            child: Text(
              'Reviews/Feedback Given',
              style: TextStyle(
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: Color(0xff1d3557),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              itemCount: _reviews.length,
              itemBuilder: (context, index) =>
                  _ReviewCard(text: _reviews[index], index: index),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.text, required this.index});

  final String text;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review',
            style: TextStyle(fontSize: 10, color: Color(0xff333333)),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: index == 2 ? 21 : 10,
              height: index == 2 ? 1.12 : 1.25,
              fontWeight: index == 1 ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xff355c8a),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xff078b21),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.thumb_up,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Created by K.Vignesh Raj (SAMCBES5325) 10 C - 2026 on ${index == 1 ? '24-Jul-26' : '09-Aug-26'}',
                style: const TextStyle(fontSize: 7, color: Color(0xff777777)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
