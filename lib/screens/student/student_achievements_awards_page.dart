import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentAchievementsAwardsPage extends StatelessWidget {
  const StudentAchievementsAwardsPage({super.key});

  static const _awards = [
    _AwardEntry(
      title: 'Championing Excellence in Sports: Winner in the 8th Senior School Sports Meet',
      description:
          'Congratulations on your outstanding performance and victory in the 8th Senior School Sports Meet! Your unwavering determination, athletic spirit, and exceptional skills have earned you the prestigious Certificate of Excellence. This achievement reflects your hard work and passion for sports, serving as an inspiration for others to strive for greatness.',
      meta: 'Created by K.Vignesh Raj (SAMCBES5325) 10 C - 2026 on 09-Sep-26',
    ),
    _AwardEntry(
      title: 'Celebrating the Spirit of Non-Violence: Participation in the Gandhi Janti Intra-School Competition',
      description:
          'Congratulations on your active participation in the Gandhi Janti Intra-School Competition held on 4th October 2023! Your passion and reflections on the teachings and philosophy of Mahatma Gandhi were truly inspiring, and your contribution was instrumental in the success of the event. We are delighted to honour your commitment with a Certificate of Participation. May this acknowledgement act as a beacon, illuminating your intellectual path through the ideals of peace, truth, and non-violence.',
      meta: 'Created by IYSHWARYA (1017) 7 A - 2023 on 09-Oct-23',
    ),
    _AwardEntry(
      title: 'Celebrating Cosmic Curiosity: Participation in the Chandrayaan 3 Intra-School Competition',
      description:
          'Congratulations on actively participating in the Chandrayaan 3 Intra-School Competition! Your enthusiasm and dedication to lunar science and space exploration shine brightly, and your contribution played a key role in making the event a success. We are pleased to honor your engagement with a Certificate of Participation. May this recognition serve as a stepping stone in your intellectual journey through the vast cosmos.',
      meta: 'Created by K.Vignesh Raj (SAMCBES5325) 10 C - 2026 on 09-Sep-26',
    ),
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
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Badges, Awards, Achievements',
              style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'For MOHAMED AZEEMSHA A',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appreciation/Badges Given',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1d3557),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No Data available',
                    style: TextStyle(fontSize: 11, color: Color(0xff4d4d4d)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Awards/Certificates Given',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1d3557),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._awards.map((award) => _AwardCard(award: award)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.award});

  final _AwardEntry award;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd7d7d7)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            award.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xff1e2a39),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            award.description,
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              color: Color(0xff355c8a),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xff1c9a46),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  award.meta,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xff666666),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AwardEntry {
  const _AwardEntry({
    required this.title,
    required this.description,
    required this.meta,
  });

  final String title;
  final String description;
  final String meta;
}
