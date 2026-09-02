import 'package:intl/intl.dart';

class SchoolNews {
  const SchoolNews({
    this.id,
    required this.title,
    required this.date,
    required this.news,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String title;
  final DateTime? date;
  final String news;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get formattedDate {
    if (date == null) {
      return '—';
    }
    return DateFormat('dd-MM-yyyy').format(date!);
  }

  factory SchoolNews.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final raw = value.toString();
      try {
        return DateTime.parse(raw);
      } catch (_) {
        try {
          final normalized = raw.replaceAll('/', '-');
          return DateTime.parse(normalized);
        } catch (_) {
          return null;
        }
      }
    }

    return SchoolNews(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: (json['title'] ?? '').toString().trim(),
      date: parseDate(json['date']),
      news: (json['news'] ?? '').toString().trim(),
      isPublished: json['isPublished'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date?.toIso8601String(),
        'news': news,
        'isPublished': isPublished,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  SchoolNews copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? news,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolNews(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      news: news ?? this.news,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
