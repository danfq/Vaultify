import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:native_auth/native_auth.dart';
import 'package:vaultify/pages/vaultify.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/main.dart';

class UnlockApp extends StatefulWidget {
  const UnlockApp({super.key});

  @override
  State<UnlockApp> createState() => _UnlockAppState();
}

class _UnlockAppState extends State<UnlockApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Unlock"), allowBack: false),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            //Animation
            Center(child: AnimHandler.asset(animation: "lock", reverse: true)),

            //Spacing
            const SizedBox(height: 30.0),

            //Unlock Button
            Center(
              child: Buttons.elevatedIcon(
                text: "Unlock Vaultify",
                icon: Ionicons.ios_lock_closed,
                onTap: () async {
                  //Wait for Authentication
                  final authStatus = await Auth.isAuthenticate();

                  //Check Authentication
                  if (authStatus.isAuthenticated) {
                    //Go Home
                    Get.offAll(() => const Vaultify());
                  } else {
                    //Notify User
                    ToastHandler.toast(message: "Failed to Authenticate");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
