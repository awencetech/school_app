/// Central place for route names.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const language = '/language';
  static const main = '/main';
  static const forgotPassword = '/forgot-password';
  static const createAccount = '/create-account';
  static const studentDashboard = '/student-dashboard';
  static const studentInfo = '/student-info';
  static const studentMoreOptions = '/student-more-options';
  static const groupClassMenu = '/group-class-menu';
  static const studentMenu = '/student-menu';
  static const staffDashboard = '/staff-dashboard';
  static const staffOverviewDashboard = '/staff-dashboard/dashboard-summary';
  static const staffEventCalendar = '/staff-dashboard/event-calendar';
  static const staffInfo = '/staff-dashboard/staff-info';
  static const staffInfoEdit = '$staffInfo/edit';
  static const staffApplyLeave = '/staff-dashboard/apply-leave';
  static const staffSwipeAttendance = '/staff-dashboard/swipe-attendance';
  static const staffManagementFeedback = '/staff-dashboard/management-feedback';
  static const staffMeeting = '/staff-dashboard/meeting';
  static const staffAnnouncements = '/staff-dashboard/announcements';
  static const staffResources = '/staff-dashboard/staff-resources';
  static const schoolResources = '/staff-dashboard/school-resources';
  static const staffHandbook = '/staff-dashboard/staff-handbook';
  static const staffEventsCelebration = '/staff-dashboard/events-celebration';
  static const staffTodoTasks = '/staff-dashboard/to-do-tasks';
  static const adminDashboard = '/admin-dashboard';
    static const adminMedicalEventList =
            '$adminDashboard/other-options/medical-event-list';
    static const adminMedicalEventListView = '$adminMedicalEventList/view';
  static const adminDashboardNewsletter = '$adminDashboard/news-letter';
  static const adminDashboardDemography = '$adminDashboard/demography';
  static const adminDashboardLibrary = '$adminDashboard/library';
  static const adminSchoolNews = '/admin/other-options/schoolnews';
  static const adminOtherOptions = '/admin/other-options';
  static const adminMainEdit = '$adminOtherOptions/main-edit';
  static const adminAdd = '$adminOtherOptions/add';
  static const adminKnowYourSchool = '$adminOtherOptions/know-your-school';
  static const adminKnowYourSchoolWebsiteEdit = '$adminKnowYourSchool/website-edit';
  static const adminKnowYourSchoolSchoolHandbookEdit = '$adminKnowYourSchool/school-handbook-edit';
  static const adminKnowYourSchoolEventsCelebrationEdit = '$adminKnowYourSchool/events-celebration-edit';
  static const adminKnowYourSchoolEventsCelebrationEditAddEvent = '$adminKnowYourSchoolEventsCelebrationEdit/add-event';
  static const adminKnowYourSchoolEventsCelebrationEditEditEvent = '$adminKnowYourSchoolEventsCelebrationEdit/edit-event';
  static const adminKnowYourSchoolSchoolResourcesEdit = '$adminKnowYourSchool/school-resources-edit';
  static const adminKnowYourSchoolNewsletterEdit = '$adminKnowYourSchool/newsletter-edit';
  static const adminKnowYourSchoolAnnouncementEdit = '$adminKnowYourSchool/announcement-edit';
  static const adminKnowYourSchoolDemographyEdit = '$adminKnowYourSchool/demography-edit';
  static const adminKnowYourSchoolFacebookEdit = '$adminKnowYourSchool/facebook-edit';
  static const adminKnowYourSchoolYoutubeEdit = '$adminKnowYourSchool/youtube-edit';
    static const adminKnowYourSchoolWhatsappEdit = '$adminKnowYourSchool/whatsapp';
  static const adminKnowYourSchoolInstagramEdit = '$adminKnowYourSchool/instagram-edit';
  static const adminKnowYourSchoolLibraryEdit = '$adminKnowYourSchool/library-edit';
  static const adminStudentOptions = '$adminOtherOptions/student';
  static const adminListStudents = '$adminOtherOptions/list-students';
  static const adminStudentInfo = '$adminListStudents/student-info';
  static const adminStudentMenu = '$adminListStudents/student-menu';
  static const adminStaffOptions = '$adminOtherOptions/staff';
  static const adminListClasses = '$adminOtherOptions/list-classes';
  static const adminListTeachers = '$adminOtherOptions/list-teachers';
  static const adminEmployeeInfo = '$adminListTeachers/employee-info';
  static const adminMainEditSplashScreen = '$adminMainEdit/splash-screen';
  static const adminMainEditSchoolSettings = '$adminMainEdit/school-settings';
  static const adminMainEditSchoolContent =
      '$adminMainEdit/school-content-management';
  static const adminMainEditGradePage = '$adminMainEdit/grade-page';
  static const adminMainEditContentEdit = '$adminMainEdit/content-edit';
  static const adminAddStudent = '$adminAdd/student-create-id';
  static const adminAddStaff = '$adminAdd/staff-create-id';
  static const adminAddAdmin = '$adminAdd/admin-create-id';
  static const adminAddGroup = '$adminAdd/create-group';
  static const adminAddClasses = '$adminAdd/create-classes';
  static const adminOtherGroups = '/admin/other-groups/list-other-groups';
  static const adminOtherGroupDetails = '$adminOtherGroups/';
  static const adminGroupDetails = '/admin/group-details';
  static const teacherGroupClasses = '/teacher/group-classes';
  static const teacherGroupInfo = '$teacherGroupClasses/group-info';
  static const teacherFutureEventCalendar =
      '$teacherGroupClasses/future-event-calendar';
  static const teacherHomeworkToday = '$teacherGroupClasses/homework-today';
  static const teacherGroupMessages = '$teacherGroupClasses/group-messages';
  static const teacherWriteMessage = '$teacherGroupClasses/write-message';
  static const teacherClassDemography = '$teacherGroupClasses/class-demography';
  static const teacherClassResources = '$teacherGroupClasses/class-resources';
  static const teacherPhotosNews = '$teacherGroupClasses/photos-news';
  static const teacherClassTimetable = '$teacherGroupClasses/class-timetable';
  static const teacherClassTimetableAdd =
      '$teacherGroupClasses/class-timetable-add';
  static const teacherClassPlanner = '$teacherGroupClasses/class-planner';
  static const teacherVideoConference = '$teacherGroupClasses/video-conference';
  static const teacherClassFilePlan = '$teacherGroupClasses/class-file-plan';
  static const teacherOnlineAssignment =
      '$teacherGroupClasses/online-assignment';
  static const teacherOnlineAssessment =
      '$teacherGroupClasses/online-assessment';
  static const teacherGroupInfoEdit = '$teacherGroupClasses/group-info-edit';
  static const teacherEditGroupInfo = teacherGroupInfoEdit;
  static const teacherEditFutureEventCalendar =
      '$teacherGroupClasses/future-event-calendar-edit';
  static const teacherEditHomeworkToday =
      '$teacherGroupClasses/homework-today-edit';
  static const teacherHomeworkAdd = '$teacherEditHomeworkToday/homework-add';
  static const teacherTodayClassAdd = '$teacherEditHomeworkToday/today-class';
  static const teacherEditGroupMessages =
      '$teacherGroupClasses/group-messages-edit';
  static const teacherEditWriteMessage =
      '$teacherGroupClasses/write-message-edit';
  static const teacherEditClassDemography =
      '$teacherGroupClasses/class-demography-edit';
  static const teacherEditClassResources =
      '$teacherGroupClasses/class-resources-edit';
  static const teacherEditPhotosNews = '$teacherGroupClasses/photos-news-edit';
  static const teacherEditClassTimetable =
      '$teacherGroupClasses/class-timetable-edit';
  static const teacherEditClassPlanner =
      '$teacherGroupClasses/class-planner-edit';
  static const teacherEditVideoConference =
      '$teacherGroupClasses/video-conference-edit';
  static const teacherEditClassFilePlan =
      '$teacherGroupClasses/class-file-plan-edit';
  static const teacherEditOnlineAssignment =
      '$teacherGroupClasses/online-assignment-edit';
  static const teacherEditOnlineAssessment =
      '$teacherGroupClasses/online-assessment-edit';
  static const teacherEditGroupInfoEdit = teacherGroupInfoEdit;
  static const teacherGroupClassMenu = '$teacherGroupClasses/group-class-menu';
  static const teacherGroupDashboard = '$teacherGroupClasses/group-dashboard';
  static const teacherDiarySummary = '$teacherGroupClasses/diary-summary';
  static const teacherTakeAttendance = '$teacherGroupClasses/take-attendance';
  static const teacherAppreciateAward = '$teacherGroupClasses/appreciate-award';
  static const teacherLeaveApproval = '$teacherGroupClasses/leave-approval';
  static const teacherMedicalEventList =
      '$teacherGroupClasses/medical-event-list';
  static const teacherHappinessReport = '$teacherGroupClasses/happiness-report';
  static const teacherOneOnOneMeeting =
      '$teacherGroupClasses/one-on-one-meeting';
  static const teacherPickDropEntry = '$teacherGroupClasses/pick-drop-entry';
  static const teacherAccessManagement =
      '$teacherGroupClasses/access-management';
  static const teacherClassFeeDetails =
      '$teacherGroupClasses/class-fee-details';
  static const adminSplashScreenEditor = adminMainEditSplashScreen;
  static const adminHomeScreen = '/admin/home-screen';
  static const adminSection = '/admin/section';
  static const adminSchoolSettings = adminMainEditSchoolSettings;
  static const adminSchoolContentManagement = adminMainEditSchoolContent;
  static const adminUserProfile = '/admin/user-profile';
  static const adminChangePassword = '/admin/change-password';
  static const supportQuery = '/support-query';
  static const privacyPolicy = '/privacy-policy';
}
