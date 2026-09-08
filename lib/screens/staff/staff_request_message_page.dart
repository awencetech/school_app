import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/student_request_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';

class StaffRequestMessagePage extends StatefulWidget {
  const StaffRequestMessagePage({
    super.key,
    this.headerTitle = 'SAMUNI',
    this.quickAccessTitle,
    this.studentMode = false,
  });

  final String headerTitle;
  final String? quickAccessTitle;
  final bool studentMode;

  @override
  State<StaffRequestMessagePage> createState() =>
      _StaffRequestMessagePageState();
}

class _StaffRequestMessagePageState extends State<StaffRequestMessagePage> {
  bool _includeCompleted = false;
  final _searchController = TextEditingController();

  static const _activeRequests = [
    _Request(
      '2026-08-27 - IDC1',
      'ID Card Request\nRequest for new student ID card',
      'Created on Aug 27, 2026 7:45 AM',
      false,
    ),
    _Request(
      '2026-08-23 - FEE1',
      'Fee Related Request\nRequest regarding fee payment details',
      'Created on Aug 23, 2026 10:59 AM',
      false,
    ),
    _Request(
      '2026-08-22 - TRN1',
      'Transport Request\nRequest for school transport route change',
      'Created on Aug 22, 2026 5:39 PM',
      false,
    ),
    _Request(
      '2026-08-21 - PDT1',
      'Personal Details Update\nRequest to update student personal details',
      'Created on Aug 21, 2026 12:27 PM',
      false,
    ),
    _Request(
      '2026-08-20 - CLS1',
      'Class Related Request\nRequest regarding class section change',
      'Created on Aug 20, 2026 12:25 PM',
      false,
    ),
  ];

  static const _completedRequests = [
    _Request(
      '2026-08-25 - BON1',
      'Bonafide Certificate\nRequest for Bonafide Certificate',
      'Created on Aug 25, 2026 8:07 AM',
      true,
    ),
    _Request(
      '2026-08-24 - CRT1',
      'Certificate Request\nRequest for academic certificate',
      'Created on Aug 24, 2026 5:27 PM',
      true,
    ),
    _Request(
      '2026-08-19 - LIB1',
      'Library Request\nRequest regarding library book issue',
      'Created on Aug 19, 2026 11:20 AM',
      true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Request> get _requests => [
    ..._activeRequests,
    if (_includeCompleted) ..._completedRequests,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.studentMode) return const _StudentRequestForm();

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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 7, 4, 0),
            child: Row(
              children: [
                const Text(
                  'Request List',
                  style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 24),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 10, color: Color(0xff087ff5)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffdddddd)),
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 7, 27, 3),
            child: Row(
              children: [
                SizedBox(
                  height: 18,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _includeCompleted = !_includeCompleted),
                    icon: Icon(
                      _includeCompleted
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      size: 9,
                    ),
                    label: Text(
                      _includeCompleted
                          ? 'Exclude Completed'
                          : 'Include Completed',
                      style: const TextStyle(fontSize: 8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a6b7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 18,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 8),
                      decoration: const InputDecoration(
                        hintText: 'Search Text...',
                        hintStyle: TextStyle(fontSize: 8),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _smallButton('Search', const Color(0xff16a6b7)),
                const SizedBox(width: 4),
                _smallButton('Reset', const Color(0xffed3b5a)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'St Dt: 2026-07-27',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.edit, size: 10, color: Color(0xff666666)),
                SizedBox(width: 19),
                Text(
                  'En Dt: 2026-08-27',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.edit, size: 10, color: Color(0xff666666)),
              ],
            ),
          ),
          if (_includeCompleted)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 3, bottom: 2),
                child: Text('< Page 1 of 9 >', style: TextStyle(fontSize: 9)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [_tableHeader(), ..._requests.map(_requestRow)],
              ),
            ),
          ),
        ],
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

  Widget _smallButton(String label, Color color) => SizedBox(
    height: 18,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 7)),
    ),
  );

  Widget _tableHeader() => Container(
    height: 18,
    color: const Color(0xffe5e9ed),
    child: const Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 3),
            child: Text('Request', style: TextStyle(fontSize: 8)),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text('Status', style: TextStyle(fontSize: 8)),
        ),
      ],
    ),
  );

  Widget _requestRow(_Request request) => Container(
    constraints: const BoxConstraints(minHeight: 33),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffe1e1e1))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
            child: Text(
              '${request.code}\n${request.description}${request.created.isEmpty ? '' : '\n${request.created}'}',
              style: const TextStyle(
                fontSize: 7,
                height: 1.2,
                color: Color(0xff355c8a),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: request.completed
                      ? const Color(0xff078b21)
                      : const Color(0xffffa500),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 17,
                color: const Color(0xff16a6b7),
                child: const Icon(
                  Icons.chevron_right,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StudentRequestForm extends StatefulWidget {
  const _StudentRequestForm();

  @override
  State<_StudentRequestForm> createState() => _StudentRequestFormState();
}

class _StudentRequestFormState extends State<_StudentRequestForm> {
  final _service = StudentRequestService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _requestType = 'ID Card Request';
  bool _isSending = false;
  String? _error;

  static const _requestTypes = [
    'ID Card Request',
    'Bonafide Certificate Request',
    'Fee Related Request',
    'Transport Request',
    'Certificate Request',
    'Personal Details Update',
    'Library Request',
    'Class/Section Change Request',
    'Other Student Request',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final state = context.read<AppState>();
    String? error;
    if (title.isEmpty) error = 'Please enter a request title.';
    if (description.isEmpty) error = 'Please enter request details.';
    if ((state.currentUserId ?? '').trim().isEmpty) {
      error = 'Your student account is missing. Please log in again.';
    }
    if ((state.currentUserRole ?? '').trim().toLowerCase() != 'student') {
      error = 'Only students can submit requests from this page.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await _service.createRequest(
        requestType: _requestType,
        title: title,
        description: description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.studentDashboardMessages,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Unable to submit request. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const QuickAccessAppBar(title: 'Request'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Request',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _requestType,
                decoration: const InputDecoration(
                  labelText: 'Request Type',
                  border: OutlineInputBorder(),
                ),
                items: _requestTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _requestType = value);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Request Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Request Details',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.main,
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
        ],
      ),
    );
  }
}

class _Request {
  const _Request(this.code, this.description, this.created, this.completed);

  final String code;
  final String description;
  final String created;
  final bool completed;
}
