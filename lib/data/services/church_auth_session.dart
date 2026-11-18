import 'package:flutter/foundation.dart';

enum ChurchRole {
  superAdmin,
  executive,
  member,
  visitor
}

class ChurchMemberSession extends ChangeNotifier {
  static final ChurchMemberSession instance = ChurchMemberSession._internal();
  ChurchMemberSession._internal();

  String memberId = 'RLDS-2026-1001';
  String fullName = 'Samuel Makokha';
  String email = 'pastor.makokha@rldschurch.co.ke';
  String phone = '+254712000001';
  ChurchRole role = ChurchRole.executive;
  String title = 'Pastor in Charge';
  String branch = 'Restoration Fellowship Assembly';

  bool get isSuperAdmin => role == ChurchRole.superAdmin;
  bool get isExecutive => role == ChurchRole.executive || role == ChurchRole.superAdmin;
  bool get isMember => role == ChurchRole.member || role == ChurchRole.executive || role == ChurchRole.superAdmin;

  void signIn({
    required String id,
    required String name,
    required String userEmail,
    required String userPhone,
    required ChurchRole userRole,
    required String userTitle,
    required String userBranch,
  }) {
    memberId = id;
    fullName = name;
    email = userEmail;
    phone = userPhone;
    role = userRole;
    title = userTitle;
    branch = userBranch;
    notifyListeners();
  }

  void switchRole(ChurchRole newRole) {
    role = newRole;
    if (newRole == ChurchRole.superAdmin) {
      memberId = 'RLDS-ADMIN-001';
      title = 'Super Administrator & Presiding Bishop';
    } else if (newRole == ChurchRole.executive) {
      memberId = 'RLDS-EXEC-104';
      title = 'Presiding Elder / Pastor';
    } else {
      memberId = 'RLDS-2026-1088';
      title = 'Sanctuary Member in Good Standing';
    }
    notifyListeners();
  }

  static String generateMembershipNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = timestamp.substring(timestamp.length - 4);
    return 'RLDS-2026-$suffix';
  }
}
