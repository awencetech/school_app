import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../models/group.dart';
import '../../widgets/admin_bottom_nav.dart';

class AbsencePage extends StatefulWidget {
  const AbsencePage({super.key, required this.group});

  final Group group;

  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends State<AbsencePage> {
  int _selectedTab = 0;

  Future<void> _showAttendanceForm() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _AttendanceDialog(),
    );
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
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
        ),
        title: const Text('Today in Class', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        actions: [
          SizedBox(
            width: 48,
            child: IconButton(
              padding: const EdgeInsets.only(right: 9),
              alignment: Alignment.centerRight,
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(
            height: 27,
            child: Padding(
              padding: EdgeInsets.only(left: 7, top: 7),
              child: Text('Absence', style: TextStyle(fontSize: 11, color: Color(0xff1d3557))),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
          SizedBox(
            height: 31,
            child: Row(children: [
              _Tab(label: 'Take Attendance', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
              _Tab(label: 'Analytics', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
            ]),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xffeeeeee)),
          if (_selectedTab == 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 7),
              child: SizedBox(
                width: 65,
                height: 21,
                child: ElevatedButton(
                  onPressed: _showAttendanceForm,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff087ff5), foregroundColor: Colors.white, padding: EdgeInsets.zero, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3))),
                  child: const Text('Take Attendance', style: TextStyle(fontSize: 7)),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(left: 3, top: 10), child: Text('No Attendance Taken Today', style: TextStyle(fontSize: 10, color: Color(0xff222222)))),
            const Padding(padding: EdgeInsets.only(left: 3, top: 10), child: Text('No Student Applied for Leave Today', style: TextStyle(fontSize: 10, color: Color(0xff222222)))),
          ] else
            const Padding(padding: EdgeInsets.only(left: 3, top: 12), child: Text('No Data available', style: TextStyle(fontSize: 10, color: Color(0xff222222))),),
          const Expanded(child: SizedBox()),
        ]),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(currentIndex: 2, onItemSelected: (_) {}),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: label == 'Take Attendance' ? 97 : 66,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, border: selected ? Border.all(color: const Color(0xffd9e2ec)) : null),
        child: Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xff333333) : const Color(0xff0066cc))),
      ),
    );
  }
}

class _AttendanceDialog extends StatefulWidget {
  const _AttendanceDialog();

  @override
  State<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  DateTime _date = DateTime(2026, 8, 20);

  Future<void> _chooseDate() async {
    final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (date != null) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) {
    final dateText = '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}';
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 7),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 34, child: Padding(padding: const EdgeInsets.only(left: 10, top: 10), child: Row(children: [const Text('Enter Attendance', style: TextStyle(fontSize: 11)), const Spacer(), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 24, height: 24), onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 15, color: Color(0xff777777)))]))),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(children: [
                const SizedBox(width: 38, child: Text('Subject', style: TextStyle(fontSize: 10))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 68,
                  height: 24,
                  child: DropdownButtonFormField<String>(
                    initialValue: 'Select',
                    isDense: true,
                    iconSize: 13,
                    style: const TextStyle(fontSize: 9, color: Color(0xff333333)),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 3), border: OutlineInputBorder()),
                    items: const [DropdownMenuItem(value: 'Select', child: Text('Select'))],
                    onChanged: (_) {},
                  ),
                ),
              ]),
            const SizedBox(height: 14),
              Row(children: [
                const SizedBox(width: 38, child: Text('Class Type', style: TextStyle(fontSize: 10))),
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  height: 24,
                  child: DropdownButtonFormField<String>(
                    initialValue: 'Select',
                    isDense: true,
                    iconSize: 13,
                    style: const TextStyle(fontSize: 9, color: Color(0xff333333)),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 3), border: OutlineInputBorder()),
                    items: const [DropdownMenuItem(value: 'Select', child: Text('Select'))],
                    onChanged: (_) {},
                  ),
                ),
              ]),
            const SizedBox(height: 14),
            const Text('Attendance Date', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: TextField(
                readOnly: true,
                onTap: _chooseDate,
                controller: TextEditingController(text: dateText),
                style: const TextStyle(fontSize: 10),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  suffixIcon: Icon(Icons.calendar_today, size: 13),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 13),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 20,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a64a), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                      child: const Text('Record Attendance', style: TextStyle(fontSize: 7)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 25, 10),
              child: SizedBox(
                height: 20,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff6c757d), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                  child: const Text('Close', style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
