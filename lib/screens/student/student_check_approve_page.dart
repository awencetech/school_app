import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/student_request.dart';
import '../../services/student_request_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentCheckApprovePage extends StatefulWidget {
  const StudentCheckApprovePage({
    super.key,
    this.headerTitle = 'SAMUNI',
    this.quickAccessTitle,
    this.approvalMode = false,
  });

  final String headerTitle;
  final String? quickAccessTitle;
  final bool approvalMode;

  @override
  State<StudentCheckApprovePage> createState() =>
      _StudentCheckApprovePageState();
}

class _StudentCheckApprovePageState extends State<StudentCheckApprovePage> {
  bool _showMyMessages = false;
  final _requestService = StudentRequestService();
  List<StudentRequest> _requests = [];
  bool _loadingRequests = false;
  String? _requestError;

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
  void initState() {
    super.initState();
    if (widget.approvalMode) _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loadingRequests = true;
      _requestError = null;
    });
    try {
      final requests = await _requestService.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loadingRequests = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRequests = false;
        _requestError = 'Unable to load student requests.';
      });
    }
  }

  Future<void> _updateRequest(StudentRequest request, String status) async {
    try {
      await _requestService.updateStatus(id: request.id, status: status);
      if (!mounted) return;
      await _loadRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update request status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        appBar: widget.quickAccessTitle != null
          ? QuickAccessAppBar(title: widget.quickAccessTitle!)
          : AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: Text(
          widget.headerTitle,
          style: const TextStyle(color: Colors.white, fontSize: 14),
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
            child: widget.approvalMode
                ? _buildRequestApprovalList()
                : _showMyMessages
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

  Widget _buildRequestApprovalList() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requestError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_requestError!),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadRequests, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Center(child: Text('No student requests pending approval.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _StudentRequestApprovalCard(
          request: request,
          onApprove: () => _updateRequest(request, 'Approved'),
          onReject: () => _updateRequest(request, 'Rejected'),
        );
      },
    );
  }
}

class _StudentRequestApprovalCard extends StatelessWidget {
  const _StudentRequestApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final StudentRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final date = request.createdAt;
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
                child: Icon(Icons.person_outline, size: 25, color: Color(0xffcccccc)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Student: ${request.studentName.isEmpty ? request.studentUsername : request.studentName}\nUsername: ${request.studentUsername}\nRequest Type: ${request.requestType}\nDate: $dateText',
                  style: const TextStyle(fontSize: 8, height: 1.25, color: Color(0xff355c8a)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text('Request: ${request.title}', style: const TextStyle(fontSize: 10, color: Color(0xff333333))),
          const SizedBox(height: 3),
          Text('Details: ${request.description}', style: const TextStyle(fontSize: 9, height: 1.25, color: Color(0xff333333))),
          const SizedBox(height: 3),
          const Text('Status: Pending', style: TextStyle(fontSize: 9, color: Color(0xffff8c00))),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onApprove, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('Approve', style: TextStyle(fontSize: 8, color: Color(0xff087ff5)))),
              TextButton(onPressed: onReject, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('Reject', style: TextStyle(fontSize: 8, color: Color(0xff087ff5)))),
            ],
          ),
        ],
      ),
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
