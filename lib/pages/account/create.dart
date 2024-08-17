import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    //E-mail Controller
    TextEditingController emailController = TextEditingController();

    //Password Controller
    TextEditingController passwordController = TextEditingController();

    //Username Controller
    TextEditingController usernameController = TextEditingController();

    //UI
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Create Account")),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Username
            Input(
              controller: usernameController,
              placeholder: "Username",
            ),

            //E-mail
            Input(
              controller: emailController,
              placeholder: "E-mail",
              isEmail: true,
            ),

            //Password
            Input(
              controller: passwordController,
              placeholder: "Password",
              isPassword: true,
            ),

            //Spacing
            const SizedBox(height: 60.0),

            //Login
            Buttons.elevated(
              text: "Create Account",
              onTap: () async {
                //E-mail & Password
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final username = usernameController.text.trim();

                //Check E-mail & Password
                if (email.isNotEmpty &&
                    password.isNotEmpty &&
                    username.isNotEmpty) {
                  //User Confirmation
                  await Get.defaultDialog(
                    title: "Are you sure?",
                    content: const Text("You can later change these details."),
                    actions: [
                      //Go Back
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Go Back"),
                      ),

                      //Proceed
                      Buttons.elevated(
                        text: "Proceed",
                        onTap: () async {
                          //Close Dialog
                          Get.back();

                          //Sign In With E-mail & Password
                          await AccountHandler.createAccount(
                            email: email,
                            password: password,
                            username: username,
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  //Notify User
                  ToastHandler.toast(message: "All Fields Are Mandatory");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
