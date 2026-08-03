/// Supported languages for the School App.
enum LanguageOption {
  tamil,
  english,
  hindi,
}

extension LanguageOptionX on LanguageOption {
  String get label => switch (this) {
        LanguageOption.tamil => 'தமிழ்',
        LanguageOption.english => 'English',
        LanguageOption.hindi => 'हिन्दी',
      };

  String get code => switch (this) {
        LanguageOption.tamil => 'ta',
        LanguageOption.english => 'en',
        LanguageOption.hindi => 'hi',
      };

  static LanguageOption? fromCode(String? code) => switch (code) {
        'ta' => LanguageOption.tamil,
        'en' => LanguageOption.english,
        'hi' => LanguageOption.hindi,
        _ => null,
      };
}

