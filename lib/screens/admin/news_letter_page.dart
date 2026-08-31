import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/newsletter.dart';
import '../../services/newsletter_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class NewsLetterPage extends StatefulWidget {
  const NewsLetterPage({super.key});

  @override
  State<NewsLetterPage> createState() => _NewsLetterPageState();
}

class _NewsLetterPageState extends State<NewsLetterPage> {
  final _service = NewsletterService();
  bool _loading = true;
  List<Newsletter> _newsletters = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getNewsletters();
      if (!mounted) return;
      setState(() {
        _newsletters = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newsletters = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Newsletter'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _newsletters.isEmpty
                ? const Center(
                    child: Text(
                      'No newsletter content yet.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _newsletters.length,
                    itemBuilder: (context, index) {
                      final item = _newsletters[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => const SizedBox(
                                      height: 180,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, _, _) => Container(
                                      height: 180,
                                      color: const Color(0xffeef2f7),
                                      child: const Center(
                                        child: Icon(Icons.broken_image_outlined),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffeef2f7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.newspaper, size: 40),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                item.heading,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (item.introduction.isNotEmpty)
                                Text(
                                  item.introduction,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xff374151),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ...item.sections.map(
                                (section) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (section.subHeading.isNotEmpty)
                                        Text(
                                          section.subHeading,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (section.content.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          section.content,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.6,
                                            color: Color(0xff4b5563),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
      ),
    );
  }
}
