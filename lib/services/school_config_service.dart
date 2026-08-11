import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/main_page_info.dart';
import '../models/management_member.dart';
import '../models/news_item.dart';
import '../models/sports_achievement_entry.dart';
import '../models/topper_entry.dart';
import 'main_page_info_repository.dart';
import 'preferences_service.dart';

class SchoolConfigService extends ChangeNotifier {
  static const _nameKey = 'school_name';
  static const _quoteKey = 'school_quote';
  static const _welcomeKey = 'school_welcome';
  static const _websiteKey = 'school_website_url';
  static const _runningItemsKey = 'school_running_items';
  static const _posterKey = 'school_poster_base64';
  static const _mottoKey = 'school_motto';
  static const _sinceYearKey = 'school_since_year';
  static const _logoKey = 'school_logo_base64';
  static const _bannerKey = 'school_banner_base64';
  static const _gradePageBannerKey = 'grade_page_banner_base64';
  static const _founderPhotoKey = 'founder_photo_base64';
  static const _founderNameKey = 'founder_name';
  static const _founderDesignationKey = 'founder_designation';
  static const _founderVisionTitleKey = 'founder_vision_title';
  static const _founderVisionDescKey = 'founder_vision_description';
  static const _secretaryPhotoKey = 'secretary_photo_base64';
  static const _secretaryNameKey = 'secretary_name';
  static const _secretaryDesignationKey = 'secretary_designation';
  static const _secretaryWelcomeTitleKey = 'secretary_welcome_title';
  static const _secretaryWelcomeMessageKey = 'secretary_welcome_message';
  static const _headmasterPhotoKey = 'headmaster_photo_base64';
  static const _headmasterNameKey = 'headmaster_name';
  static const _headmasterDesignationKey = 'headmaster_designation';
  static const _headmasterMessageTitleKey = 'headmaster_message_title';
  static const _headmasterMessageKey = 'headmaster_message';
  static const _managementMembersKey = 'management_members';
  static const _importantNewsKey = 'important_news';
  static const _sportsAchievementsKey = 'sports_achievements';
  static const _gradeXKey = 'grade_x_toppers';
  static const _gradeXIIKey = 'grade_xii_toppers';
  static const _addressKey = 'school_address';
  static const _phoneKey = 'school_phone';
  static const _alternatePhoneKey = 'school_alternate_phone';
  static const _emailKey = 'school_email';
  static const _googleMapKey = 'school_google_map';
  static const _facebookKey = 'school_facebook';
  static const _instagramKey = 'school_instagram';
  static const _youtubeKey = 'school_youtube';
  static const _twitterKey = 'school_twitter';
  static const _linkedInKey = 'school_linkedin';

  final MainPageInfoRepository _repository = MainPageInfoRepository();

  MainPageInfoRepository get repository => _repository;

  String schoolName = 'SCHOOL NAME';
  String quote =
      'Every student has the potential to achieve greatness through dedication, discipline, and continuous learning.';
  String _welcome = '';
  String websiteUrl = '';
  String schoolMotto = '';
  String sinceYear = '';
  String? logoBase64;
  String? bannerBase64;
  String? gradePageBannerBase64;
  String? founderPhotoBase64;
  String founderName = '';
  String founderDesignation = '';
  String founderVisionTitle = '';
  String founderVisionDescription = '';
  String? secretaryPhotoBase64;
  String secretaryName = '';
  String secretaryDesignation = '';
  String secretaryWelcomeTitle = '';
  String secretaryWelcomeMessage = '';
  String? headmasterPhotoBase64;
  String headmasterName = '';
  String headmasterDesignation = '';
  String headmasterMessageTitle = '';
  String headmasterMessage = '';
  List<ManagementMember> managementMembers = [];
  List<NewsItem> importantNews = [];
  List<SportsAchievementEntry> sportsAchievements = [];
  List<TopperEntry> gradeXTopper = [];
  List<TopperEntry> gradeXIITopper = [];
  String address = '';
  String phoneNumber = '';
  String alternatePhone = '';
  String contactEmail = '';
  String googleMapLink = '';
  String facebookUrl = '';
  String instagramUrl = '';
  String youtubeUrl = '';
  String twitterUrl = '';
  String linkedInUrl = '';
  List<String> runningItems = const [
    'Sports Day Registrations Open',
    'Admissions Open for 2026–27',
    'Quarterly Exams Start on August 15',
    'Parent–Teacher Meeting on Friday',
    'Independence Day Celebration on August 15',
  ];
  String? posterBase64;
  String? posterUrl;

