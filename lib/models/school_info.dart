/// School branding information loaded from the configured school data.
class SchoolInfo {
  const SchoolInfo({
    required this.name,
    required this.since,
    required this.motto,
    required this.quote,
    required this.websiteUrl,
  });

  final String name;
  final String since;
  final String motto;
  final String quote;
  final String websiteUrl;

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      name: json['name'] as String? ?? '',
      since: json['since'] as String? ?? '',
      motto: json['motto'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      websiteUrl: json['websiteUrl'] as String? ?? '',
    );
  }
}
