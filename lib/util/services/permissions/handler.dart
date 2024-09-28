import 'package:permission_handler/permission_handler.dart';

///Permissions Handler
class PermissionsHandler {
  ///Permissions
  static final List<Permission> _permissions = [
    Permission.storage,
  ];

  ///Request Permissions
  static Future<void> requestPermissions() async {
    //Request Each Permission
    for (final permission in _permissions) {
      //Request Permission
      await permission.request();
    }
  }
}
