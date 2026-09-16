import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred Language'**
  String get selectPreferredLanguage;

  /// No description provided for @schoolPoster.
  ///
  /// In en, this message translates to:
  /// **'School Poster'**
  String get schoolPoster;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Data available'**
  String get noDataAvailable;

  /// No description provided for @noNewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No news available'**
  String get noNewsAvailable;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get deleteQuestion;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @quickMenu.
  ///
  /// In en, this message translates to:
  /// **'Quick Menu'**
  String get quickMenu;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks: {marks}'**
  String marks(Object marks);

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School name'**
  String get schoolName;

  /// No description provided for @usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get usernameOrEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @accountRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get accountRegisterPrompt;

  /// No description provided for @registrationInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact our school to get information about registration'**
  String get registrationInfo;

  /// No description provided for @invalidUserRole.
  ///
  /// In en, this message translates to:
  /// **'Invalid user role'**
  String get invalidUserRole;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet and try again.'**
  String get connectionError;

  /// No description provided for @updateUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Update User\nProfile'**
  String get updateUserProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change\nPassword'**
  String get changePassword;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcome(Object name);

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @quickAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Access frequently used features quickly'**
  String get quickAccessDescription;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @dashboardSummary.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Summary'**
  String get dashboardSummary;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write Message'**
  String get writeMessage;

  /// No description provided for @pta.
  ///
  /// In en, this message translates to:
  /// **'PTA'**
  String get pta;

  /// No description provided for @groupsClassBus.
  ///
  /// In en, this message translates to:
  /// **'Groups/Class Bus'**
  String get groupsClassBus;

  /// No description provided for @checkApprove.
  ///
  /// In en, this message translates to:
  /// **'Check Approve'**
  String get checkApprove;

  /// No description provided for @trackUniRoute.
  ///
  /// In en, this message translates to:
  /// **'Track UNI Route 42'**
  String get trackUniRoute;

  /// No description provided for @track57.
  ///
  /// In en, this message translates to:
  /// **'Track 57'**
  String get track57;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @knowYourSchool.
  ///
  /// In en, this message translates to:
  /// **'Know your School'**
  String get knowYourSchool;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @schoolHandbook.
  ///
  /// In en, this message translates to:
  /// **'School Handbook'**
  String get schoolHandbook;

  /// No description provided for @eventsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Events Calendar'**
  String get eventsCalendar;

  /// No description provided for @schoolResources.
  ///
  /// In en, this message translates to:
  /// **'School Res.'**
  String get schoolResources;

  /// No description provided for @newsletter.
  ///
  /// In en, this message translates to:
  /// **'Newsletter'**
  String get newsletter;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @demography.
  ///
  /// In en, this message translates to:
  /// **'Demography'**
  String get demography;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @otherMenu.
  ///
  /// In en, this message translates to:
  /// **'Other\nMenu'**
  String get otherMenu;

  /// No description provided for @listStudents.
  ///
  /// In en, this message translates to:
  /// **'List\nStudents'**
  String get listStudents;

  /// No description provided for @listTeachers.
  ///
  /// In en, this message translates to:
  /// **'List\nTeachers'**
  String get listTeachers;

  /// No description provided for @listClasses.
  ///
  /// In en, this message translates to:
  /// **'List\nClasses'**
  String get listClasses;

  /// No description provided for @listOtherGroups.
  ///
  /// In en, this message translates to:
  /// **'List Other\nGroups'**
  String get listOtherGroups;

  /// No description provided for @write.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get write;

  /// No description provided for @schoolNews.
  ///
  /// In en, this message translates to:
  /// **'School\nNews'**
  String get schoolNews;

  /// No description provided for @medicalEventList.
  ///
  /// In en, this message translates to:
  /// **'Medical Event\nList'**
  String get medicalEventList;

  /// No description provided for @trackBusGps.
  ///
  /// In en, this message translates to:
  /// **'Track Bus\nGPS'**
  String get trackBusGps;

  /// No description provided for @employeeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Employee\nAttendance'**
  String get employeeAttendance;

  /// No description provided for @employeeLeaveApproval.
  ///
  /// In en, this message translates to:
  /// **'Emp Leave\nApproval'**
  String get employeeLeaveApproval;

  /// No description provided for @oneOnOne.
  ///
  /// In en, this message translates to:
  /// **'One on\nOne'**
  String get oneOnOne;

  /// No description provided for @schoolNameValue.
  ///
  /// In en, this message translates to:
  /// **'MMHSS'**
  String get schoolNameValue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
