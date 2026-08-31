import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_bottom_nav.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final _service = AnnouncementService();
  bool _loading = true;
  bool _error = false;
  List<Announcement> _announcements = const [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final items = await _service.getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _announcements = const [];
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _toggleLike(Announcement item, String userId) async {
    try {
      final response = await _service.toggleLike(item.id ?? '', userId: userId);
      if (!mounted) return;
      setState(() {
        final index = _announcements.indexWhere((entry) => entry.id == item.id);
        if (index == -1) return;
        final updated = _announcements[index];
        final likes = List<String>.from(updated.likes);
        final liked = response['liked'] == true;
        if (liked) {
          if (!likes.contains(userId)) likes.add(userId);
        } else {
          likes.remove(userId);
        }
        _announcements[index] = Announcement(
          id: updated.id,
          subject: updated.subject,
          fromName: updated.fromName,
          to: updated.to,
          createdOn: updated.createdOn,
          content: updated.content,
          likes: likes,
          comments: updated.comments,
          reminders: updated.reminders,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update like.')),
      );
    }
  }

  Future<void> _addComment(Announcement item, TextEditingController controller) async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment first.')),
      );
      return;
    }

    try {
      final response = await _service.addComment(
        item.id ?? '',
        userId: 'current-user',
        userName: 'Current User',
        text: text,
      );
      if (!mounted) return;
      controller.clear();
      setState(() {
        final index = _announcements.indexWhere((entry) => entry.id == item.id);
        if (index == -1) return;
        final updated = _announcements[index];
        final comments = List<AnnouncementComment>.from(updated.comments);
        comments.add(AnnouncementComment(
          name: response['userName']?.toString() ?? 'Current User',
          text: response['text']?.toString() ?? text,
          createdAt: DateTime.now(),
        ));
        _announcements[index] = Announcement(
          id: updated.id,
          subject: updated.subject,
          fromName: updated.fromName,
          to: updated.to,
          createdOn: updated.createdOn,
          content: updated.content,
          likes: updated.likes,
          comments: comments,
          reminders: updated.reminders,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to post comment.')),
      );
    }
  }

  Future<void> _addReminder(Announcement item) async {
    try {
      await _service.addReminder(item.id ?? '', userId: 'current-user');
      if (!mounted) return;
      setState(() {
        final index = _announcements.indexWhere((entry) => entry.id == item.id);
        if (index == -1) return;
        final updated = _announcements[index];
        final reminders = List<String>.from(updated.reminders);
        if (!reminders.contains('current-user')) {
          reminders.add('current-user');
        }
        _announcements[index] = Announcement(
          id: updated.id,
          subject: updated.subject,
          fromName: updated.fromName,
          to: updated.to,
          createdOn: updated.createdOn,
          content: updated.content,
          likes: updated.likes,
          comments: updated.comments,
          reminders: reminders,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save reminder.')),
      );
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
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Messages'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Unable to load announcements'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadAnnouncements,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _announcements.isEmpty
                    ? const Center(
                        child: Text(
                          'No announcements available',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final item = _announcements[index];
                          final likeCount = item.likes.length;
                          final isLiked = item.likes.contains('current-user');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xffe8ebf7),
                                        child: Text(
                                          item.fromName.isNotEmpty ? item.fromName.substring(0, 1).toUpperCase() : 'A',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.subject,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Created On: ${item.createdOn?.isNotEmpty == true ? item.createdOn : 'Not available'}',
                                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xff666666)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Message From\n${item.fromName.isNotEmpty ? item.fromName : 'System'}',
                                              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.content,
                                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xff333333), height: 1.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleLike(item, 'current-user'),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.thumb_up_alt_outlined, size: 16),
                                            const SizedBox(width: 4),
                                            Text(isLiked ? 'Liked' : 'Like', style: GoogleFonts.poppins(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text('$likeCount', style: GoogleFonts.poppins(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          await showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (context) {
                                              final sheetController = TextEditingController();
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Comments',
                                                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      if (item.comments.isEmpty)
                                                        const Text('No comments yet.')
                                                      else
                                                        ...item.comments.map(
                                                          (comment) => Padding(
                                                            padding: const EdgeInsets.only(bottom: 8),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(comment.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                                const SizedBox(height: 2),
                                                                Text(comment.text, style: GoogleFonts.poppins(fontSize: 12)),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextField(
                                                              controller: sheetController,
                                                              decoration: const InputDecoration(
                                                                hintText: 'Write Comment...',
                                                                border: OutlineInputBorder(),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          FilledButton(
                                                            onPressed: () {
                                                              _addComment(item, sheetController);
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: const Text('Post'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.comment_outlined, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Comment', style: GoogleFonts.poppins(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _addReminder(item),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.alarm_add_outlined, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Remind', style: GoogleFonts.poppins(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
