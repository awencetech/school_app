import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../models/staff_leave.dart';
import '../../services/app_state.dart';
import '../../services/staff_leave_service.dart';
import '../../widgets/admin_bottom_nav.dart';

class LeaveApprovalPage extends StatefulWidget {
  const LeaveApprovalPage({super.key, required this.group});

  final Group group;

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final StaffLeaveService _service = StaffLeaveService();
  List<StaffLeaveRequest> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.all();
      if (!mounted) return;
      setState(() {
        _items = items.where((item) => item.status.toLowerCase() == 'pending').toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(StaffLeaveRequest item, bool approve) async {
    if (item.id == null) return;
    final state = context.read<AppState>();
    final actor = {
      'userId': state.currentUserId ?? '',
      'name': state.currentUserEmail ?? state.currentUserId ?? '',
    };
    try {
      if (approve) {
        await _service.approve(item.id!, actor);
      } else {
        await _service.reject(item.id!, actor, '');
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 46,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 9),
          alignment: Alignment.centerLeft,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text(
          'Today in Class',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(
                height: 27,
                child: Padding(
                  padding: EdgeInsets.only(left: 3, top: 7),
                  child: Text('Approve Leaves', style: TextStyle(fontSize: 11, color: Color(0xff1d3557))),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
              if (_loading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (_items.isEmpty)
                const Padding(padding: EdgeInsets.all(12), child: Text('No pending leave requests available', style: TextStyle(fontSize: 10)))
              else
                ..._items.map(_leaveCard),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (_) {},
      ),
    );
  }

  Widget _leaveCard(StaffLeaveRequest item) => Container(
    padding: const EdgeInsets.fromLTRB(2, 5, 2, 4),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffdddddd)))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${item.staffId}-${item.staffName}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      Text(item.reason, style: const TextStyle(fontSize: 8)),
      Text('${item.leaveType} - ${item.year}', style: const TextStyle(fontSize: 8)),
      Text('Status: ${item.status}', style: const TextStyle(fontSize: 8)),
      Text('From ${_date(item.startDate)} to ${_date(item.endDate)}', style: const TextStyle(fontSize: 8)),
      Text('Creation Dt ${_date(item.createdAt)}', style: const TextStyle(fontSize: 8)),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => _showInfo(item), child: const Text('Info', style: TextStyle(fontSize: 8))),
        TextButton(onPressed: () => _decide(item, true), child: const Text('Approve', style: TextStyle(fontSize: 8))),
        TextButton(onPressed: () => _decide(item, false), child: const Text('Reject', style: TextStyle(fontSize: 8))),
      ]),
    ]),
  );

  void _showInfo(StaffLeaveRequest item) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Leave Information'),
      content: Text('Leave Type: ${item.leaveType}\nStart Date: ${_date(item.startDate)}\nEnd Date: ${_date(item.endDate)}\nEffective Days: ${item.effectiveDays}\nReason: ${item.reason}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}

String _date(DateTime? value) => value == null ? 'Not available' : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
