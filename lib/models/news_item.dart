/// News item used for announcements and updates.
class NewsItem {
  const NewsItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

