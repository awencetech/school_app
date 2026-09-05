import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

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
          onPressed: () => navigateBack(context),
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  color: const Color(0xffeef2f7),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  color: const Color(0xffeef2f7),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: Color(0xff6b7280),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xffeef2f7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.newspaper,
                                    size: 40,
                                    color: Color(0xff6b7280),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 18),
                            if (item.heading.isNotEmpty)
                              Text(
                                item.heading,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff111827),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (item.introduction.isNotEmpty)
                              Text(
                                item.introduction,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: Color(0xff374151),
                                ),
                              ),
                            const SizedBox(height: 18),
                            ...item.sections.map(
                              (section) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (section.subHeading.isNotEmpty)
                                      Text(
                                        section.subHeading,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xff111827),
                                        ),
                                      ),
                                    if (section.content.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        section.content,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.7,
                                          color: Color(0xff374151),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
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
