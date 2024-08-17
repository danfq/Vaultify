import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:vaultify/pages/account/login.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/data/local.dart';

class Intro extends StatelessWidget {
  const Intro({super.key});

  @override
  Widget build(BuildContext context) {
    //Pages
    final pages = [
      //Hello
      PageViewModel(
        image: AnimHandler.asset(animation: "hello"),
        title: "Hello!",
        body: "Welcome to Vaultify!",
      ),

      //Security
      PageViewModel(
        image: AnimHandler.asset(animation: "secure"),
        title: "Secure & Encrypted",
        body: "All Your Data is Encrypted.",
      ),
    ];

    //UI
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: pages,
          dotsDecorator: DotsDecorator(
            activeColor: Theme.of(context).colorScheme.secondary,
          ),
          showNextButton: true,
          showBackButton: true,
          next: const Text("Next"),
          back: const Text("Back"),
          done: const Text(
            "Let's Go!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onDone: () async {
            //Set Intro as Done
            await LocalData.setData(box: "intro", data: {"status": true}).then(
              (_) {
                //Go to Login
                Get.offAll(() => const Login());
              },
            );
          },
        ),
      ),
    );
  }
}
