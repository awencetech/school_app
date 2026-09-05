import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class StaffCampaignsPage extends StatelessWidget {
  const StaffCampaignsPage({super.key});

  static const _campaigns = [
    _Campaign(
      'Deworming tablet - administering Albendazole Tablet - Reg.',
      'From 21-Aug 24 to 22-Aug 24',
      'Type: consent',
    ),
    _Campaign(
      'Feed back about the school app',
      'From 22-Dec 20 to 24-Dec 20',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST - POSTER MAKING COMPETITION',
      'From 07-Jun 21 to 12-Jun 21',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST - KNOW YOUR BLOOD CAMPAIGN',
      'From 15-Jun 21 to 18-Jun 21',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST - KNOW YOUR INNER UNIVERSE CONTEST',
      'From 22-Jun 21 to 24-Jun 21',
      'Type: consent',
    ),
    _Campaign(
      'UNIFEST - SAY NO PLASTICS-NO POLLUTION CONTEST',
      'From 29-Jun 21 to 30-Jun 21',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST - ENERGY CONSERVATION - WEEK 5',
      'From 06-Jul 21 to 08-Jul 21',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST - VNC/A LITERATURE - WEEK',
      'From 19-Jul 21 to 23-Jul 21',
      'Type: survey',
    ),
    _Campaign(
      'UNIFEST MUTHAMIL VIZHA',
      'From 26-Jul 21 to 28-Jul 21',
      'Type: survey',
    ),
  ];

  void _selectCampaign(BuildContext context, _Campaign campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StaffCampaignDetailPage(campaign: campaign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 39,
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
            padding: EdgeInsets.fromLTRB(2, 8, 2, 4),
            child: Text(
              'Campaigns, Surveys',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: Text(
              'Please take time to respond. Your input is important',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Color(0xff1d3557),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final campaign = _campaigns[index];
                return _CampaignTile(
                  campaign: campaign,
                  onSelect: () => _selectCampaign(context, campaign),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _bottomNavigation(BuildContext context) => ReusableBottomNavigationBar(
    currentIndex: 2,
    onItemSelected: (index) {
      if (index == 4) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
      BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
      BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
      BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
    ],
  );
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign, required this.onSelect});

  final _Campaign campaign;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xffcccccc),
        border: Border.all(color: const Color(0xffaaaaaa)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
            child: Text(
              campaign.title,
              style: const TextStyle(fontSize: 10, color: Color(0xff222222)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 1, 3, 1),
            child: Text(
              '${campaign.date}\n${campaign.type}\nStatus: Completed',
              style: const TextStyle(
                fontSize: 7,
                height: 1.15,
                color: Color(0xff355c8a),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 16,
              child: OutlinedButton.icon(
                onPressed: onSelect,
                icon: const Icon(
                  Icons.check_box_outline_blank,
                  size: 11,
                  color: Color(0xff777777),
                ),
                label: const Text(
                  'Select',
                  style: TextStyle(fontSize: 8, color: Color(0xff777777)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: Color(0xffaaaaaa)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campaign {
  const _Campaign(this.title, this.date, this.type);

  final String title;
  final String date;
  final String type;
}

class _StaffCampaignDetailPage extends StatelessWidget {
  const _StaffCampaignDetailPage({required this.campaign});

  final _Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 39,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 7, 0, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Respond to Campaigns, Surveys, memo',
              style: TextStyle(fontSize: 11, color: Color(0xff222222)),
            ),
            const SizedBox(height: 5),
            Text(
              'Description: ${campaign.title}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Updated: 29-Nov-21\nStatus: progress',
              style: TextStyle(fontSize: 9),
            ),
            const SizedBox(height: 12),
            const Text(
              'SRI AUROBINDo UNIVERSAL SCHOOL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Color(0xff222222),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cr.No.30 / SAM UNIVERSAL/GRADE 1 to 8',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
            const Text(
              'Date : 29.11.2021',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 16),
            const Text(
              'Greetings from SAM Universal!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 18),
            const Text(
              '“WARMTHNESS AROUND WITH A BOND OF LOVE\nAND HAPPINESS TO SAMUNES!”',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                'We are glad to inform you that the Offline classes for the students of Grade 1 to 8 resume from Wednesday, 1st December 2021 and function on alternate days. The entire teaching faculty will be accessible for emotional and Academic development. The health and safety of students and teachers will remain our primary focus in these extraordinary times and we know that our students and teachers work very hard to reengage with coursework and make up for ground lost during lockdown.\n\nStudents, initially need not wear uniforms ( not mandatory) and are expected to report in a formal outfit-modest and decent. Students must wear shoes (of any kind) to school. They will not be permitted to wear sandals/slippers.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Quick Menu',
          ),
        ],
      ),
    );
  }
}
