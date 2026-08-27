class StaffInfo {
  const StaffInfo({
    this.id,
    required this.name,
    required this.designation,
    required this.employeeCategory,
    required this.employeeId,
    required this.teaches,
    required this.about,
    required this.hobbiesAndInterest,
    required this.role,
    required this.imageUrl,
    String? mobileNo,
    String? shareableContactNo,
    String? mailId,
    String? address,
    String? briefIntroduction,
    String? sports,
    String? sportsTrainingDetails,
    String? sportsTeamClub,
    String? achievements,
    String? extraCurricularActivities,
    String? extraCurricularTeamClub,
    String? professionalBodyAssociation,
    String? whatYouDo,
    this.createdAt,
    this.updatedAt,
  })  : mobileNo = mobileNo ?? '',
        shareableContactNo = shareableContactNo ?? '',
        mailId = mailId ?? '',
        address = address ?? '',
        briefIntroduction = briefIntroduction ?? '',
        sports = sports ?? '',
        sportsTrainingDetails = sportsTrainingDetails ?? '',
        sportsTeamClub = sportsTeamClub ?? '',
        achievements = achievements ?? '',
        extraCurricularActivities = extraCurricularActivities ?? '',
        extraCurricularTeamClub = extraCurricularTeamClub ?? '',
        professionalBodyAssociation = professionalBodyAssociation ?? '',
        whatYouDo = whatYouDo ?? '';

  final String? id;
  final String name;
  final String designation;
  final String employeeCategory;
  final String employeeId;
  final String teaches;
  final String about;
  final String hobbiesAndInterest;
  final String role;
  final String imageUrl;
  final String mobileNo;
  final String shareableContactNo;
  final String mailId;
  final String address;
  final String briefIntroduction;
  final String sports;
  final String sportsTrainingDetails;
  final String sportsTeamClub;
  final String achievements;
  final String extraCurricularActivities;
  final String extraCurricularTeamClub;
  final String professionalBodyAssociation;
  final String whatYouDo;
  final String? createdAt;
  final String? updatedAt;

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      employeeCategory: json['employeeCategory']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      teaches: json['teaches']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      hobbiesAndInterest: json['hobbiesAndInterest']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      mobileNo: json['mobileNo']?.toString() ?? '',
      shareableContactNo: json['shareableContactNo']?.toString() ?? '',
      mailId: json['mailId']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      briefIntroduction: json['briefIntroduction']?.toString() ?? '',
      sports: json['sports']?.toString() ?? '',
      sportsTrainingDetails: json['sportsTrainingDetails']?.toString() ?? '',
      sportsTeamClub: json['sportsTeamClub']?.toString() ?? '',
      achievements: json['achievements']?.toString() ?? '',
      extraCurricularActivities: json['extraCurricularActivities']?.toString() ?? '',
      extraCurricularTeamClub: json['extraCurricularTeamClub']?.toString() ?? '',
      professionalBodyAssociation: json['professionalBodyAssociation']?.toString() ?? '',
      whatYouDo: json['whatYouDo']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'designation': designation,
        'employeeCategory': employeeCategory,
        'employeeId': employeeId,
        'teaches': teaches,
        'about': about,
        'hobbiesAndInterest': hobbiesAndInterest,
        'role': role,
        'imageUrl': imageUrl,
        'mobileNo': mobileNo,
        'shareableContactNo': shareableContactNo,
        'mailId': mailId,
        'address': address,
        'briefIntroduction': briefIntroduction,
        'sports': sports,
        'sportsTrainingDetails': sportsTrainingDetails,
        'sportsTeamClub': sportsTeamClub,
        'achievements': achievements,
        'extraCurricularActivities': extraCurricularActivities,
        'extraCurricularTeamClub': extraCurricularTeamClub,
        'professionalBodyAssociation': professionalBodyAssociation,
        'whatYouDo': whatYouDo,
      };
}
