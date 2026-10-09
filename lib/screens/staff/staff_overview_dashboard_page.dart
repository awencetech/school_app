import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/admin_message.dart';
import '../../models/school_news.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_message_service.dart';
import '../../services/app_state.dart';
import '../../services/school_news_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/quick_access_app_bar.dart';

class StaffOverviewDashboardPage extends StatefulWidget {
  const StaffOverviewDashboardPage({super.key, this.quickAccessTitle});

  final String? quickAccessTitle;

  @override
  State<StaffOverviewDashboardPage> createState() =>
      _StaffOverviewDashboardPageState();
}

class _StaffOverviewDashboardPageState
    extends State<StaffOverviewDashboardPage> {
  bool _showAdminDashboard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.quickAccessTitle != null
          ? QuickAccessAppBar(title: widget.quickAccessTitle!)
          : AppBar(
              backgroundColor: AppColors.topBar,
              foregroundColor: Colors.white,
              toolbarHeight: 45,
              automaticallyImplyLeading: false,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => navigateBack(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Dashboard Summary',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(3, 7, 3, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'News Summaries',
              style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Tab(
                  label: 'User Dash',
                  selected: !_showAdminDashboard,
                  onTap: () => setState(() => _showAdminDashboard = false),
                ),
                _Tab(
                  label: 'Admin Dash',
                  selected: _showAdminDashboard,
                  onTap: () => setState(() => _showAdminDashboard = true),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _showAdminDashboard
                ? const _AdminDashboardContent()
                : const _UserDashboardContent(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xfff1f1f1) : Colors.white,
          border: Border.all(color: const Color(0xffdddddd)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Color(0xff1d3557)),
        ),
      ),
    );
  }
}

class _UserDashboardContent extends StatefulWidget {
  const _UserDashboardContent();

  @override
  State<_UserDashboardContent> createState() => _UserDashboardContentState();
}

class _UserDashboardContentState extends State<_UserDashboardContent> {
  late final Future<List<SchoolNews>> _schoolNewsFuture;

  @override
  void initState() {
    super.initState();
    _schoolNewsFuture = SchoolNewsService().getSchoolNews(onlyPublished: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SchoolNews>>(
      future: _schoolNewsFuture,
      builder: (context, snapshot) {
        final publishedNews =
            List<SchoolNews>.from(snapshot.data ?? const <SchoolNews>[])
              ..sort((a, b) {
                final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });

        final newsCards = publishedNews.isEmpty
            ? const [
                _NewsDataCard(
                  title: 'No school news available',
                  message: 'There are no public school news at the moment.',
                ),
              ]
            : publishedNews.take(3).map((news) {
                final date = news.date != null
                    ? DateFormat('dd-MMM-yy').format(news.date!)
                    : 'Date n/a';
                return _NewsDataCard(
                  title: '$date - ${news.title}',
                  message: news.news,
                );
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _UnreadMessagesSection(),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffdddddd)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xffeeeeee),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: const Text(
                      'News',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff222222),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Text(
                            'Loading school news...',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xff355c8a),
                            ),
                          )
                        : Column(children: newsCards),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnreadMessagesSection extends StatefulWidget {
  const _UnreadMessagesSection();

  @override
  State<_UnreadMessagesSection> createState() => _UnreadMessagesSectionState();
}

class _UnreadMessagesSectionState extends State<_UnreadMessagesSection> {
  late final Future<List<AdminMessage>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    final role =
        context.read<AppState>().currentUserRole?.trim().toLowerCase() ?? '';
    _messagesFuture = AdminMessageService().getMessagesForRole(role);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminMessage>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Section(
            title: 'New Messages',
            lines: ['Loading messages...'],
          );
        }
        if (snapshot.hasError) {
          return const _Section(
            title: 'New Messages',
            lines: ['Unable to load messages.'],
          );
        }

        final unreadMessages = (snapshot.data ?? const <AdminMessage>[])
            .where((message) => !message.read)
            .toList();
        final lines = unreadMessages.isEmpty
            ? const ['No new messages available.']
            : unreadMessages.take(10).map((message) {
                final date = message.createdAt == null
                    ? ''
                    : '${DateFormat('dd-MMM-yy').format(message.createdAt!)} - ';
                return '$date${message.senderName}: ${message.subject}';
              }).toList();

        return _Section(
          title: 'New Messages (${unreadMessages.length})',
          lines: lines,
        );
      },
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(title: 'Dashboard', lines: ['No dashboard data available.']),
        SizedBox(height: 6),
        _TrendTable(),
      ],
    );
  }
}

class _NewsDataCard extends StatelessWidget {
  const _NewsDataCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        border: Border.all(color: const Color(0xffd7e3f2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xff22324a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 8,
              height: 1.35,
              color: Color(0xff355c8a),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xffeeeeee),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xff222222),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Row(
                      children: [
                        Flexible(
                          child: Text(
                            line,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1.35,
                              color: Color(0xff355c8a),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTable extends StatelessWidget {
  const _TrendTable();

  @override
  Widget build(BuildContext context) {
    const rows = <List<String>>[];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xffeeeeee),
            padding: const EdgeInsets.all(4),
            child: const Text(
              'Messages Trend',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const _TrendRow(
            values: ['Date', 'Msgs', 'SMS', 'Notifications'],
            header: true,
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'No message trend data available.',
                style: TextStyle(fontSize: 8, color: Color(0xff355c8a)),
              ),
            )
          else
            ...rows.map((row) => _TrendRow(values: row)),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.values, this.header = false});

  final List<String> values;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header ? const Color(0xffe5e9ed) : const Color(0xfff5f5f5),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: values
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    value,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: header ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
