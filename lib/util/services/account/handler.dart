import 'package:get/route_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/pages/vaultify.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/toast/handler.dart';

///Account Handler
class AccountHandler {
  ///Supabase Auth Instance
  static final GoTrueClient _auth = Supabase.instance.client.auth;

  ///Create Account with `email`, `password` & `username`
  static Future<void> createAccount({
    required String email,
    required String password,
    required String username,
  }) async {
//User
    User? user;

    //Attempt to Sign In
    try {
      await _auth.signUp(
        email: email,
        password: password,
        data: {"username": username},
      ).then(
        (authResponse) async {
          //Check User
          if (authResponse.user != null) {
            //Set User
            user = authResponse.user;

            //Cache User
            await LocalData.setData(box: "user", data: {
              "id": user?.id,
              "email": user?.email,
              "metadata": user?.userMetadata,
            });

            //Go Home
            Get.offAll(() => const Vaultify());
          }
        },
      );
    } on AuthException catch (error) {
      //Notify User
      ToastHandler.toast(message: error.message);
    }
  }

  ///Sign In With `email` & `password`
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    //User
    User? user;

    //Attempt to Sign In
    try {
      await _auth
          .signInWithPassword(
        email: email,
        password: password,
      )
          .then(
        (authResponse) async {
          //Check User
          if (authResponse.user != null) {
            //Set User
            user = authResponse.user;

            //Cache User
            await LocalData.setData(box: "user", data: {
              "id": user?.id,
              "email": user?.email,
              "metadata": user?.userMetadata,
            });

            //Go Home
            Get.offAll(() => const Vaultify());
          }
        },
      );
    } on AuthException catch (error) {
      //Notify User
      ToastHandler.toast(message: error.message);
    }
  }
}
