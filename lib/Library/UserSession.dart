import '../Model/UserModel.dart';
import 'dart:convert';

class UserSession {
  static UserModel? loggedInUser;
  static Map<String, dynamic> userPermissions = {};

  static void setLoggedInUser(UserModel user) {
    loggedInUser = user;

    // Decode and store permissions
    if (user.permissions != null && user.permissions!.isNotEmpty) {
      try {
        userPermissions = jsonDecode(user.permissions!);
      } catch (e) {
        userPermissions = {};
      }
    } else {
      userPermissions = {};
    }
  }

  // Permission checkers
  static bool canView(String module) {
    return userPermissions[module]?['View'] == true;
  }

  static bool canCreate(String module) {
    return userPermissions[module]?['Create'] == true;
  }

  static bool canEdit(String module) {
    return userPermissions[module]?['Edit'] == true;
  }
}
