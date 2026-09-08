import 'package:flutter/material.dart';
import '../../models/staff_leave.dart';
import '../../services/staff_leave_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class StaffRequestApprovalPage extends StatefulWidget {
  const StaffRequestApprovalPage({super.key});

  @override
  State<StaffRequestApprovalPage> createState() => _StaffRequestApprovalPageState();
}

class _StaffRequestApprovalPageState extends State<StaffRequestApprovalPage> {
  final _service = StaffLeaveService();
  List<StaffLeaveRequest> _requests = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final requests = await _service.staffRequests();
      if (mounted) setState(() { _requests = requests.where((item) => item.status == 'Pending').toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(StaffLeaveRequest request, String status) async {
    if (request.id == null) return;
    try {
      await _service.updateStaffRequestStatus(request.id!, status);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        foregroundColor: Colors.white,
        title: const Text('Check Approval', style: TextStyle(fontSize: 14)),
        leading: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(8, 10, 8, 20), children: [
          const Text('Staff Leave Requests', style: TextStyle(fontSize: 13, color: Color(0xff1d3557), fontWeight: FontWeight.w600)),
          const Divider(),
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_requests.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No pending leave requests available', style: TextStyle(fontSize: 11)))
          else ..._requests.map(_card),
        ]),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }

  Widget _card(StaffLeaveRequest request) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xffdddddd)), borderRadius: BorderRadius.circular(4)),
    child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Leave Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('From: ${request.staffName.isEmpty ? request.staffId : request.staffName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      Text('Type: ${request.leaveType}', style: const TextStyle(fontSize: 11)),
      Text('${_date(request.startDate)} → ${_date(request.endDate)}', style: const TextStyle(fontSize: 11)),
      const SizedBox(height: 4),
      Text('Reason: ${request.reason}', style: const TextStyle(fontSize: 11)),
      if (request.status.isNotEmpty) Text('Status: ${request.status}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => _decide(request, 'Approved'), child: const Text('Accept')),
        TextButton(onPressed: () => _decide(request, 'Rejected'), child: const Text('Reject')),
      ]),
    ])),
  );

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';
  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}
