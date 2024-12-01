import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class ImportKey extends StatefulWidget {
  const ImportKey({super.key});

  @override
  State<ImportKey> createState() => _ImportKeyState();
}

class _ImportKeyState extends State<ImportKey> {
  final TextEditingController _keyFilePath = TextEditingController();
  bool _importing = false;

  String _fileName({required String path}) {
    return path.split("/").last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Import Key")),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Import your Private Key (.pem) to decrypt your Data.",
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Input(
                      controller: _keyFilePath,
                      placeholder: _keyFilePath.text.trim().isNotEmpty
                          ? _fileName(path: _keyFilePath.text.trim())
                          : "Select Key file...",
                      enabled: false,
                    ),
                  ),
                  Expanded(
                    child: Buttons.elevated(
                      text: "Choose File",
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ["pem"],
                        );

                        if (result != null) {
                          setState(() {
                            _keyFilePath.text = result.files.first.path ?? "";
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _importing,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text("Importing key..."),
                      SizedBox(height: 20.0),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Buttons.elevatedIcon(
          enabled: _keyFilePath.text.trim().isNotEmpty,
          text: "Import Key",
          icon: Ionicons.key_outline,
          onTap: () async {
            await Get.defaultDialog(
              barrierDismissible: false,
              title: "Import Key",
              content: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Are you sure you want to import this key file?",
                  textAlign: TextAlign.center,
                ),
              ),
              cancel: Buttons.text(text: "Cancel", onTap: () => Get.back()),
              confirm: Buttons.elevated(
                text: "Import",
                onTap: () async {
                  //Import Key
                  setState(() => _importing = true);
                  EncryptionHandler.importKey(
                    file: File(
                      _keyFilePath.text.trim(),
                    ),
                  );

                  //Finished Importing
                  setState(() => _importing = false);

                  //Go Back
                  Get.back();

                  //Notify User
                  ToastHandler.toast(message: "Key Imported Successfully!");
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
