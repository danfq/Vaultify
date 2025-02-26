import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/pages/account/login.dart';
import 'package:vaultify/pages/intro/intro.dart';
import 'package:vaultify/pages/security/unlock.dart';
import 'package:vaultify/pages/vaultify.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/permissions/handler.dart';
import 'package:vaultify/util/services/tray/handler.dart';

///Main Services Handler
class MainServices {
  ///Initialize Main Services
  ///
  ///- Widgets Binding (Flutter).
  ///- Environment Variables (DotEnv).
  ///- Permissions.
  ///- Local Data (Hive).
  ///- Remote Data (Supabase).
  ///- Stripe.
  ///- Tray - Desktop Only.
  static Future<void> init() async {
    //Widgets Binding
    WidgetsFlutterBinding.ensureInitialized();

    //Environment Variables
    await EnvVars.load();

    //Permissions - Mobile Only
    if (Platform.isAndroid || Platform.isIOS) {
      await PermissionsHandler.requestPermissions();
    }

    //Local Data
    await LocalData.init();

    //Remote Data
    await Supabase.initialize(
      url: EnvVars.get(name: "SUPABASE_URL"),
      anonKey: EnvVars.get(name: "SUPABASE_KEY"),
    );

    //Premium
    await PremiumHandler.init();

    //Tray - Desktop Only
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await TrayHandler.init();
    }
  }

  ///Initial Route
  static Future<Widget> initialRoute() async {
    //Intro Status
    final introStatus = LocalData.boxData(box: "intro")["status"] ?? false;

    //Bio Lock Status
    final lockStatus = LocalData.boxData(box: "security")["bio_lock"] ?? false;

    //Login Status
    final loginStatus = AccountHandler.currentUser != null;

    //Return Initial Route
    return introStatus
        ? loginStatus
            ? lockStatus
                ? const UnlockApp()
                : const Vaultify()
            : const Login()
        : const Intro();
  }
}
