import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';

///Passwords Handler
class PasswordsHandler {
  ///Supabase
  static final _supabase = Supabase.instance.client;

  ///Current User
  static final _currentUserID =
      AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

  ///Check if User Hit Max Passwords
  static Future<bool> hitMax() async {
    //User Passwords
    final passwords = await getAll();

    //Max Passwords
    final maxPwds = await maxPasswords();

    //Return True or False
    if (maxPwds == "∞") {
      return false; // No limit for Premium Users
    } else {
      //Max Count
      final maxCount = int.tryParse(maxPwds) ?? 0;

      //Return True or False if Reached Max Passwords
      return passwords.length >= maxCount;
    }
  }

  ///Max Passwords
  static Future<String> maxPasswords() async {
    //Max Passwords (Environment Variable)
    final maxEnv = EnvVars.get(name: "MAX_ITEMS");

    //Check Premium
    final premium = await PremiumHandler.checkPremium();

    //Return According to Premium
    return premium ? "∞" : maxEnv;
  }

  /// Import Passwords from File
  static Future<int> importFromFile({required File file}) async {
    //Number of Imported Passwords
    int importedPwds = 0;

    // Check if File Exists
    if (await file.exists()) {
      // Check if File is CSV
      if (file.path.endsWith(".csv")) {
        try {
          //Parse Passwords
          final parsedData = await _parseCSVFile(file);

          //Check Passwords
          if (parsedData.isNotEmpty) {
            //Create Passwords & Respective Groups
            for (final entry in parsedData.entries) {
              //Group Name
              final groupName = entry.key;

              //Passwords
              final passwords = entry.value;

              //Create Group
              await GroupsHandler.addGroup(name: groupName).then((group) async {
                //Check Group
                if (group != null) {
                  //Add Passwords to Group
                  for (final password in passwords) {
                    await addWithGroup(password: password, groupID: group.id);
                  }

                  //Set Imported Status as True When Done
                  importedPwds = passwords.length;
                } else {
                  ToastHandler.toast(message: "Failed to Create Group");
                  debugPrint("Failed to Create Group");
                  importedPwds = 0;
                }
              });
            }
          } else {
            ToastHandler.toast(message: "No Passwords in File");
            debugPrint("No Passwords in File");
            importedPwds = 0;
          }
        } catch (error) {
          ToastHandler.toast(message: "Error Parsing CSV: $error.");
          debugPrint("Error Parsing CSV: $error.");
          importedPwds = 0;
        }
      } else {
        debugPrint("Invalid CSV");

        //File Isn't Valid CSV - Return False
        importedPwds = 0;
      }
    } else {
      debugPrint("File Doesn't Exist");

      //File Doesn't Exist - Return False
      importedPwds = 0;
    }

    //Return Imported Status
    return importedPwds;
  }

  /// Helper function to parse the CSV file
  static Future<Map<String, List<Password>>> _parseCSVFile(File file) async {
    //CSV Content
    final csvContents = await file.readAsString();
    final csvRows = const CsvToListConverter().convert(csvContents);

    //Grouped Passwords
    final Map<String, List<Password>> groupedPasswords = {};

    //Parse Rows (Skip Header)
    for (final row in csvRows.skip(1)) {
      //Password
      final password = Password(
        id: const Uuid().v4(),
        name: row[0],
        password: row[3],
      );

      //URL
      final url = row[1];

      //Add Password to Group
      if (groupedPasswords.containsKey(url)) {
        groupedPasswords[url]!.add(password);
      } else {
        groupedPasswords[url] = [password];
      }
    }

    //Return Grouped Passwords
    return groupedPasswords;
  }

  ///Add Password with Group
  static Future<bool> addWithGroup({
    required Password password,
    required String groupID,
  }) async {
    //Added Status
    bool added = false;

    //Add Password
    final addedPwd = (await _supabase.from("passwords").insert(
      {
        "id": password.id,
        "name": password.name,
        "password": password.password,
        "uid": _currentUserID,
      },
    ).select())
        .isNotEmpty;

    //Add Relationship with Group
    final addedRel = (await _supabase.from("group_passwords").insert({
      "group_id": groupID,
      "password_id": password.id,
      "uid": _currentUserID,
    }).select())
        .isNotEmpty;

    //Check if All is Good
    if (addedPwd && addedRel) {
      added = true;
    }

    //Return Added Status
    return added;
  }

  ///Get All Passwords
  static Future<List<Password>> getAll() async {
    //Passwords
    List<Password> passwords = [];

    //Database Passwords
    final dbPwds =
        await _supabase.from("passwords").select().eq("uid", _currentUserID);

    //Parse Passwords
    for (final dbPwd in dbPwds) {
      //Password
      final password = Password.fromJSON(dbPwd);

      //Add Password to List
      passwords.add(password);
    }

    //Return Passwords
    return passwords;
  }
}
