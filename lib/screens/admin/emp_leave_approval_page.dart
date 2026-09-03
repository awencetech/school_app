import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/staff_leave.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/staff_leave_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class EmpLeaveApprovalPage extends StatefulWidget {
  const EmpLeaveApprovalPage({super.key});
  @override State<EmpLeaveApprovalPage> createState() => _EmpLeaveApprovalPageState();
}
class _EmpLeaveApprovalPageState extends State<EmpLeaveApprovalPage> {
  final _service = StaffLeaveService();
  List<StaffLeaveRequest> _items = const [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final items = await _service.all(); if (mounted) setState(() { _items = items.where((item) => item.status == 'Pending').toList(); _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  Future<void> _decide(StaffLeaveRequest item, bool approve) async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(approve ? 'Approve Leave Request?' : 'Reject Leave Request?'), content: Text('Are you sure you want to ${approve ? 'approve' : 'reject'} this leave request?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(approve ? 'Approve' : 'Reject'))]));
    if (confirmed != true || item.id == null) return;
    final state = context.read<AppState>();
    final actor = {'userId': state.currentUserId ?? '', 'name': state.currentUserEmail ?? state.currentUserId ?? ''};
    try { if (approve) { await _service.approve(item.id!, actor); } else { await _service.reject(item.id!, actor, ''); } await _load(); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.topBar,
      foregroundColor: Colors.white,
      title: const Text('Employee Leave Approval'),
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
      actions: [TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.adminEmpLeaveApprovalHistory), child: const Text('History', style: TextStyle(color: Colors.white)))],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No pending leave requests available')))
          else ..._items.map(_card),
        ],
      ),
    ),
    bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (index) {
      if (index == 0 || index == 2) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false);
      if (index == 4) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
    }),
  );

  Widget _card(StaffLeaveRequest item) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.leaveType, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('${item.staffName} (${item.staffId})'),
        Text('From ${_date(item.startDate)} to ${_date(item.endDate)}'),
        Text('Effective Days: ${_number(item.effectiveDays)}'),
        Text('Reason: ${item.reason}'),
        Text('Requested On: ${_date(item.createdAt)}'),
        Row(children: [
          TextButton(onPressed: () => _showInfo(item), child: const Text('Information')),
          const Spacer(),
          TextButton(onPressed: () => _decide(item, true), child: const Text('Approve')),
          TextButton(onPressed: () => _decide(item, false), child: const Text('Reject')),
        ]),
      ]),
    ),
  );

  void _showInfo(StaffLeaveRequest item) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Leave Information'), content: Text('Leave Type: ${item.leaveType}\nStart Date: ${_date(item.startDate)}\nEnd Date: ${_date(item.endDate)}\nEffective Days: ${_number(item.effectiveDays)}\nReason: ${item.reason}\nStatus: ${item.status}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
}
String _date(DateTime? value) => value == null ? 'Not available' : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
