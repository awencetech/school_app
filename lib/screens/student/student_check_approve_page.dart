import 'package:flutter/material.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentCheckApprovePage extends StatefulWidget {
  const StudentCheckApprovePage({super.key});

  @override
  State<StudentCheckApprovePage> createState() =>
      _StudentCheckApprovePageState();
}

class _StudentCheckApprovePageState extends State<StudentCheckApprovePage> {
  bool _showMyMessages = false;

  static const _pendingMessages = [
    _ApprovalMessage(
      'Notification',
      'Created on: Aug 27, 2026 9:32 AM Comments not allowed\nMessage for 3-B by Ramya_Nivas from Teacher of 3 A Grade 3 A - 2026-27 (2026)\nMessage is sent to Students',
      'Attention Students of Class 3A 📣 This is a Gentle reminder regarding your upcoming computer science submissions. You are required to submit the following work on Monday, 31st August 2026: CS Class Notebook 📖 CS Uolo Tekie Book 📚 Important Instructions: *All incomplete exercises and activities in Chapter 2 and Chapter 3 must be completed without fail.',
    ),
    _ApprovalMessage(
      'Notification',
      'Created on: Aug 27, 2026 9:33 AM Comments not allowed\nMessage for 3-B by Ramya_Nivas from Teacher of 3 B Grade 3 B - 2026-27 (2026)\nMessage is sent to Students',
      'Attention Students of Class 3B 📣 This is a Gentle reminder regarding your upcoming computer science submissions. You are required to submit the following work on Monday, 31st August 2026: CS Class Notebook 📖 CS Uolo Tekie Book 📚 Important Instructions: *All incomplete exercises and activities in Chapter 2 and Chapter 3 must be completed without fail.',
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
          onPressed: () => Navigator.of(context).maybePop(),
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
              'Messages to Approve',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _Tab(
                label: 'Super Approver',
                selected: !_showMyMessages,
                onTap: () => setState(() => _showMyMessages = false),
              ),
              _Tab(
                label: 'My Message',
                selected: _showMyMessages,
                onTap: () => setState(() => _showMyMessages = true),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              _showMyMessages
                  ? 'No Messages Pending Approval'
                  : 'Messages to approve as Super Approver',
              style: const TextStyle(fontSize: 10, color: Color(0xff1d3557)),
            ),
          ),
          Expanded(
            child: _showMyMessages
                ? const SizedBox()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    itemCount: _pendingMessages.length,
                    itemBuilder: (context, index) =>
                        _ApprovalCard(message: _pendingMessages[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xfff7f7f7),
          border: Border.all(color: const Color(0xffdddddd)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: selected ? const Color(0xff333333) : const Color(0xff087ff5),
          ),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.message});

  final _ApprovalMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xffeeeeee),
                child: Icon(
                  Icons.person_outline,
                  size: 25,
                  color: Color(0xffcccccc),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff087ff5),
                      ),
                    ),
                    Text(
                      message.details,
                      style: const TextStyle(
                        fontSize: 7,
                        height: 1.2,
                        color: Color(0xff355c8a),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            message.body,
            style: const TextStyle(
              fontSize: 10,
              height: 1.25,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 7)),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Approve as Super Approver',
                  style: TextStyle(fontSize: 7, color: Color(0xff087ff5)),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Not Approve',
                  style: TextStyle(fontSize: 7, color: Color(0xff087ff5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalMessage {
  const _ApprovalMessage(this.title, this.details, this.body);

  final String title;
  final String details;
  final String body;
}
