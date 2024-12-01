import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/pages/account/login.dart';
import 'package:vaultify/pages/vaultify.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/passwords/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';

///Account Handler
class AccountHandler {
  ///Supabase Auth Instance
  static final GoTrueClient _auth = Supabase.instance.client.auth;

  ///Supabase Database Instance
  static final SupabaseClient _supabase = Supabase.instance.client;

  ///Current User
  static final User? currentUser = _auth.currentUser;

  ///Cached User
  static final Map cachedUser = LocalData.boxData(box: "user")["info"] ?? {};

  ///Get User Data
  static Future<Map> getUserData() async {
    //Check Current User
    if (cachedUser.isNotEmpty) {
      //User Data
      final userData = await Supabase.instance.client
          .from("users")
          .select()
          .eq(
            "id",
            cachedUser["id"],
          )
          .limit(1);

      return userData[0];
    } else {
      return {};
    }
  }

  ///Update User Data
  static Future<User?> updateData({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    //User Updated
    User? userData;

    //Check if User is Logged In
    if (currentUser != null) {
      //Update User per Provided Data
      await _auth
          .updateUser(
        UserAttributes(
          email: email ?? cachedUser["email"],
          password: password,
          data: data,
        ),
      )
          .then((response) async {
        //New User Data
        final user = response.user;

        //Return if User is Not Null
        userData = user;

        //Update Database if Not Null
        if (userData != null) {
          await _supabase.from("users").upsert({
            "id": userData?.id,
            "username": data?["username"],
          });
        }
      });
    }

    //Return Update Status
    return userData;
  }

  ///Sign Out
  static Future<void> signOut() async {
    //Confirmation Sheet
    showModalBottomSheet(
      context: Get.context!,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Title
              const Text(
                "Sign Out",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
              ),

              //Swipe to Confirm
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: SwipeableButtonView(
                  onFinish: () {},
                  onWaitingProcess: () async {
                    await _auth.signOut().then((_) {
                      //Go to Login
                      Get.offAll(() => const Login());
                    });
                  },
                  activeColor: Theme.of(context).cardColor,
                  buttonWidget: const Icon(
                    Ionicons.ios_chevron_forward,
                    color: Colors.black,
                  ),
                  buttonText: "Swipe to Confirm",
                  buttontextstyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ///Delete Account
  static Future<void> deleteAccount() async {
    //Confirmation Sheet
    showModalBottomSheet(
      context: Get.context!,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Title
              const Text(
                "Delete Account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
              ),

              //Swipe to Confirm
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: SwipeableButtonView(
                  onFinish: () {},
                  onWaitingProcess: () async {
                    try {
                      //Delete User
                      await _supabase
                          .from("users")
                          .delete()
                          .eq("id", cachedUser["id"]);

                      //Delete Groups
                      await GroupsHandler.deleteAll();

                      //Delete Passwords
                      await PasswordsHandler.deleteAll();

                      //Add Deletion Request
                      await RemoteData.addData(
                        table: "delete_requests",
                        data: {
                          "id": const Uuid().v4(),
                          "email": cachedUser["email"],
                        },
                      ).then((added) {
                        //Check if Added
                        if (added) {
                          Get.offAll(() => const Login());
                        } else {
                          ToastHandler.toast(message: "An Error Occurred");
                        }
                      });
                    } catch (error) {
                      debugPrint(error.toString());
                    }
                  },
                  activeColor: Theme.of(context).cardColor,
                  buttonWidget: const Icon(
                    Ionicons.ios_chevron_forward,
                    color: Colors.black,
                  ),
                  buttonText: "Swipe to Confirm",
                  buttontextstyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
              "info": {
                "id": user?.id,
                "email": user?.email,
                "metadata": user?.userMetadata,
              }
            });

            //Save User in Database
            await _saveUserInDB(user: user!);

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

    //Requested Deletion
    bool requestedDel = await _checkDelReq(email: email);

    //Attempt to Sign In
    try {
      //Check if Requested Deletion
      if (requestedDel) {
        //Notify User
        Get.defaultDialog(
          title: "Account Deletion",
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "You've requested the deletion of your account.\n\nIf you've changed your mind, please contact us.",
              textAlign: TextAlign.center,
            ),
          ),
          confirm: Buttons.elevated(
            text: "Contact Us",
            onTap: () async {
              //Mail To
              final mailTo = Mailto(
                to: ["help@danfq.dev"],
                subject: "Account Deletion",
                body:
                    "User: $email\n\nThis User wants to keep their Account active.",
              );

              //Open Sheet
              await launchUrl(Uri.parse(mailTo.toString()));
            },
          ),
        );
      } else {
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
                "info": {
                  "id": user?.id,
                  "email": user?.email,
                  "metadata": user?.userMetadata,
                }
              });

              //Go Home
              Get.offAll(() => const Vaultify());
            }
          },
        );
      }
    } on AuthException catch (error) {
      //Notify User
      ToastHandler.toast(message: error.message);
    }
  }

  ///Check Deletion Request
  static Future<bool> _checkDelReq({required String email}) async {
    //Database
    final db = Supabase.instance.client;

    //Deletion Requests
    final delReqs =
        await db.from("delete_requests").select().eq("email", email);

    //Return Accordingly
    return delReqs.isNotEmpty;
  }

  ///Save User in Database
  static Future<void> _saveUserInDB({required User user}) async {
    //Database
    final db = Supabase.instance.client;

    //Generate Key Pair & Save User in Database
    try {
      //Generate Key Pair
      final keyPair = await EncryptionHandler.generateKeyPair();

      //Save User in Database
      await db.from("users").insert({
        "id": user.id,
        "username": user.userMetadata?["username"],
        "joined": DateTime.now().millisecondsSinceEpoch,
        "public_key": keyPair["publicKey"],
      });

      //Cache Key Pair
      await EncryptionHandler.saveKeyPairSecurely(
        publicKey: keyPair["publicKey"] ?? "",
        privateKey: keyPair["privateKey"] ?? "",
      );
    } on Exception catch (error) {
      //Throw Exception
      throw Exception(error.toString());
    }
  }
}
