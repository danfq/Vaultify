import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/services/passwords/hibp.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class Leak extends StatefulWidget {
  const Leak({super.key});

  @override
  State<Leak> createState() => _LeakState();
}

class _LeakState extends State<Leak> {
  // Controller
  final _searchController = TextEditingController();

  // Animation state
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showContent = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _showContent ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: Offset(0, _showContent ? 0 : 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Title
            MainWidgets.pageTitle(title: "Check for Leaks"),

            //Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Input(
                controller: _searchController,
                placeholder: "Enter Password",
                isPassword: true,
              ),
            ),

            //Search Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Buttons.elevated(
                text: "Search for Leaks",
                onTap: () async {
                  //Password
                  final password = _searchController.text;

                  //Check if Input is Empty
                  if (password.trim().isEmpty) return;

                  //Check if Password is Leaked
                  final isLeaked = await HIBP.checkPassword(password);

                  //Close Sheet
                  Get.back();
                  //Notify User
                  Get.defaultDialog(
                    title: "Password Leak",
                    middleText: isLeaked
                        ? "This Password has been leaked!\nChange it immediately!"
                        : "This Password is Safe",
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
