import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/one_on_one_meeting.dart';
import '../../services/app_state.dart';
import '../../services/one_on_one_meeting_service.dart';
import '../../widgets/staff_footer.dart';

class StaffMeetingPage extends StatefulWidget {
  const StaffMeetingPage({super.key});

  @override
  State<StaffMeetingPage> createState() => _StaffMeetingPageState();
}

class _StaffMeetingPageState extends State<StaffMeetingPage> {
  final _service = OneOnOneMeetingService();
  List<OneOnOneMeeting> _meetings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final token = context.read<AppState>().currentAuthToken?.trim() ?? '';
    if (token.isEmpty) {
      setState(() { _loading = false; _error = 'Please sign in again to view meeting information.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final meetings = await _service.getMyMeetings(token: token);
      if (mounted) setState(() { _meetings = meetings; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MeetingAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadMeetings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          children: [
            const Text('Meetings Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Meetings assigned to you by the administrator.'),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(35), child: CircularProgressIndicator()))
            else if (_error != null)
              Column(children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), TextButton(onPressed: _loadMeetings, child: const Text('Retry'))])
            else if (_meetings.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: Text('No meeting information available.')))
            else ...[
              ..._meetings.map((meeting) => _MeetingCard(meeting: meeting)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MeetingInfoHistoryPage(meetings: _meetings))),
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('View Meeting Notes'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});
  final OneOnOneMeeting meeting;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_meetingDate(meeting.startDateTime), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(meeting.meetingTime),
            const SizedBox(height: 8),
            Text(meeting.meetingInfo),
            if (meeting.meetingUrl.isNotEmpty)
              TextButton.icon(onPressed: () => launchUrl(Uri.parse(meeting.meetingUrl), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const Text('Open meeting link')),
          ]),
        ),
      );
}

class MeetingInfoHistoryPage extends StatelessWidget {
  const MeetingInfoHistoryPage({super.key, required this.meetings});
  final List<OneOnOneMeeting> meetings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const _MeetingAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          const Text('Meeting Info History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          if (meetings.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${meetings.first.staffName}  |  Staff ID: ${meetings.first.staffId}'),
            const SizedBox(height: 16),
            ...meetings.map((meeting) => _MeetingCard(meeting: meeting)),
          ] else
            const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: Center(child: Text('No meeting information available.'))),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

String _meetingDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

class _MeetingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MeetingAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 39,
      elevation: 0,
      leading: IconButton(
        onPressed: () => navigateBack(context),
        icon: const Icon(Icons.arrow_back, size: 20),
      ),
      title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(39);
}