  SchoolConfigService() {
    _load();
  }

  String get welcome => _welcome.isNotEmpty ? _welcome : 'Welcome To $schoolName';

  String? get posterDisplaySource => posterUrl ?? posterBase64;

  Future<void> _refreshPosterFromServer() async {
    try {
      final saved = await _repository.getMainPageInfo();
      final remotePoster = saved.schoolSettings.schoolPoster.trim();
      if (remotePoster.isNotEmpty) {
        posterUrl = remotePoster;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, remotePoster);
      } else {
        posterUrl = null;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, '');
      }
    } catch (_) {
      // Keep the locally cached value if the backend is temporarily unavailable.
    }
  }

  Future<void> _load() async {
    final name = await PreferencesService.getString(_nameKey);
    final quoteValue = await PreferencesService.getString(_quoteKey);
    final welcomeValue = await PreferencesService.getString(_welcomeKey);
    final websiteValue = await PreferencesService.getString(_websiteKey);
    final runningJson = await PreferencesService.getString(_runningItemsKey);
    final poster = await PreferencesService.getString(_posterKey);
    final mottoValue = await PreferencesService.getString(_mottoKey);
    final sinceValue = await PreferencesService.getString(_sinceYearKey);
    final logo = await PreferencesService.getString(_logoKey);
    final banner = await PreferencesService.getString(_bannerKey);
    final gradePageBanner = await PreferencesService.getString(_gradePageBannerKey);
    final founderPhoto = await PreferencesService.getString(_founderPhotoKey);
    final founderNameValue = await PreferencesService.getString(_founderNameKey);
    final founderDesignationValue = await PreferencesService.getString(_founderDesignationKey);
    final founderVisionTitleValue = await PreferencesService.getString(_founderVisionTitleKey);
    final founderVisionDescValue = await PreferencesService.getString(_founderVisionDescKey);
    final secretaryPhoto = await PreferencesService.getString(_secretaryPhotoKey);
    final secretaryNameValue = await PreferencesService.getString(_secretaryNameKey);
    final secretaryDesignationValue = await PreferencesService.getString(_secretaryDesignationKey);
    final secretaryWelcomeTitleValue = await PreferencesService.getString(_secretaryWelcomeTitleKey);
    final secretaryWelcomeMessageValue = await PreferencesService.getString(_secretaryWelcomeMessageKey);
    final headmasterPhoto = await PreferencesService.getString(_headmasterPhotoKey);
    final headmasterNameValue = await PreferencesService.getString(_headmasterNameKey);
    final headmasterDesignationValue = await PreferencesService.getString(_headmasterDesignationKey);
    final headmasterMessageTitleValue = await PreferencesService.getString(_headmasterMessageTitleKey);
    final headmasterMessageValue = await PreferencesService.getString(_headmasterMessageKey);
    final managementMembersJson = await PreferencesService.getString(_managementMembersKey);
    final importantNewsJson = await PreferencesService.getString(_importantNewsKey);
    final sportsJson = await PreferencesService.getString(_sportsAchievementsKey);
    final gradeXJson = await PreferencesService.getString(_gradeXKey);
    final gradeXIIJson = await PreferencesService.getString(_gradeXIIKey);
    final addressValue = await PreferencesService.getString(_addressKey);
    final phoneValue = await PreferencesService.getString(_phoneKey);
    final alternatePhoneValue = await PreferencesService.getString(_alternatePhoneKey);
    final emailValue = await PreferencesService.getString(_emailKey);
    final googleMapValue = await PreferencesService.getString(_googleMapKey);
    final facebookValue = await PreferencesService.getString(_facebookKey);
    final instagramValue = await PreferencesService.getString(_instagramKey);
    final youtubeValue = await PreferencesService.getString(_youtubeKey);
    final twitterValue = await PreferencesService.getString(_twitterKey);
    final linkedInValue = await PreferencesService.getString(_linkedInKey);

    if (name != null && name.isNotEmpty) schoolName = name;
    if (quoteValue != null && quoteValue.isNotEmpty) quote = quoteValue;
    if (welcomeValue != null) _welcome = welcomeValue;
    if (websiteValue != null && websiteValue.isNotEmpty) websiteUrl = websiteValue;
    if (mottoValue != null && mottoValue.isNotEmpty) schoolMotto = mottoValue;
    if (sinceValue != null && sinceValue.isNotEmpty) sinceYear = sinceValue;
    if (logo != null && logo.isNotEmpty) logoBase64 = logo;
    if (banner != null && banner.isNotEmpty) bannerBase64 = banner;
    if (gradePageBanner != null && gradePageBanner.isNotEmpty) gradePageBannerBase64 = gradePageBanner;
    if (founderPhoto != null && founderPhoto.isNotEmpty) founderPhotoBase64 = founderPhoto;
    if (founderNameValue != null && founderNameValue.isNotEmpty) founderName = founderNameValue;
    if (founderDesignationValue != null && founderDesignationValue.isNotEmpty) founderDesignation = founderDesignationValue;
    if (founderVisionTitleValue != null && founderVisionTitleValue.isNotEmpty) founderVisionTitle = founderVisionTitleValue;
    if (founderVisionDescValue != null && founderVisionDescValue.isNotEmpty) founderVisionDescription = founderVisionDescValue;
    if (secretaryPhoto != null && secretaryPhoto.isNotEmpty) secretaryPhotoBase64 = secretaryPhoto;
    if (secretaryNameValue != null && secretaryNameValue.isNotEmpty) secretaryName = secretaryNameValue;
    if (secretaryDesignationValue != null && secretaryDesignationValue.isNotEmpty) secretaryDesignation = secretaryDesignationValue;
    if (secretaryWelcomeTitleValue != null && secretaryWelcomeTitleValue.isNotEmpty) secretaryWelcomeTitle = secretaryWelcomeTitleValue;
    if (secretaryWelcomeMessageValue != null && secretaryWelcomeMessageValue.isNotEmpty) secretaryWelcomeMessage = secretaryWelcomeMessageValue;
    if (headmasterPhoto != null && headmasterPhoto.isNotEmpty) headmasterPhotoBase64 = headmasterPhoto;
    if (headmasterNameValue != null && headmasterNameValue.isNotEmpty) headmasterName = headmasterNameValue;
    if (headmasterDesignationValue != null && headmasterDesignationValue.isNotEmpty) headmasterDesignation = headmasterDesignationValue;
    if (headmasterMessageTitleValue != null && headmasterMessageTitleValue.isNotEmpty) headmasterMessageTitle = headmasterMessageTitleValue;
    if (headmasterMessageValue != null && headmasterMessageValue.isNotEmpty) headmasterMessage = headmasterMessageValue;
    if (managementMembersJson != null && managementMembersJson.isNotEmpty) {
      managementMembers = _decodeMembers(managementMembersJson);
    }
    if (importantNewsJson != null && importantNewsJson.isNotEmpty) {
      importantNews = _decodeNews(importantNewsJson);
    }
    if (sportsJson != null && sportsJson.isNotEmpty) {
      sportsAchievements = _decodeSports(sportsJson);
    }
    if (gradeXJson != null && gradeXJson.isNotEmpty) {
      gradeXTopper = _decodeToppers(gradeXJson);
    }
    if (gradeXIIJson != null && gradeXIIJson.isNotEmpty) {
      gradeXIITopper = _decodeToppers(gradeXIIJson);
    }
    if (addressValue != null && addressValue.isNotEmpty) address = addressValue;
    if (phoneValue != null && phoneValue.isNotEmpty) phoneNumber = phoneValue;
    if (alternatePhoneValue != null && alternatePhoneValue.isNotEmpty) alternatePhone = alternatePhoneValue;
    if (emailValue != null && emailValue.isNotEmpty) contactEmail = emailValue;
    if (googleMapValue != null && googleMapValue.isNotEmpty) googleMapLink = googleMapValue;
    if (facebookValue != null && facebookValue.isNotEmpty) facebookUrl = facebookValue;
    if (instagramValue != null && instagramValue.isNotEmpty) instagramUrl = instagramValue;
    if (youtubeValue != null && youtubeValue.isNotEmpty) youtubeUrl = youtubeValue;
    if (twitterValue != null && twitterValue.isNotEmpty) twitterUrl = twitterValue;
    if (linkedInValue != null && linkedInValue.isNotEmpty) linkedInUrl = linkedInValue;
    if (runningJson != null && runningJson.isNotEmpty) {
      try {
        final list = jsonDecode(runningJson) as List<dynamic>;
        runningItems = list.map((e) => e.toString()).toList(growable: false);
      } catch (_) {}
    }
    posterBase64 = poster != null && poster.isNotEmpty ? poster : null;

    try {
      final saved = await _repository.getMainPageInfo();
      schoolName = saved.schoolSettings.schoolName.isNotEmpty ? saved.schoolSettings.schoolName : schoolName;
      if (saved.schoolSettings.schoolQuote.isNotEmpty) {
        quote = saved.schoolSettings.schoolQuote;
      }
      if (saved.schoolSettings.welcomeText.isNotEmpty) {
        _welcome = saved.schoolSettings.welcomeText;
      }
      if (saved.schoolSettings.schoolWebsite.isNotEmpty) {
        websiteUrl = saved.schoolSettings.schoolWebsite;
      }
      if (saved.schoolSettings.runningContent.isNotEmpty) {
        runningItems = List<String>.from(saved.schoolSettings.runningContent);
      }
      if (saved.schoolSettings.schoolPoster.isNotEmpty) {
        posterUrl = saved.schoolSettings.schoolPoster;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, saved.schoolSettings.schoolPoster);
        print('Loaded school poster URL: $posterUrl');
      } else {
        posterUrl = null;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, '');
      }
      if (saved.schoolContent.founder.name.isNotEmpty) founderName = saved.schoolContent.founder.name;
      if (saved.schoolContent.secretary.name.isNotEmpty) secretaryName = saved.schoolContent.secretary.name;
      if (saved.schoolContent.headmaster.name.isNotEmpty) headmasterName = saved.schoolContent.headmaster.name;
      if (saved.schoolContent.members.isNotEmpty) {
        managementMembers = saved.schoolContent.members
            .map((member) => ManagementMember(
                  photoBase64: member.photo,
                  name: member.name,
                  designation: member.designation,
                  title: member.title,
                  description: member.description,
                ))
            .toList();
      }
      if (saved.gradePage.grade10.students.isNotEmpty) {
        gradeXTopper = saved.gradePage.grade10.students
            .map((student) => TopperEntry(
                  photoBase64: student.photo,
                  studentName: student.studentName,
                  marks: student.marks,
                  imageFit: student.imageFit,
                  cropData: student.cropData,
                ))
            .toList();
      }
      if (saved.gradePage.grade12.students.isNotEmpty) {
        gradeXIITopper = saved.gradePage.grade12.students
            .map((student) => TopperEntry(
                  photoBase64: student.photo,
                  studentName: student.studentName,
                  marks: student.marks,
                  imageFit: student.imageFit,
                  cropData: student.cropData,
                ))
            .toList();
      }
      if (saved.gradePage.sportsAchievements.isNotEmpty) {
        sportsAchievements = saved.gradePage.sportsAchievements
            .map((achievement) => SportsAchievementEntry(
                  imageBase64: achievement.image,
                  studentName: achievement.studentName,
                  achievementTitle: '',
                  description: achievement.achievementDescription,
                ))
            .toList();
      }
    } catch (_) {
      // The cached values remain the safe fallback when the API is unavailable.
    }

    notifyListeners();
  }

  List<ManagementMember> _decodeMembers(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => ManagementMember.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  List<NewsItem> _decodeNews(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  List<SportsAchievementEntry> _decodeSports(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => SportsAchievementEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<TopperEntry> _decodeToppers(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => TopperEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> save({
    String? schoolName,
    String? quote,
    String? welcome,
    String? website,
    String? schoolMotto,
    String? sinceYear,
    String? logoBase64,
    bool clearLogo = false,
    String? bannerBase64,
    bool clearBanner = false,
    String? founderPhotoBase64,
    bool clearFounderPhoto = false,
    String? founderName,
    String? founderDesignation,
    String? founderVisionTitle,
    String? founderVisionDescription,
    String? secretaryPhotoBase64,
    bool clearSecretaryPhoto = false,
    String? secretaryName,
    String? secretaryDesignation,
    String? secretaryWelcomeTitle,
    String? secretaryWelcomeMessage,
    String? headmasterPhotoBase64,
    bool clearHeadmasterPhoto = false,
    String? headmasterName,
    String? headmasterDesignation,
    String? headmasterMessageTitle,
    String? headmasterMessage,
    List<ManagementMember>? managementMembers,
    List<NewsItem>? importantNews,
    List<SportsAchievementEntry>? sportsAchievements,
    List<TopperEntry>? gradeXTopper,
    List<TopperEntry>? gradeXIITopper,
    String? address,
    String? phone,
    String? alternatePhone,
    String? email,
    String? googleMapLink,
    String? facebook,
    String? instagram,
    String? youtube,
    String? twitter,
    String? linkedIn,
    List<String>? runningItems,
    String? posterBase64,
    String? posterUrl,
    bool clearPoster = false,
    String? gradePageBannerBase64,
    bool clearGradePageBanner = false,
  }) async {
    if (schoolName != null) {
      this.schoolName = schoolName;
      await PreferencesService.setString(_nameKey, schoolName);
    }
    if (quote != null) {
      this.quote = quote;
      await PreferencesService.setString(_quoteKey, quote);
    }
    if (welcome != null) {
      _welcome = welcome;
      await PreferencesService.setString(_welcomeKey, welcome);
    }
    if (website != null) {
      websiteUrl = website;
      await PreferencesService.setString(_websiteKey, website);
    }
    if (schoolMotto != null) {
      this.schoolMotto = schoolMotto;
      await PreferencesService.setString(_mottoKey, schoolMotto);
    }
    if (sinceYear != null) {
      this.sinceYear = sinceYear;
      await PreferencesService.setString(_sinceYearKey, sinceYear);
    }
    if (clearLogo) {
      logoBase64 = null;
      this.logoBase64 = null;
      await PreferencesService.setString(_logoKey, '');
    } else if (logoBase64 != null) {
      this.logoBase64 = logoBase64;
      await PreferencesService.setString(_logoKey, logoBase64);
    }
    if (clearBanner) {
      bannerBase64 = null;
      this.bannerBase64 = null;
      await PreferencesService.setString(_bannerKey, '');
    } else if (bannerBase64 != null) {
      this.bannerBase64 = bannerBase64;
      await PreferencesService.setString(_bannerKey, bannerBase64);
    }
    if (clearGradePageBanner) {
      gradePageBannerBase64 = null;
      this.gradePageBannerBase64 = null;
      await PreferencesService.setString(_gradePageBannerKey, '');
    } else if (gradePageBannerBase64 != null) {
      this.gradePageBannerBase64 = gradePageBannerBase64;
      await PreferencesService.setString(_gradePageBannerKey, gradePageBannerBase64);
    }
    if (clearFounderPhoto) {
      founderPhotoBase64 = null;
      this.founderPhotoBase64 = null;
      await PreferencesService.setString(_founderPhotoKey, '');
    } else if (founderPhotoBase64 != null) {
      this.founderPhotoBase64 = founderPhotoBase64;
      await PreferencesService.setString(_founderPhotoKey, founderPhotoBase64);
    }
    if (founderName != null) {
      this.founderName = founderName;
      await PreferencesService.setString(_founderNameKey, founderName);
    }
    if (founderDesignation != null) {
      this.founderDesignation = founderDesignation;
      await PreferencesService.setString(_founderDesignationKey, founderDesignation);
    }
    if (founderVisionTitle != null) {
      this.founderVisionTitle = founderVisionTitle;
      await PreferencesService.setString(_founderVisionTitleKey, founderVisionTitle);
    }
    if (founderVisionDescription != null) {
      this.founderVisionDescription = founderVisionDescription;
      await PreferencesService.setString(_founderVisionDescKey, founderVisionDescription);
    }
    if (clearSecretaryPhoto) {
      secretaryPhotoBase64 = null;
      this.secretaryPhotoBase64 = null;
      await PreferencesService.setString(_secretaryPhotoKey, '');
    } else if (secretaryPhotoBase64 != null) {
      this.secretaryPhotoBase64 = secretaryPhotoBase64;
      await PreferencesService.setString(_secretaryPhotoKey, secretaryPhotoBase64);
    }
    if (secretaryName != null) {
      this.secretaryName = secretaryName;
      await PreferencesService.setString(_secretaryNameKey, secretaryName);
    }
    if (secretaryDesignation != null) {
      this.secretaryDesignation = secretaryDesignation;
      await PreferencesService.setString(_secretaryDesignationKey, secretaryDesignation);
    }
    if (secretaryWelcomeTitle != null) {
      this.secretaryWelcomeTitle = secretaryWelcomeTitle;
      await PreferencesService.setString(_secretaryWelcomeTitleKey, secretaryWelcomeTitle);
    }
    if (secretaryWelcomeMessage != null) {
      this.secretaryWelcomeMessage = secretaryWelcomeMessage;
      await PreferencesService.setString(_secretaryWelcomeMessageKey, secretaryWelcomeMessage);
    }
    if (clearHeadmasterPhoto) {
      headmasterPhotoBase64 = null;
      this.headmasterPhotoBase64 = null;
      await PreferencesService.setString(_headmasterPhotoKey, '');
    } else if (headmasterPhotoBase64 != null) {
      this.headmasterPhotoBase64 = headmasterPhotoBase64;
      await PreferencesService.setString(_headmasterPhotoKey, headmasterPhotoBase64);
    }
    if (headmasterName != null) {
      this.headmasterName = headmasterName;
      await PreferencesService.setString(_headmasterNameKey, headmasterName);
    }
    if (headmasterDesignation != null) {
      this.headmasterDesignation = headmasterDesignation;
      await PreferencesService.setString(_headmasterDesignationKey, headmasterDesignation);
    }
    if (headmasterMessageTitle != null) {
      this.headmasterMessageTitle = headmasterMessageTitle;
      await PreferencesService.setString(_headmasterMessageTitleKey, headmasterMessageTitle);
    }
    if (headmasterMessage != null) {
      this.headmasterMessage = headmasterMessage;
      await PreferencesService.setString(_headmasterMessageKey, headmasterMessage);
    }
    if (managementMembers != null) {
      this.managementMembers = List<ManagementMember>.from(managementMembers);
      await PreferencesService.setString(_managementMembersKey,
          jsonEncode(managementMembers.map((e) => e.toJson()).toList()));
    }
    if (importantNews != null) {
      this.importantNews = List<NewsItem>.from(importantNews);
      await PreferencesService.setString(_importantNewsKey,
          jsonEncode(importantNews.map((e) => {'title': e.title, 'description': e.description}).toList()));
    }
    if (sportsAchievements != null) {
      this.sportsAchievements = List<SportsAchievementEntry>.from(sportsAchievements);
      await PreferencesService.setString(_sportsAchievementsKey,
          jsonEncode(sportsAchievements.map((e) => e.toJson()).toList()));
    }
    if (gradeXTopper != null) {
      this.gradeXTopper = List<TopperEntry>.from(gradeXTopper);
      await PreferencesService.setString(_gradeXKey,
          jsonEncode(gradeXTopper.map((e) => e.toJson()).toList()));
    }
    if (gradeXIITopper != null) {
      this.gradeXIITopper = List<TopperEntry>.from(gradeXIITopper);
      await PreferencesService.setString(_gradeXIIKey,
          jsonEncode(gradeXIITopper.map((e) => e.toJson()).toList()));
    }
    if (address != null) {
      this.address = address;
      await PreferencesService.setString(_addressKey, address);
    }
    if (phone != null) {
      phoneNumber = phone;
      await PreferencesService.setString(_phoneKey, phone);
    }
    if (alternatePhone != null) {
      this.alternatePhone = alternatePhone;
      await PreferencesService.setString(_alternatePhoneKey, alternatePhone);
    }
    if (email != null) {
      contactEmail = email;
      await PreferencesService.setString(_emailKey, email);
    }
    if (googleMapLink != null) {
      this.googleMapLink = googleMapLink;
      await PreferencesService.setString(_googleMapKey, googleMapLink);
    }
    if (facebook != null) {
      facebookUrl = facebook;
      await PreferencesService.setString(_facebookKey, facebook);
    }
    if (instagram != null) {
      instagramUrl = instagram;
      await PreferencesService.setString(_instagramKey, instagram);
    }
    if (youtube != null) {
      youtubeUrl = youtube;
      await PreferencesService.setString(_youtubeKey, youtube);
    }
    if (twitter != null) {
      twitterUrl = twitter;
      await PreferencesService.setString(_twitterKey, twitter);
    }
    if (linkedIn != null) {
      linkedInUrl = linkedIn;
      await PreferencesService.setString(_linkedInKey, linkedIn);
    }
    if (runningItems != null) {
      this.runningItems = List<String>.from(runningItems);
      await PreferencesService.setString(_runningItemsKey, jsonEncode(runningItems));
    }
    if (clearPoster) {
      posterUrl = null;
      posterBase64 = null;
      this.posterUrl = null;
      this.posterBase64 = null;
      await PreferencesService.setString(_posterKey, '');
    } else if (posterUrl != null) {
      this.posterUrl = posterUrl;
      this.posterBase64 = null;
      await PreferencesService.setString(_posterKey, posterUrl);
    } else if (posterBase64 != null) {
      this.posterBase64 = posterBase64;
      this.posterUrl = null;
      await PreferencesService.setString(_posterKey, posterBase64);
    }

    try {
      final payload = MainPageInfo(
        schoolSettings: SchoolSettingsModel(
          schoolName: this.schoolName,
          schoolLogo: this.logoBase64 ?? '',
          schoolPoster: this.posterUrl ?? this.posterBase64 ?? '',
          selectedLanguage: '',
          themeColor: '',
          schoolQuote: this.quote,
          welcomeText: this._welcome,
          schoolWebsite: this.websiteUrl,
          runningContent: this.runningItems,
        ),
        schoolContent: SchoolContentModel(
          founder: FounderModel(
            photo: this.founderPhotoBase64 ?? '',
            name: this.founderName,
            designation: this.founderDesignation,
            visionTitle: this.founderVisionTitle,
            visionDescription: this.founderVisionDescription,
          ),
          secretary: SecretaryModel(
            photo: this.secretaryPhotoBase64 ?? '',
            name: this.secretaryName,
            designation: this.secretaryDesignation,
            welcomeTitle: this.secretaryWelcomeTitle,
            welcomeMessage: this.secretaryWelcomeMessage,
          ),
          headmaster: HeadmasterModel(
            photo: this.headmasterPhotoBase64 ?? '',
            name: this.headmasterName,
            designation: this.headmasterDesignation,
            messageTitle: this.headmasterMessageTitle,
            message: this.headmasterMessage,
          ),
          members: this.managementMembers
              .map((member) => ManagementMemberModel(
                    id: member.name,
                    photo: member.photoBase64,
                    name: member.name,
                    designation: member.designation,
                    title: member.title,
                    description: member.description,
                    order: 0,
                  ))
              .toList(),
        ),
        gradePage: GradePageModel(
          grade10: GradeStudentGroupModel(
            students: this.gradeXTopper
                .map((student) => StudentModel(
                      photo: student.photoBase64,
                      studentName: student.studentName,
                      marks: student.marks,
                      imageFit: student.imageFit,
                      cropData: student.cropData,
                    ))
                .toList(),
          ),
          grade12: GradeStudentGroupModel(
            students: this.gradeXIITopper
                .map((student) => StudentModel(
                      photo: student.photoBase64,
                      studentName: student.studentName,
                      marks: student.marks,
                      imageFit: student.imageFit,
                      cropData: student.cropData,
                    ))
                .toList(),
          ),
          sportsAchievements: this.sportsAchievements
              .map((achievement) => SportsAchievementModel(
                    image: achievement.imageBase64,
                    studentName: achievement.studentName,
                    achievementDescription: achievement.description,
                  ))
              .toList(),
        ),
      );

      final updated = await _repository.updateMainPageInfo(payload);
      if (updated.schoolSettings.schoolPoster.isNotEmpty) {
        posterUrl = updated.schoolSettings.schoolPoster;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, updated.schoolSettings.schoolPoster);
      } else {
        posterUrl = null;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, '');
      }
      notifyListeners();
      return true;
    } catch (_) {
      notifyListeners();
      return false;
    }
  }
}
