import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/services/passwords/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class ImportFromFile extends StatefulWidget {
  const ImportFromFile({super.key});

  @override
  State<ImportFromFile> createState() => _ImportFromFileState();
}

class _ImportFromFileState extends State<ImportFromFile> {
  ///Imported File Path
  final TextEditingController _importedFilePath = TextEditingController();

  ///Importing Status
  bool _importing = false;

  ///Extract File Name from Path
  String _fileName({required String path}) {
    return path.split("/").last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Import from File")),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Explanation
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "You can import Passwords from Chrome-based browsers (e.g. Google Chrome or Brave).",
                textAlign: TextAlign.center,
              ),
            ),

            //Import
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  //File Name
                  Expanded(
                    child: Input(
                      controller: _importedFilePath,
                      placeholder: _importedFilePath.text.trim().isNotEmpty
                          ? _fileName(path: _importedFilePath.text.trim())
                          : "Import a File...",
                      enabled: false,
                    ),
                  ),

                  //Import
                  Expanded(
                    child: Buttons.elevated(
                      text: "Choose File",
                      onTap: () async {
                        //Show File Picker
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ["csv"],
                        );

                        //Check Result
                        if (result != null) {
                          //Set File Path
                          setState(() {
                            _importedFilePath.text =
                                _fileName(path: result.files.first.path ?? "");
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            //Importing
            Visibility(
              visible: _importing,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text("Importing..."),
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
          enabled: _importedFilePath.text.trim().isNotEmpty,
          text: "Start Importing",
          icon: Ionicons.ios_download_outline,
          onTap: () async {
            //Confirmation
            await Get.defaultDialog(
              barrierDismissible: false,
              title: "Import Passwords",
              content: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Your Passwords will be imported.\nGroups will be created to accomodate all Passwords.",
                  textAlign: TextAlign.center,
                ),
              ),
              cancel: Buttons.text(text: "Cancel", onTap: () => Get.back()),
              confirm: Buttons.elevated(
                text: "Start Importing",
                onTap: () async {
                  //Close Dialog
                  Get.back();

                  //Set Importing Status
                  setState(() {
                    _importing = true;
                  });

                  //File
                  final file = File(_importedFilePath.text.trim());

                  //Start Importing
                  await PasswordsHandler.importFromFile(file: file).then(
                    (imported) {
                      //Stop Animation
                      setState(() {
                        _importing = false;
                      });

                      //Notify User
                      if (imported > 0) {
                        ToastHandler.toast(
                          message: "Successfully Imported $imported Passwords!",
                        );
                      } else {
                        ToastHandler.toast(
                          message: "Failed to Import Passwords",
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
