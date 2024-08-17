import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/account/create.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    //E-mail Controller
    TextEditingController emailController = TextEditingController();

    //Password Controller
    TextEditingController passwordController = TextEditingController();

    //UI
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Login"), allowBack: false),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

            //Create Account
            GestureDetector(
              onTap: () {
                Get.to(() => const CreateAccount());
              },
              child: const Text(
                "Create Account",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),

            //Spacing
            const SizedBox(height: 60.0),

            //Login
            Buttons.elevated(
              text: "Login",
              onTap: () async {
                //E-mail & Password
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                //Check E-mail & Password
                if (email.isNotEmpty && password.isNotEmpty) {
                  //Sign In With E-mail & Password
                  await AccountHandler.signIn(email: email, password: password);
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
