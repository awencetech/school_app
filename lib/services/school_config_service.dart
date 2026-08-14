import 'dart:convert';
import 'dart:math';

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
  static const _homeContentKey = 'home_content';
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
  // Home-specific content items (editable from Content Edit). Kept separate
  // from managementMembers which represent school staff.
  List<ManagementMember> homeContent = [];
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
    final cached = await PreferencesService.getStrings([
      _nameKey,
      _quoteKey,
      _welcomeKey,
      _websiteKey,
      _runningItemsKey,
      _posterKey,
      _mottoKey,
      _sinceYearKey,
      _logoKey,
      _bannerKey,
      _gradePageBannerKey,
      _founderPhotoKey,
      _founderNameKey,
      _founderDesignationKey,
      _founderVisionTitleKey,
      _founderVisionDescKey,
      _secretaryPhotoKey,
      _secretaryNameKey,
      _secretaryDesignationKey,
      _secretaryWelcomeTitleKey,
      _secretaryWelcomeMessageKey,
      _headmasterPhotoKey,
      _headmasterNameKey,
      _headmasterDesignationKey,
      _headmasterMessageTitleKey,
      _headmasterMessageKey,
      _managementMembersKey,
      _importantNewsKey,
      _sportsAchievementsKey,
      _gradeXKey,
      _gradeXIIKey,
      _addressKey,
      _phoneKey,
      _alternatePhoneKey,
      _emailKey,
      _googleMapKey,
      _facebookKey,
      _instagramKey,
      _youtubeKey,
      _twitterKey,
      _linkedInKey,
    ]);

    final name = cached[_nameKey];
    final quoteValue = cached[_quoteKey];
    final welcomeValue = cached[_welcomeKey];
    final websiteValue = cached[_websiteKey];
    final runningJson = cached[_runningItemsKey];
    final poster = cached[_posterKey];
    final mottoValue = cached[_mottoKey];
    final sinceValue = cached[_sinceYearKey];
    final logo = cached[_logoKey];
    final banner = cached[_bannerKey];
    final gradePageBanner = cached[_gradePageBannerKey];
    final founderPhoto = cached[_founderPhotoKey];
    final founderNameValue = cached[_founderNameKey];
    final founderDesignationValue = cached[_founderDesignationKey];
    final founderVisionTitleValue = cached[_founderVisionTitleKey];
    final founderVisionDescValue = cached[_founderVisionDescKey];
    final secretaryPhoto = cached[_secretaryPhotoKey];
    final secretaryNameValue = cached[_secretaryNameKey];
    final secretaryDesignationValue = cached[_secretaryDesignationKey];
    final secretaryWelcomeTitleValue = cached[_secretaryWelcomeTitleKey];
    final secretaryWelcomeMessageValue = cached[_secretaryWelcomeMessageKey];
    final headmasterPhoto = cached[_headmasterPhotoKey];
    final headmasterNameValue = cached[_headmasterNameKey];
    final headmasterDesignationValue = cached[_headmasterDesignationKey];
    final headmasterMessageTitleValue = cached[_headmasterMessageTitleKey];
    final headmasterMessageValue = cached[_headmasterMessageKey];
    final managementMembersJson = cached[_managementMembersKey];
    final homeContentJson = cached[_homeContentKey];
    final importantNewsJson = cached[_importantNewsKey];
    final sportsJson = cached[_sportsAchievementsKey];
    final gradeXJson = cached[_gradeXKey];
    final gradeXIIJson = cached[_gradeXIIKey];
    final addressValue = cached[_addressKey];
    final phoneValue = cached[_phoneKey];
    final alternatePhoneValue = cached[_alternatePhoneKey];
    final emailValue = cached[_emailKey];
    final googleMapValue = cached[_googleMapKey];
    final facebookValue = cached[_facebookKey];
    final instagramValue = cached[_instagramKey];
    final youtubeValue = cached[_youtubeKey];
    final twitterValue = cached[_twitterKey];
    final linkedInValue = cached[_linkedInKey];

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
    if (homeContentJson != null && homeContentJson.isNotEmpty) {
      homeContent = _decodeMembers(homeContentJson);
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

    notifyListeners();

    try {
      final saved = await _repository.getMainPageInfo();

      // SERVER IS AUTHORITATIVE: apply server values and persist to SharedPreferences
      schoolName = saved.schoolSettings.schoolName ?? '';
      await PreferencesService.setString(_nameKey, schoolName);

      quote = saved.schoolSettings.schoolQuote ?? '';
      await PreferencesService.setString(_quoteKey, quote);

      _welcome = saved.schoolSettings.welcomeText ?? '';
      await PreferencesService.setString(_welcomeKey, _welcome);

      websiteUrl = saved.schoolSettings.schoolWebsite ?? '';
      await PreferencesService.setString(_websiteKey, websiteUrl);

      runningItems = (saved.schoolSettings.runningContent ?? []).map((e) => e.toString()).toList(growable: false);
      await PreferencesService.setString(_runningItemsKey, jsonEncode(runningItems));

      // Poster: accept empty string as authoritative too (clears cache)
      final remotePoster = saved.schoolSettings.schoolPoster ?? '';
      if (remotePoster.isNotEmpty) {
        posterUrl = remotePoster;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, remotePoster);
      } else {
        posterUrl = null;
        posterBase64 = null;
        await PreferencesService.setString(_posterKey, '');
      }

      // Founder / Secretary / Headmaster / Management members
      founderPhotoBase64 = saved.schoolContent.founder.photo ?? '';
      founderName = saved.schoolContent.founder.name ?? '';
      founderDesignation = saved.schoolContent.founder.designation ?? '';
      founderVisionTitle = saved.schoolContent.founder.visionTitle ?? '';
      founderVisionDescription = saved.schoolContent.founder.visionDescription ?? '';
      await PreferencesService.setString(_founderPhotoKey, founderPhotoBase64 ?? '');
      await PreferencesService.setString(_founderNameKey, founderName);
      await PreferencesService.setString(_founderDesignationKey, founderDesignation);
      await PreferencesService.setString(_founderVisionTitleKey, founderVisionTitle);
      await PreferencesService.setString(_founderVisionDescKey, founderVisionDescription);

      secretaryPhotoBase64 = saved.schoolContent.secretary.photo ?? '';
      secretaryName = saved.schoolContent.secretary.name ?? '';
      secretaryDesignation = saved.schoolContent.secretary.designation ?? '';
      secretaryWelcomeTitle = saved.schoolContent.secretary.welcomeTitle ?? '';
      secretaryWelcomeMessage = saved.schoolContent.secretary.welcomeMessage ?? '';
      await PreferencesService.setString(_secretaryPhotoKey, secretaryPhotoBase64 ?? '');
      await PreferencesService.setString(_secretaryNameKey, secretaryName);
      await PreferencesService.setString(_secretaryDesignationKey, secretaryDesignation);
      await PreferencesService.setString(_secretaryWelcomeTitleKey, secretaryWelcomeTitle);
      await PreferencesService.setString(_secretaryWelcomeMessageKey, secretaryWelcomeMessage);

      headmasterPhotoBase64 = saved.schoolContent.headmaster.photo ?? '';
      headmasterName = saved.schoolContent.headmaster.name ?? '';
      headmasterDesignation = saved.schoolContent.headmaster.designation ?? '';
      headmasterMessageTitle = saved.schoolContent.headmaster.messageTitle ?? '';
      headmasterMessage = saved.schoolContent.headmaster.message ?? '';
      await PreferencesService.setString(_headmasterPhotoKey, headmasterPhotoBase64 ?? '');
      await PreferencesService.setString(_headmasterNameKey, headmasterName);
      await PreferencesService.setString(_headmasterDesignationKey, headmasterDesignation);
      await PreferencesService.setString(_headmasterMessageTitleKey, headmasterMessageTitle);
      await PreferencesService.setString(_headmasterMessageKey, headmasterMessage);

      managementMembers = (saved.schoolContent.members ?? []).map((member) => ManagementMember(
        id: member.id ?? '',
        photoBase64: member.photo ?? '',
        name: member.name ?? '',
        designation: member.designation ?? '',
        title: member.title ?? '',
        description: member.description ?? '',
          )).toList();
      await PreferencesService.setString(_managementMembersKey, jsonEncode(managementMembers.map((e) => e.toJson()).toList()));

      // Home content (separate list). If backend provides homeContent, use it.
      homeContent = (saved.homeContent ?? []).map((raw) {
        final item = raw as dynamic;
        if (item is Map<String, dynamic>) {
          return ManagementMember(
            id: item['id']?.toString() ?? '',
            photoBase64: item['photo']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            designation: item['designation']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
          );
        }
        if (item is ManagementMemberModel) {
          return ManagementMember(
            id: item.id ?? '',
            photoBase64: item.photo ?? '',
            name: item.name ?? '',
            designation: item.designation ?? '',
            title: item.title ?? '',
            description: item.description ?? '',
          );
        }
        try {
          final s = item?.toString() ?? '';
          return ManagementMember(id: '', photoBase64: '', name: s, designation: '', title: s, description: '');
        } catch (_) {
          return ManagementMember(id: '', photoBase64: '', name: '', designation: '', title: '', description: '');
        }
      }).toList();
      await PreferencesService.setString(_homeContentKey, jsonEncode(homeContent.map((e) => e.toJson()).toList()));

      // Grades and sports
      gradeXTopper = (saved.gradePage.grade10.students ?? []).map((student) => TopperEntry(
            photoBase64: student.photo ?? '',
            studentName: student.studentName ?? '',
            marks: student.marks ?? '',
            imageFit: student.imageFit ?? 'cover',
            cropData: student.cropData,
          )).toList();
      await PreferencesService.setString(_gradeXKey, jsonEncode(gradeXTopper.map((e) => e.toJson()).toList()));

      gradeXIITopper = (saved.gradePage.grade12.students ?? []).map((student) => TopperEntry(
            photoBase64: student.photo ?? '',
            studentName: student.studentName ?? '',
            marks: student.marks ?? '',
            imageFit: student.imageFit ?? 'cover',
            cropData: student.cropData,
          )).toList();
      await PreferencesService.setString(_gradeXIIKey, jsonEncode(gradeXIITopper.map((e) => e.toJson()).toList()));

      sportsAchievements = (saved.gradePage.sportsAchievements ?? []).map((achievement) => SportsAchievementEntry(
            imageBase64: achievement.image ?? '',
            studentName: achievement.studentName ?? '',
            achievementTitle: '',
            description: achievement.achievementDescription ?? '',
          )).toList();
      await PreferencesService.setString(_sportsAchievementsKey, jsonEncode(sportsAchievements.map((e) => e.toJson()).toList()));

    } catch (_) {
      // Keep the locally cached value if the backend is temporarily unavailable.
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
    } catch (error) {
      debugPrint('SchoolConfigService.save failed: $error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveManagementMembers(List<ManagementMember> managementMembers) async {
    this.managementMembers = List<ManagementMember>.from(managementMembers);
    await PreferencesService.setString(
      _managementMembersKey,
      jsonEncode(this.managementMembers.map((e) => e.toJson()).toList()),
    );

    try {
      final contentPayload = SchoolContentModel(
        founder: FounderModel(
          photo: founderPhotoBase64 ?? '',
          name: founderName,
          designation: founderDesignation,
          visionTitle: founderVisionTitle,
          visionDescription: founderVisionDescription,
        ),
        secretary: SecretaryModel(
          photo: secretaryPhotoBase64 ?? '',
          name: secretaryName,
          designation: secretaryDesignation,
          welcomeTitle: secretaryWelcomeTitle,
          welcomeMessage: secretaryWelcomeMessage,
        ),
        headmaster: HeadmasterModel(
          photo: headmasterPhotoBase64 ?? '',
          name: headmasterName,
          designation: headmasterDesignation,
          messageTitle: headmasterMessageTitle,
          message: headmasterMessage,
        ),
        members: this.managementMembers
            .map((member) => ManagementMemberModel(
                  id: member.id.isNotEmpty ? member.id : (member.name.isNotEmpty ? member.name : member.title),
                  photo: member.photoBase64,
                  name: member.name,
                  designation: member.designation,
                  title: member.title,
                  description: member.description,
                  order: 0,
                ))
            .toList(),
      );

      final updated = await _repository.updateSchoolContent(contentPayload.toJson());

      managementMembers = (updated.schoolContent.members ?? [])
          .map((member) => ManagementMember(
                id: member.id ?? '',
                photoBase64: member.photo ?? '',
                name: member.name ?? '',
                designation: member.designation ?? '',
                title: member.title ?? '',
                description: member.description ?? '',
              ))
          .toList();
      await PreferencesService.setString(
        _managementMembersKey,
        jsonEncode(managementMembers.map((e) => e.toJson()).toList()),
      );
      notifyListeners();
      return true;
    } catch (_) {
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveHomeContent(List<ManagementMember> items) async {
    // Keep a snapshot of previously-cached in-memory items so we can detect
    // intentional deletions performed by the user in this session.
    final previousLocal = List<ManagementMember>.from(this.homeContent);

    // Update in-memory list immediately (UI already shows these items).
    this.homeContent = List<ManagementMember>.from(items);

    try {
      // Compute a stable item identity: prefer explicit id, otherwise use title+description.
      String _deriveId(ManagementMember m) {
        if (m.id.isNotEmpty) return m.id;
        final title = m.title.trim();
        final description = m.description.trim();
        return title.isNotEmpty || description.isNotEmpty ? '$title|$description' : DateTime.now().millisecondsSinceEpoch.toString();
      }

      ManagementMember _ensureStableId(ManagementMember m) {
        if (m.id.isNotEmpty) return m;
        return ManagementMember(
          id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}',
          photoBase64: m.photoBase64,
          name: m.name,
          designation: m.designation,
          title: m.title,
          description: m.description,
        );
      }

      String _deriveIdFromMap(Map<String, dynamic> item) {
        final id = (item['id'] ?? '').toString().trim();
        if (id.isNotEmpty) return id;
        final title = (item['title'] ?? '').toString().trim();
        final description = (item['description'] ?? '').toString().trim();
        return title.isNotEmpty || description.isNotEmpty ? '$title|$description' : '';
      }

      this.homeContent = this.homeContent.map(_ensureStableId).toList();
      final localIds = this.homeContent.map(_deriveId).toSet();
      final previousIds = previousLocal.map(_deriveId).toSet();
      final deletedIds = previousIds.difference(localIds);

      // Fetch current server document so we can preserve any server-only items
      // the user didn't intentionally delete. This avoids destructive writes
      // when the UI list is incomplete for any reason.
      final serverDoc = await _repository.getMainPageInfo();
      final serverHomeRaw = serverDoc.homeContent ?? [];

      // Normalize a server item to a Map<String,dynamic> with expected keys
      Map<String, dynamic> normalizeServerItem(dynamic raw) {
        if (raw is Map<String, dynamic>) return raw;
        if (raw is ManagementMemberModel) {
          return {
            'id': raw.id ?? '',
            'photo': raw.photo ?? '',
            'name': raw.name ?? '',
            'designation': raw.designation ?? '',
            'title': raw.title ?? '',
            'description': raw.description ?? '',
            'order': raw.order ?? 0,
          };
        }
        return {'id': raw.toString(), 'photo': '', 'name': raw.toString(), 'designation': '', 'title': raw.toString(), 'description': '', 'order': 0};
      }

      final serverItems = serverHomeRaw.map(normalizeServerItem).toList();

      // Build the authoritative list to send: start with local items (user's
      // intended state). For any server-side items not present locally, keep
      // them only if the user didn't delete them in this session.
      final List<Map<String, dynamic>> merged = [];

      // Add local items first (sanitizing photo values)
      for (final member in this.homeContent) {
        String photoValue = member.photoBase64.trim();
        final shouldStrip = photoValue.startsWith('data:') || photoValue.length > 100000;
        if (shouldStrip) {
          debugPrint('saveHomeContent: stripping large/photo data before send (len=${photoValue.length})');
          photoValue = '';
        }
        merged.add({
          'id': _deriveId(member),
          'photo': photoValue,
          'name': member.name,
          'designation': member.designation,
          'title': member.title,
          'description': member.description,
          'order': 0,
        });
      }

      // Preserve server-only items that were not intentionally deleted
      for (final s in serverItems) {
        final serverId = _deriveIdFromMap(s);
        if (serverId.isEmpty) continue;
        if (localIds.contains(serverId)) continue; // already present in local
        if (deletedIds.contains(serverId)) continue; // user deleted it
        merged.add(s);
      }

      final payload = {'homeContent': merged};

      debugPrint('saveHomeContent: sending payload with ${merged.length} items');
      try {
        // Full per-item debug logging (compact) — avoid printing huge base64
        for (var i = 0; i < merged.length; i++) {
          final m = merged[i];
          final id = (m['id'] ?? '').toString();
          final title = (m['title'] ?? '').toString();
          final desc = (m['description'] ?? '').toString();
          final photo = (m['photo'] ?? '').toString();
          String photoInfo;
          if (photo.isEmpty) {
            photoInfo = 'empty';
          } else if (photo.startsWith('http://') || photo.startsWith('https://')) {
            photoInfo = 'url (${photo.length} chars)';
          } else if (photo.startsWith('data:')) {
            photoInfo = 'dataUri (${photo.length} chars)';
          } else {
            photoInfo = 'base64 (${photo.length} chars)';
          }
          debugPrint('-> item[$i] id="$id" title="${title}" descLen=${desc.length} photo=$photoInfo');
        }
      } catch (_) {}
      final updated = await _repository.updateSchoolContent(payload);

      // If the PUT response didn't include homeContent, fetch authoritative
      // document with a GET and use that instead. This guarantees we never
      // overwrite the editor state with stale cache.
      MainPageInfo authoritative = updated;
      try {
        final returnedCount = (updated.homeContent ?? []).length;
        final expectedCount = merged.length;
        debugPrint('saveHomeContent: PUT returned homeContent count = $returnedCount, expected = $expectedCount');
        if (returnedCount != expectedCount) {
          debugPrint('saveHomeContent: PUT response count mismatch; performing GET fallback');
          authoritative = await _repository.getMainPageInfo();
          debugPrint('saveHomeContent: GET returned homeContent count = ${authoritative.homeContent?.length ?? 0}');
        }
      } catch (e) {
        debugPrint('saveHomeContent: error inspecting PUT response: $e');
      }

      // Updated may include the new homeContent; sync it back from authoritative
      homeContent = (authoritative.homeContent ?? []).map((raw) {
        final item = raw as dynamic;
        if (item is Map<String, dynamic>) {
          return ManagementMember(
            id: item['id']?.toString() ?? item['name']?.toString() ?? '',
            photoBase64: item['photo']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            designation: item['designation']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
          );
        }
        if (item is ManagementMemberModel) {
          return ManagementMember(
            id: item.id ?? '',
            photoBase64: item.photo ?? '',
            name: item.name ?? '',
            designation: item.designation ?? '',
            title: item.title ?? '',
            description: item.description ?? '',
          );
        }
        try {
          final s = item?.toString() ?? '';
          return ManagementMember(id: '', photoBase64: '', name: s, designation: '', title: s, description: '');
        } catch (_) {
          return ManagementMember(id: '', photoBase64: '', name: '', designation: '', title: '', description: '');
        }
      }).toList();

      // Persist authoritative server-backed homeContent to preferences
      debugPrint('saveHomeContent: persisting ${homeContent.length} items to cache');
      await PreferencesService.setString(_homeContentKey, jsonEncode(homeContent.map((e) => e.toJson()).toList()));
      notifyListeners();
      return true;
    } catch (e) {
      // Surface the underlying error to the caller so UI can report a useful message
      debugPrint('SchoolConfigService.saveHomeContent failed: $e');
      notifyListeners();
      rethrow;
    }
  }
}
