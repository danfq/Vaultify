import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:vaultify/util/services/passwords/strength.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/theming/controller.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class GeneratePassword extends StatefulWidget {
  const GeneratePassword({super.key});

  @override
  State<GeneratePassword> createState() => _GeneratePasswordState();
}

class _GeneratePasswordState extends State<GeneratePassword> {
  //Controller
  final _passwordController = TextEditingController();

  ///Include Numbers
  bool _includeNumbers = true;

  ///Include Uppercase
  bool _includeUppercase = true;

  ///Include Symbols
  bool _includeSymbols = true;

  ///Password Length
  double _passwordLength = 12;

  // Add animation variables
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    // Trigger animation after a brief delay
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
            MainWidgets.pageTitle(title: "Generate Password"),

            //Generated Password & Copy
            Row(
              children: [
                Expanded(
                  child: Input(
                    enabled: false,
                    backgroundColor: !ThemeController.current(context: context)
                        ? Colors.grey.shade200
                        : null,
                    controller: _passwordController,
                    placeholder: "Generated Password",
                  ),
                ),

                //Copy Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Buttons.icon(
                    icon: Ionicons.ios_copy_outline,
                    onTap: () async {
                      //Copy to Clipboard
                      Clipboard.setData(
                        ClipboardData(text: _passwordController.text.trim()),
                      );

                      //Notify User
                      ToastHandler.toast(message: "Copied!");
                    },
                  ),
                ),
              ],
            ),

            //Password Length Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text("Length: "),
                  Expanded(
                    child: Slider(
                      value: _passwordLength,
                      min: 8,
                      max: 32,
                      divisions: 24,
                      label: _passwordLength.toInt().toString(),
                      onChanged: (value) =>
                          setState(() => _passwordLength = value),
                    ),
                  ),
                  Text(_passwordLength.toInt().toString()),
                ],
              ),
            ),

            //Spacing
            const SizedBox(height: 40.0),

            //Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text("Include Numbers"),
                    value: _includeNumbers,
                    onChanged: (value) =>
                        setState(() => _includeNumbers = value!),
                  ),
                  CheckboxListTile(
                    title: const Text("Include Uppercase"),
                    value: _includeUppercase,
                    onChanged: (value) =>
                        setState(() => _includeUppercase = value!),
                  ),
                  CheckboxListTile(
                    title: const Text("Include Symbols"),
                    value: _includeSymbols,
                    onChanged: (value) =>
                        setState(() => _includeSymbols = value!),
                  ),
                ],
              ),
            ),

            //Spacing
            const SizedBox(height: 40.0),

            //Generate
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Buttons.elevated(
                text: "Generate",
                onTap: () {
                  //Generate Password
                  final password = StrengthHandler.generateStrongPassword(
                    length: _passwordLength.toInt(),
                    numbers: _includeNumbers,
                    upperCase: _includeUppercase,
                    symbols: _includeSymbols,
                  );

                  //Set Password
                  setState(() {
                    _passwordController.text = password;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
