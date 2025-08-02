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

  static bool _isAdmin() {
    return loggedInUser?.role == 'admin';
  }

  static bool canView(String module) {
    if (_isAdmin()) return true; // admin can view everything
    final perms = userPermissions[module];
    return perms != null && perms['View'] == true;
  }

  static bool canCreate(String module) {
    if (_isAdmin()) return true; // admin can create everything
    final perms = userPermissions[module];
    return perms != null && perms['Create'] == true;
  }

  static bool canEdit(String module) {
    if (_isAdmin()) return true; // admin can edit everything
    final perms = userPermissions[module];
    return perms != null && perms['Edit'] == true;
  }

}
