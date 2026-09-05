class ParentObservation {
  const ParentObservation({
    this.id = '',
    required this.studentId,
    required this.studentName,
    required this.groupId,
    required this.date,
    this.diaryId = '',
    this.wentToBedAt = '',
    this.gotUpAt = '',
    this.brushedTeeth = '',
    this.didYoga = '',
    this.breakfast = '',
    this.homework = '',
    this.assignmentCompletion = '',
    this.helpfulAtHome = '',
    this.respectfulToElders = '',
    this.parentsRemark = '',
    this.studentMood = '',
    this.teacherPunctuality = '',
    this.teacherFood = '',
    this.subject = '',
    this.assignmentCompletionFeedback = '',
    this.classPerformance = '',
    this.subjectNote = '',
    this.gkScore = '',
    this.area = '',
    this.status = '',
    this.diaryDetails = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String groupId;
  final String date;
  final String diaryId;
  final String wentToBedAt;
  final String gotUpAt;
  final String brushedTeeth;
  final String didYoga;
  final String breakfast;
  final String homework;
  final String assignmentCompletion;
  final String helpfulAtHome;
  final String respectfulToElders;
  final String parentsRemark;
  final String studentMood;
  final String teacherPunctuality;
  final String teacherFood;
  final String subject;
  final String assignmentCompletionFeedback;
  final String classPerformance;
  final String subjectNote;
  final String gkScore;
  final String area;
  final String status;
  final String diaryDetails;

  factory ParentObservation.fromJson(Map<String, dynamic> json) {
    final parent = json['parentObservation'] is Map
        ? Map<String, dynamic>.from(json['parentObservation'] as Map)
        : json;
    final student = json['studentObservation'] is Map
        ? Map<String, dynamic>.from(json['studentObservation'] as Map)
        : const <String, dynamic>{};
    return ParentObservation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      groupId: (json['groupId'] ?? json['classId'] ?? '').toString(),
      date: (json['diaryDate'] ?? json['date'] ?? '').toString(),
      diaryId: (json['diaryId'] ?? '').toString(),
      wentToBedAt: (parent['wentToBedAt'] ?? '').toString(),
      gotUpAt: (parent['gotUpAt'] ?? '').toString(),
      brushedTeeth: (parent['brushedTeeth'] ?? '').toString(),
      didYoga: (parent['didYoga'] ?? '').toString(),
      breakfast: (parent['breakfast'] ?? '').toString(),
      homework: (parent['homework'] ?? '').toString(),
      assignmentCompletion: (parent['assignmentCompletion'] ?? '').toString(),
      helpfulAtHome: (parent['helpfulAtHome'] ?? '').toString(),
      respectfulToElders: (parent['respectfulToElders'] ?? '').toString(),
      parentsRemark: (parent['parentsRemark'] ?? '').toString(),
      studentMood: (student['mood'] ?? '').toString(),
      teacherPunctuality: (json['teacherObservation']?['punctuality'] ?? '')
          .toString(),
      teacherFood: (json['teacherObservation']?['food'] ?? '').toString(),
      subject: (json['subjectFeedback']?['subject'] ?? '').toString(),
      assignmentCompletionFeedback:
          (json['subjectFeedback']?['completionOfDueAssignment'] ?? '')
              .toString(),
      classPerformance:
          (json['subjectFeedback']?['performanceInClassToday'] ?? '')
              .toString(),
      subjectNote: (json['subjectFeedback']?['note'] ?? '').toString(),
      gkScore: (json['gkScore'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      diaryDetails: (json['diaryDetails'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'groupId': groupId,
    'classId': groupId,
    'date': date,
    'diaryDate': date,
    'diaryId': diaryId,
    'parentObservation': {
      'wentToBedAt': wentToBedAt,
      'gotUpAt': gotUpAt,
      'brushedTeeth': brushedTeeth,
      'didYoga': didYoga,
      'breakfast': breakfast,
      'homework': homework,
      'assignmentCompletion': assignmentCompletion,
      'helpfulAtHome': helpfulAtHome,
      'respectfulToElders': respectfulToElders,
      'parentsRemark': parentsRemark,
    },
    'studentObservation': {'mood': studentMood},
    'teacherObservation': {
      'punctuality': teacherPunctuality,
      'food': teacherFood,
    },
    'subjectFeedback': {
      'subject': subject,
      'completionOfDueAssignment': assignmentCompletionFeedback,
      'performanceInClassToday': classPerformance,
      'note': subjectNote,
    },
    'gkScore': gkScore,
    'area': area,
    'status': status,
    'diaryDetails': diaryDetails,
  };
}
