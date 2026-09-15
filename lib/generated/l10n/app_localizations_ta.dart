// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get selectPreferredLanguage =>
      'உங்களுக்கு விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get schoolPoster => 'பள்ளி சுவரொட்டி';

  @override
  String get continueText => 'தொடரவும்';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get delete => 'நீக்கு';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get ok => 'சரி';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get noDataAvailable => 'தரவு எதுவும் இல்லை';

  @override
  String get noNewsAvailable => 'செய்திகள் எதுவும் இல்லை';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு ஏற்பட்டது';

  @override
  String get pleaseTryAgain => 'மீண்டும் முயற்சி செய்யவும்';

  @override
  String get requiredField => 'இந்தப் புலம் தேவை';

  @override
  String get invalidEmail => 'தவறான மின்னஞ்சல்';

  @override
  String get passwordRequired => 'கடவுச்சொல் தேவை';

  @override
  String get areYouSure => 'நிச்சயமாகவா?';

  @override
  String get deleteQuestion => 'இதை நீக்க வேண்டுமா?';

  @override
  String get home => 'முகப்பு';

  @override
  String get school => 'பள்ளி';

  @override
  String get dashboard => 'டாஷ்போர்டு';

  @override
  String get support => 'ஆதரவு';

  @override
  String get login => 'உள்நுழை';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get user => 'பயனர்';

  @override
  String get help => 'உதவி';

  @override
  String get quickMenu => 'விரைவு மெனு';

  @override
  String get username => 'பயனர் பெயர்';

  @override
  String marks(Object marks) {
    return 'மதிப்பெண்கள்: $marks';
  }

  @override
  String get schoolName => 'பள்ளி பெயர்';

  @override
  String get usernameOrEmail => 'பயனர் பெயர் அல்லது மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get forgotPassword => 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?';

  @override
  String get signingIn => 'உள்நுழைகிறது...';

  @override
  String get signIn => 'உள்நுழை';

  @override
  String get register => 'பதிவு செய்க';

  @override
  String get accountRegisterPrompt => 'கணக்கு இல்லையா? பதிவு செய்க';

  @override
  String get registrationInfo =>
      'பதிவு பற்றிய தகவலுக்கு பள்ளியைத் தொடர்பு கொள்ளவும்';

  @override
  String get invalidUserRole => 'தவறான பயனர் வகை';

  @override
  String get invalidCredentials => 'தவறான பயனர் பெயர் அல்லது கடவுச்சொல்';

  @override
  String get connectionError =>
      'இணைப்பு பிழை. உங்கள் இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சி செய்யவும்.';

  @override
  String get updateUserProfile => 'பயனர் சுயவிவரத்தை\nபுதுப்பிக்கவும்';

  @override
  String get changePassword => 'கடவுச்சொல்லை\nமாற்றவும்';
}
