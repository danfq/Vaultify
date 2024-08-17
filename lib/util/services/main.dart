import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/pages/account/login.dart';
import 'package:vaultify/pages/intro/intro.dart';
import 'package:vaultify/pages/vaultify.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/local.dart';

///Main Services Handler
class MainServices {
  ///Initialize Main Services
  ///
  ///- Widgets Binding (Flutter).
  ///- Environment Variables (DotEnv).
  ///- Local Data (Hive).
  ///- Remote Data (Supabase).
  static Future<void> init() async {
    //Widgets Binding
    WidgetsFlutterBinding.ensureInitialized();

    //Environment Variables
    await EnvVars.load();

    //Local Data
    await LocalData.init();

    //Remote Data
    await Supabase.initialize(
      url: EnvVars.get(name: "SUPABASE_URL"),
      anonKey: EnvVars.get(name: "SUPABASE_KEY"),
    );
  }

  ///Initial Route
  static Future<Widget> initialRoute() async {
    //Intro Status
    final introStatus = LocalData.boxData(box: "intro")["status"] ?? false;

    //Login Status
    final loginStatus = Supabase.instance.client.auth.currentUser != null;

    //Return Initial Route
    return introStatus
        ? loginStatus
            ? const Vaultify()
            : const Login()
        : const Intro();
  }
}
