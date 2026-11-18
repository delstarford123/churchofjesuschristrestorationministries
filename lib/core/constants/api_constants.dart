class ApiConstants {
  // Live Vercel Production Server URL
  static const String baseUrl = 'https://harvion.delstarfordworks.co.ke/api/v1';
  static const String fallbackVercelUrl = 'https://backend-fjf0xn0n2-delstarford-works.vercel.app/api/v1';

  // Core Tithes & Offerings Endpoints
  static const String syncTithes = '/tithes/sync';
  static const String submitTithe = '/tithes/submit';
  static const String titheHistory = '/tithes/history';
  static const String mpesaStkPush = '/tithes/mpesa/stkpush';

  // Stewardship Kitty Loans & Advanced Financials (Phase 2)
  static const String applyLoan = '/loans/apply';
  static const String pendingLoans = '/loans/pending';
  static const String myLoans = '/loans/my-loans';
  static const String creditScore = '/financials/credit-score';
  static const String pledges = '/financials/pledges';
  static const String annualTaxStatement = '/financials/statement/annual';
  static const String kittyAnalytics = '/financials/kitty/analytics';

  // Administration, Governance & Security (Phase 3)
  static const String membershipCard = '/governance/card';
  static const String attendanceCheckin = '/governance/attendance/checkin';
  static const String attendanceRecords = '/governance/attendance/records';
  static const String channels = '/governance/channels';
  static const String assets = '/governance/assets';
  static const String elections = '/governance/elections';

  // Community, Outreach & Education (Phase 4)
  static const String sundaySchoolLessons = '/community/sundayschool/lessons';
  static const String childPickupGenerate = '/community/sundayschool/pickup/generate';
  static const String childPickupVerify = '/community/sundayschool/pickup/verify';
  static const String believerMilestones = '/community/classes/milestones';
  static const String communityProjects = '/community/outreach/projects';
  static const String volunteerRoster = '/community/volunteers/roster';
  static const String communionGuide = '/community/liturgy/communion';
  static const String counselingSubmit = '/community/counseling/submit';

  // Smart Tech, Events & Accessibility (Phase 5)
  static const String translations = '/tech/translations';
  static const String events = '/tech/events';
  static const String branches = '/tech/branches';
  static const String digitalBulletin = '/tech/bulletin/current';
  static const String backupStatus = '/tech/backup/status';
  static const String chatMessage = '/chat/message';
  static const String announcements = '/announcements';
  static const String healthCheck = '/health';
}
