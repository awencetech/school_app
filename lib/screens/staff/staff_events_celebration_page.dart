import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/management_member.dart';
import '../../services/school_config_service.dart';
import '../../widgets/staff_footer.dart';

class StaffEventsCelebrationPage extends StatelessWidget {
  const StaffEventsCelebrationPage({super.key});

  static final _fallbackItems = [
    ManagementMember(
      title: 'Winter Bells 2025: A Grand Celebration of Talent and Festivity',
      description:
          'A joyful school celebration featuring student talent, music, and festive activities.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Pongal Panorama 2026: Pongal Competitions',
      description:
          'Students celebrate Pongal through cultural programmes and traditional competitions.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Threads of Tricolour, Echoes of Freedom',
      description:
          'Republic Day celebrations filled with pride, creativity, and student participation.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'United for a Cleaner Tomorrow',
      description:
          'Students and staff join together for a cleaner and greener school community.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Celebrating Champions: Competition Winners',
      description:
          'Congratulations to our students for their outstanding achievements and dedication.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Invoking the Light of Learning',
      description:
          'A special school gathering celebrating learning, values, and new beginnings.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Parent Teachers Meet',
      description:
          'An opportunity for parents and teachers to connect and support student progress.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
    ManagementMember(
      title: 'Road Safety and Responsible Citizenship',
      description:
          'An awareness initiative encouraging safe travel and responsible citizenship.',
      photoBase64: '',
      name: '',
      designation: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final configuredItems = context.watch<SchoolConfigService>().homeContent;
    final items = configuredItems.isNotEmpty ? configuredItems : _fallbackItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Events Celebration')),
      body: GridView.builder(
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

  final ManagementMember item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isNotEmpty ? item.title : item.name;

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
            Expanded(child: _EventImage(source: item.photoBase64)),
            const SizedBox(height: 5),
            Text(
              item.description,
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

  final ManagementMember item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isNotEmpty ? item.title : item.name;
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _EventImage(source: item.photoBase64)),
          const SizedBox(height: 14),
          Text(
            item.description,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}
