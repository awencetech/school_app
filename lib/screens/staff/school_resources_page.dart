import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/school_resource.dart';
import '../../services/school_resource_service.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class SchoolResourcesPage extends StatefulWidget {
  const SchoolResourcesPage({super.key});

  @override
  State<SchoolResourcesPage> createState() => _SchoolResourcesPageState();
}

class _SchoolResourcesPageState extends State<SchoolResourcesPage> {
  final _service = SchoolResourceService();
  bool _loading = true;
  List<SchoolResource> _resources = const [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getResources();
      if (!mounted) return;
      setState(() {
        _resources = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resources = const [];
        _loading = false;
      });
    }
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd-MMM-yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 42,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text('SAMUNI', style: TextStyle(fontSize: 14)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(7, 7, 7, 5),
            child: Text('Resource List', style: TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _resources.isEmpty
                    ? const Center(child: Text('No resources available'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
                        itemCount: _resources.length,
                        itemBuilder: (context, index) => _SchoolResourceRow(
                          title: _resources[index].heading,
                          date: _formatDate(_resources[index].date),
                          subtitle: _resources[index].resourceName,
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Quick Menu'),
        ],
      ),
    );
  }
}

class _SchoolResourceRow extends StatelessWidget {
  const _SchoolResourceRow({
    required this.title,
    required this.date,
    this.subtitle,
  });

  final String title;
  final String date;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 47),
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(3, 4, 4, 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdddddd)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xff173c70)),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 8, color: Color(0xff555555)),
            ),
          Text(
            date,
            style: const TextStyle(fontSize: 6, color: Color(0xff555555)),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _ResourceAction(Icons.visibility_outlined),
              _ResourceAction(Icons.info_outline),
              _ResourceAction(Icons.delete_outline),
              _ResourceAction(Icons.edit_outlined),
              _ResourceAction(Icons.download_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Icon(icon, size: 12, color: const Color(0xff777777)),
    );
  }
}
