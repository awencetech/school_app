class MainPageInfo {
  const MainPageInfo({
    this.id = '',
    this.splashScreen = const SplashScreenModel(),
    this.schoolSettings = const SchoolSettingsModel(),
    this.schoolContent = const SchoolContentModel(),
    this.gradePage = const GradePageModel(),
    this.updatedAt,
  });

  final String id;
  final SplashScreenModel splashScreen;
  final SchoolSettingsModel schoolSettings;
  final SchoolContentModel schoolContent;
  final GradePageModel gradePage;
  final DateTime? updatedAt;

  factory MainPageInfo.fromJson(Map<String, dynamic> json) {
    return MainPageInfo(
      id: (json['_id'] ?? '').toString(),
      splashScreen: SplashScreenModel.fromJson(Map<String, dynamic>.from(json['splashScreen'] ?? {})),
      schoolSettings: SchoolSettingsModel.fromJson(Map<String, dynamic>.from(json['schoolSettings'] ?? {})),
      schoolContent: SchoolContentModel.fromJson(Map<String, dynamic>.from(json['schoolContent'] ?? {})),
      gradePage: GradePageModel.fromJson(Map<String, dynamic>.from(json['gradePage'] ?? {})),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'splashScreen': splashScreen.toJson(),
      'schoolSettings': schoolSettings.toJson(),
      'schoolContent': schoolContent.toJson(),
      'gradePage': gradePage.toJson(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class SplashScreenModel {
  const SplashScreenModel({
    this.title = '',
    this.subtitle = '',
    this.image = '',
    this.sinceYear = '',
    this.quote = '',
    this.imageScale = 1.0,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final String quote;
  final String image;
  final String sinceYear;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;
  final bool enabled;

  factory SplashScreenModel.fromJson(Map<String, dynamic> json) {
    return SplashScreenModel(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      quote: json['quote']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      sinceYear: json['sinceYear']?.toString() ?? '',
      imageScale: double.tryParse(json['imageScale']?.toString() ?? '') ?? 1.0,
      imageOffsetX: double.tryParse(json['imageOffsetX']?.toString() ?? '') ?? 0.0,
      imageOffsetY: double.tryParse(json['imageOffsetY']?.toString() ?? '') ?? 0.0,
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'quote': quote,
        'image': image,
        'sinceYear': sinceYear,
        'imageScale': imageScale,
        'imageOffsetX': imageOffsetX,
        'imageOffsetY': imageOffsetY,
        'enabled': enabled,
      };
}

class SchoolSettingsModel {
  const SchoolSettingsModel({
    this.schoolName = '',
    this.schoolLogo = '',
    this.schoolPoster = '',
    this.selectedLanguage = '',
    this.themeColor = '',
    this.schoolQuote = '',
    this.welcomeText = '',
    this.schoolWebsite = '',
    this.runningContent = const [],
  });

  final String schoolName;
  final String schoolLogo;
  final String schoolPoster;
  final String selectedLanguage;
  final String themeColor;
  final String schoolQuote;
  final String welcomeText;
  final String schoolWebsite;
  final List<String> runningContent;

  factory SchoolSettingsModel.fromJson(Map<String, dynamic> json) {
    return SchoolSettingsModel(
      schoolName: json['schoolName']?.toString() ?? '',
      schoolLogo: json['schoolLogo']?.toString() ?? '',
      schoolPoster: json['schoolPoster']?.toString() ?? '',
      selectedLanguage: json['selectedLanguage']?.toString() ?? '',
      themeColor: json['themeColor']?.toString() ?? '',
      schoolQuote: json['schoolQuote']?.toString() ?? '',
      welcomeText: json['welcomeText']?.toString() ?? '',
      schoolWebsite: json['schoolWebsite']?.toString() ?? '',
      runningContent: (json['runningContent'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'schoolLogo': schoolLogo,
        'schoolPoster': schoolPoster,
        'selectedLanguage': selectedLanguage,
        'themeColor': themeColor,
        'schoolQuote': schoolQuote,
        'welcomeText': welcomeText,
        'schoolWebsite': schoolWebsite,
        'runningContent': runningContent,
      };
}

class SchoolContentModel {
  const SchoolContentModel({
    this.founder = const FounderModel(),
    this.secretary = const SecretaryModel(),
    this.headmaster = const HeadmasterModel(),
    this.members = const [],
  });

  final FounderModel founder;
  final SecretaryModel secretary;
  final HeadmasterModel headmaster;
  final List<ManagementMemberModel> members;

  factory SchoolContentModel.fromJson(Map<String, dynamic> json) {
    return SchoolContentModel(
      founder: FounderModel.fromJson(Map<String, dynamic>.from(json['founder'] ?? {})),
      secretary: SecretaryModel.fromJson(Map<String, dynamic>.from(json['secretary'] ?? {})),
      headmaster: HeadmasterModel.fromJson(Map<String, dynamic>.from(json['headmaster'] ?? {})),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((item) => ManagementMemberModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'founder': founder.toJson(),
        'secretary': secretary.toJson(),
        'headmaster': headmaster.toJson(),
        'members': members.map((member) => member.toJson()).toList(),
      };
}

class FounderModel {
  const FounderModel({
    this.photo = '',
    this.name = '',
    this.designation = '',
    this.visionTitle = '',
    this.visionDescription = '',
  });

  final String photo;
  final String name;
  final String designation;
  final String visionTitle;
  final String visionDescription;

  factory FounderModel.fromJson(Map<String, dynamic> json) {
    return FounderModel(
      photo: json['photo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      visionTitle: json['visionTitle']?.toString() ?? '',
      visionDescription: json['visionDescription']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'photo': photo,
        'name': name,
        'designation': designation,
        'visionTitle': visionTitle,
        'visionDescription': visionDescription,
      };
}

class SecretaryModel {
  const SecretaryModel({
    this.photo = '',
    this.name = '',
    this.designation = '',
    this.welcomeTitle = '',
    this.welcomeMessage = '',
  });

  final String photo;
  final String name;
  final String designation;
  final String welcomeTitle;
  final String welcomeMessage;

  factory SecretaryModel.fromJson(Map<String, dynamic> json) {
    return SecretaryModel(
      photo: json['photo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      welcomeTitle: json['welcomeTitle']?.toString() ?? '',
      welcomeMessage: json['welcomeMessage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'photo': photo,
        'name': name,
        'designation': designation,
        'welcomeTitle': welcomeTitle,
        'welcomeMessage': welcomeMessage,
      };
}

class HeadmasterModel {
  const HeadmasterModel({
    this.photo = '',
    this.name = '',
    this.designation = '',
    this.messageTitle = '',
    this.message = '',
  });

  final String photo;
  final String name;
  final String designation;
  final String messageTitle;
  final String message;

  factory HeadmasterModel.fromJson(Map<String, dynamic> json) {
    return HeadmasterModel(
      photo: json['photo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      messageTitle: json['messageTitle']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'photo': photo,
        'name': name,
        'designation': designation,
        'messageTitle': messageTitle,
        'message': message,
      };
}

class ManagementMemberModel {
  const ManagementMemberModel({
    this.id = '',
    this.photo = '',
    this.name = '',
    this.designation = '',
    this.title = '',
    this.description = '',
    this.order = 0,
  });

  final String id;
  final String photo;
  final String name;
  final String designation;
  final String title;
  final String description;
  final int order;

  factory ManagementMemberModel.fromJson(Map<String, dynamic> json) {
    return ManagementMemberModel(
      id: json['id']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      order: json['order'] is int ? json['order'] as int : int.tryParse(json['order']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'photo': photo,
        'name': name,
        'designation': designation,
        'title': title,
        'description': description,
        'order': order,
      };
}

class GradePageModel {
  const GradePageModel({
    this.grade10 = const GradeStudentGroupModel(),
    this.grade12 = const GradeStudentGroupModel(),
    this.sportsAchievements = const [],
  });

  final GradeStudentGroupModel grade10;
  final GradeStudentGroupModel grade12;
  final List<SportsAchievementModel> sportsAchievements;

  factory GradePageModel.fromJson(Map<String, dynamic> json) {
    return GradePageModel(
      grade10: GradeStudentGroupModel.fromJson(Map<String, dynamic>.from(json['grade10'] ?? {})),
      grade12: GradeStudentGroupModel.fromJson(Map<String, dynamic>.from(json['grade12'] ?? {})),
      sportsAchievements: (json['sportsAchievements'] as List<dynamic>? ?? [])
          .map((item) => SportsAchievementModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'grade10': grade10.toJson(),
        'grade12': grade12.toJson(),
        'sportsAchievements': sportsAchievements.map((item) => item.toJson()).toList(),
      };
}

class GradeStudentGroupModel {
  const GradeStudentGroupModel({this.students = const []});

  final List<StudentModel> students;

  factory GradeStudentGroupModel.fromJson(Map<String, dynamic> json) {
    return GradeStudentGroupModel(
      students: (json['students'] as List<dynamic>? ?? [])
          .map((item) => StudentModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'students': students.map((student) => student.toJson()).toList(),
      };
}

class StudentModel {
  const StudentModel({
    this.photo = '',
    this.studentName = '',
    this.marks = '',
    this.imageFit = 'cover',
    this.cropData,
  });

  final String photo;
  final String studentName;
  final String marks;
  final String imageFit;
  final Map<String, dynamic>? cropData;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      photo: json['photo']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      marks: json['marks']?.toString() ?? '',
      imageFit: json['imageFit']?.toString() ?? 'cover',
      cropData: json['cropData'] is Map<String, dynamic> ? json['cropData'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo': photo,
      'studentName': studentName,
      'marks': marks,
      'imageFit': imageFit,
      if (cropData != null) 'cropData': cropData,
    };
  }
}

class SportsAchievementModel {
  const SportsAchievementModel({
    this.image = '',
    this.studentName = '',
    this.achievementDescription = '',
  });

  final String image;
  final String studentName;
  final String achievementDescription;

  factory SportsAchievementModel.fromJson(Map<String, dynamic> json) {
    return SportsAchievementModel(
      image: json['image']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      achievementDescription: json['achievementDescription']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'image': image,
        'studentName': studentName,
        'achievementDescription': achievementDescription,
      };
}
