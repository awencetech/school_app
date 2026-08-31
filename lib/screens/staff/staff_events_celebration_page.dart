import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/event_celebration.dart';
import '../../services/event_celebration_service.dart';
import '../../widgets/staff_footer.dart';

class StaffEventsCelebrationPage extends StatefulWidget {
  StaffEventsCelebrationPage({super.key});

  @override
  State<StaffEventsCelebrationPage> createState() => _StaffEventsCelebrationPageState();
}

class _StaffEventsCelebrationPageState extends State<StaffEventsCelebrationPage> {
  final _service = EventCelebrationService();
  bool _loading = true;
  List<EventCelebration> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final events = await _service.getEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _events = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _events;

    return Scaffold(
      appBar: AppBar(title: const Text('Events & Celebrations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(
              child: Text(
                'No events or celebrations saved yet.',
                textAlign: TextAlign.center,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(3, 5, 3, 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: .72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _EventCard(
                item: items[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _EventDetailPage(item: items[index]),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.item, required this.onTap});

  final EventCelebration item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.heading.isNotEmpty ? item.heading : item.subHeading;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffd0d0d0)),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 5),
            Expanded(child: _EventImage(source: item.imageUrl)),
            const SizedBox(height: 5),
            Text(
              item.subHeading,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Read more...', style: TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return const ColoredBox(color: Color(0xffeef1f3));

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(color: Color(0xffeef1f3)),
        errorWidget: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, color: Color(0xff8a8a8a)),
      );
    }

    try {
      final encoded = trimmed.toLowerCase().startsWith('data:')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      return Image.memory(
        base64Decode(encoded.replaceAll(RegExp(r'\s+'), '')),
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xff8a8a8a),
      );
    }
  }
}

class _EventDetailPage extends StatelessWidget {
  const _EventDetailPage({required this.item});

  final EventCelebration item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            item.heading,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (item.subHeading.isNotEmpty)
            Text(
              item.subHeading,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 12),
          if (item.imageUrl.isNotEmpty)
            SizedBox(height: 220, child: _EventImage(source: item.imageUrl)),
          const SizedBox(height: 14),
          Text(
            item.content,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}
