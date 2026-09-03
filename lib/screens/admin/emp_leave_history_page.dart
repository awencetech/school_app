import 'package:flutter/material.dart';
import '../../models/staff_leave.dart';
import '../../routes/app_routes.dart';
import '../../services/staff_leave_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class EmpLeaveHistoryPage extends StatefulWidget {
  const EmpLeaveHistoryPage({super.key});
  @override State<EmpLeaveHistoryPage> createState() => _EmpLeaveHistoryPageState();
}
class _EmpLeaveHistoryPageState extends State<EmpLeaveHistoryPage> {
  final _service = StaffLeaveService();
  List<StaffLeaveRequest> _items = const [];
  bool _loading = true;
  String _filter = 'All';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final items = await _service.history(); if (mounted) setState(() { _items = items; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  @override Widget build(BuildContext context) { final visible = _items.where((item) => _filter == 'All' || item.status == _filter).toList(); return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(backgroundColor: AppColors.topBar, foregroundColor: Colors.white, title: const Text('Leave History'), leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back))), body: ListView(padding: const EdgeInsets.all(14), children: [_loading ? const Center(child: CircularProgressIndicator()) : SegmentedButton<String>(segments: const [ButtonSegment(value: 'All', label: Text('All')), ButtonSegment(value: 'Approved', label: Text('Approved')), ButtonSegment(value: 'Rejected', label: Text('Rejected'))], selected: {_filter}, onSelectionChanged: (value) => setState(() => _filter = value.first)), const SizedBox(height: 14), if (!_loading && visible.isEmpty) const Center(child: Text('No leave history available')) else ...visible.map(_card)]), bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 0, onItemSelected: (index) { if (index == 0 || index == 2) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false); if (index == 4) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false); })); }
  Widget _card(StaffLeaveRequest item) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.leaveType, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${item.staffName} (${item.staffId})'), Text('From ${_date(item.startDate)} to ${_date(item.endDate)}'), Text('Effective Days: ${_number(item.effectiveDays)}'), Text('Reason: ${item.reason}'), Text('Requested Date: ${_date(item.createdAt)}'), Text('Status: ${item.status}', style: TextStyle(color: item.status == 'Approved' ? Colors.green : Colors.red, fontWeight: FontWeight.w700))])));
}
String _date(DateTime? value) => value == null ? 'Not available' : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
