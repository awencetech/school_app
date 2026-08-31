class AnnouncementComment {
  AnnouncementComment({
    this.id,
    required this.name,
    required this.text,
    this.createdAt,
  });

  final String? id;
  final String name;
  final String text;
  final DateTime? createdAt;

  factory AnnouncementComment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        try {
          return DateTime.parse(value.toString().replaceAll('/', '-'));
        } catch (_) {
          return null;
        }
      }
    }

    return AnnouncementComment(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: (json['name'] ?? json['studentName'] ?? 'Student').toString().trim(),
      text: (json['text'] ?? json['comment'] ?? '').toString().trim(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'text': text,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class Announcement {
  Announcement({
    this.id,
    this.subject = '',
    this.fromName = '',
    List<String>? to,
    this.createdOn,
    this.content = '',
    List<String>? likes,
    List<AnnouncementComment>? comments,
    List<String>? reminders,
    this.createdAt,
    this.updatedAt,
  })  : to = to ?? const <String>[],
        likes = likes ?? const <String>[],
        comments = comments ?? const <AnnouncementComment>[],
        reminders = reminders ?? const <String>[];

  final String? id;
  final String subject;
  final String fromName;
  final List<String> to;
  final String? createdOn;
  final String content;
  final List<String> likes;
  final List<AnnouncementComment> comments;
  final List<String> reminders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        try {
          return DateTime.parse(value.toString().replaceAll('/', '-'));
        } catch (_) {
          return null;
        }
      }
    }

    final rawTo = json['to'];
    final rawLikes = json['likes'];
    final rawComments = json['comments'];
    final rawReminders = json['reminders'];

    return Announcement(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      subject: (json['subject'] ?? '').toString().trim(),
      fromName: (json['from'] ?? json['fromName'] ?? '').toString().trim(),
      to: rawTo is List
          ? rawTo.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
          : const <String>[],
      createdOn: (json['createdOn'] ?? '').toString().trim(),
      content: (json['content'] ?? '').toString().trim(),
      likes: rawLikes is List
          ? rawLikes.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
          : const <String>[],
      comments: rawComments is List
          ? rawComments
              .whereType<Map>()
              .map((item) => AnnouncementComment.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const <AnnouncementComment>[],
      reminders: rawReminders is List
          ? rawReminders.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
          : const <String>[],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'from': fromName,
        'to': to,
        'createdOn': createdOn,
        'content': content,
        'likes': likes,
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'reminders': reminders,
      };
}
