import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';

///Dialog Type
enum DialogType {
  username,
  email,
  password,
}

///Utility Dialog
class UtilDialog {
  ///Change User Data
  static Future<Map> changeUserData({required DialogType type}) async {
    //User Data
    Map userData = {};

    //Dialog Name
    String dialogName;
    switch (type) {
      case DialogType.username:
        dialogName = "Username";

      case DialogType.email:
        dialogName = "E-mail";

      case DialogType.password:
        dialogName = "Password";
    }

    //Controller
    TextEditingController inputController = TextEditingController();

    //Input
    String input = inputController.text.trim();

    //Show Adaptive Dialog
    await showAdaptiveDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  "Change $dialogName",
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              //Input
              Input(
                controller: inputController,
                placeholder: "New $dialogName",
                centerPlaceholder: true,
                onChanged: (inputString) {
                  input = inputString;
                },
              ),

              //Save
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Buttons.elevated(
                    text: "Save",
                    onTap: () async {
                      //Check Input
                      if (input.isNotEmpty) {
                        //User
                        User? user;

                        //Update User Data per Type
                        switch (type) {
                          case DialogType.username:
                            if (context.mounted) {
                              user = await AccountHandler.updateData(
                                data: {"username": input},
                              );
                            }

                          case DialogType.email:
                            if (context.mounted) {
                              user = await AccountHandler.updateData(
                                email: input,
                              );
                            }

                          case DialogType.password:
                            if (context.mounted) {
                              user = await AccountHandler.updateData(
                                password: input,
                              );
                            }
                        }

                        //Set User Data
                        userData = {
                          "id": user?.id,
                          "email": user?.email,
                          "metadata": user?.userMetadata,
                        };

                        //Close Dialog
                        Navigator.pop(Get.context!);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    //Return User Data
    return userData;
  }
}
