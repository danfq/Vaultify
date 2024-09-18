import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/widgets/dialogs.dart';
import 'package:vaultify/util/widgets/main.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:intl/intl.dart';

class ProfileInfo extends StatefulWidget {
  const ProfileInfo({super.key});

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  ///Get User Info
  Future<Map> getUserInfo() async {
    //User
    final user = await AccountHandler.getUserData();

    //Return User
    return user;
  }

  ///Readable Join Date
  String joinDate(int timestamp) {
    //Date
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    //Formatted Date
    String formattedDate = DateFormat("MMM dd, yyyy").format(date);

    //Return Formatted Date
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Profile"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            //Username & Join Date
            FutureBuilder(
              future: getUserInfo(),
              builder: (context, snapshot) {
                //Check Connection
                if (snapshot.connectionState == ConnectionState.done) {
                  //Data
                  final data = snapshot.data;

                  //Check Data
                  if (data != null) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            data["username"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                          subtitle: Text(
                            joinDate(data["joined"]),
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          trailing: Buttons.iconFilled(
                            icon: Ionicons.ios_log_out,
                            onTap: () async {
                              await AccountHandler.signOut();
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Error Fetching Data"),
                    );
                  }
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      child: ListTile(
                        title: const Text(""),
                        subtitle: const Text(""),
                        trailing: Buttons.iconFilled(
                          icon: Ionicons.ios_log_out,
                          onTap: () async {
                            await AccountHandler.signOut();
                          },
                        ),
                      ),
                    ),
                  );
                }
              },
            ),

            //Options
            Expanded(
              child: SettingsList(
                lightTheme: SettingsThemeData(
                  settingsListBackground:
                      Theme.of(context).scaffoldBackgroundColor,
                ),
                darkTheme: SettingsThemeData(
                  settingsListBackground:
                      Theme.of(context).scaffoldBackgroundColor,
                ),
                physics: const BouncingScrollPhysics(),
                sections: [
                  SettingsSection(
                    tiles: [
                      //Change Username
                      SettingsTile.navigation(
                        leading: const Icon(Ionicons.ios_person),
                        title: const Text("Change Username"),
                        description: const Text("Change your username."),
                        onPressed: (context) async {
                          await UtilDialog.changeUserData(
                            type: DialogType.username,
                          ).then((_) => setState(() {}));
                        },
                      ),

                      //Change Password
                      SettingsTile.navigation(
                        leading: const Icon(Ionicons.ios_lock_closed),
                        title: const Text("Change Password"),
                        description: const Text("Change your password."),
                        onPressed: (context) async {
                          await UtilDialog.changeUserData(
                            type: DialogType.password,
                          );
                        },
                      ),

                      //Delete Account
                      SettingsTile.navigation(
                        leading: const Icon(Ionicons.ios_trash),
                        title: const Text("Delete Account"),
                        description: const Text(
                          "Request account deletion.",
                        ),
                        onPressed: (context) async {
                          await AccountHandler.deleteAccount();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
