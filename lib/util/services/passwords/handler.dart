import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
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
    // Number of Imported Passwords
    int importedPwds = 0;

    // User Passwords
    final usrPwds = await getAll();

    // User Groups
    final userGroups = await GroupsHandler.getAllGroups(
      onNewData: (_) {},
    ).first;

    // Check if File Exists
    if (await file.exists()) {
      // Check if File is CSV
      if (file.path.endsWith(".csv")) {
        try {
          // Parse Passwords
          final parsedData = await _parseCSVFile(file);

          // Check Passwords
          if (parsedData.isNotEmpty) {
            // Create Passwords & Respective Groups
            for (final entry in parsedData.entries) {
              // Group Name
              final groupName = entry.key;

              // Passwords
              final passwords = entry.value;

              // Check if Group already exists
              final groupExists =
                  userGroups.any((group) => group?.name == groupName);

              // If Group doesn't exist, create a new group
              if (!groupExists) {
                await GroupsHandler.addGroup(name: groupName)
                    .then((group) async {
                  // Check Group
                  if (group != null) {
                    // Add Passwords to Group
                    for (final password in passwords) {
                      // Check if Password already exists in the user's saved passwords
                      final duplicate = usrPwds.any((usrPwd) =>
                          usrPwd.name == password.name &&
                          usrPwd.password == password.password);

                      // Skip if duplicate found
                      if (duplicate) {
                        debugPrint(
                            "Skipping duplicate password: ${password.name}");
                        continue;
                      }

                      // Add password if no duplicate found
                      await addWithGroup(password: password, groupID: group.id);
                      importedPwds++;
                    }
                  } else {
                    ToastHandler.toast(message: "Failed to Create Group");
                    debugPrint("Failed to Create Group");
                  }
                });
              } else {
                //Check for Existing Group
                final Group? existingGroup = userGroups.firstWhere(
                  (group) => group?.name == groupName,
                  orElse: () => null,
                );

                // Add Passwords to the existing group
                for (final password in passwords) {
                  // Check if Password already exists in the user's saved passwords
                  final duplicate = usrPwds.any((usrPwd) =>
                      usrPwd.name == password.name &&
                      usrPwd.password == password.password);

                  // Skip if duplicate found
                  if (duplicate) {
                    debugPrint("Skipping duplicate password: ${password.name}");
                    continue;
                  }

                  // Add password if no duplicate found
                  await addWithGroup(
                    password: password,
                    groupID: existingGroup!.id,
                  );

                  //Increase Imported Passwords
                  importedPwds++;
                }
              }
            }
          } else {
            ToastHandler.toast(message: "No Passwords in File");
            debugPrint("No Passwords in File");
          }
        } catch (error) {
          ToastHandler.toast(message: "Error Parsing CSV: $error.");
          debugPrint("Error Parsing CSV: $error.");
        }
      } else {
        debugPrint("Invalid CSV");

        // File Isn't Valid CSV - Return False
        importedPwds = 0;
      }
    } else {
      debugPrint("File Doesn't Exist");

      // File Doesn't Exist - Return False
      importedPwds = 0;
    }

    // Return Imported Status
    return importedPwds;
  }

  /// Helper function to parse the CSV file
  static Future<Map<String, List<Password>>> _parseCSVFile(File file) async {
    //CSV Content
    final csvContents = await file.readAsString();
    final csvRows = csvContents.split("\n");

    //Grouped Passwords
    final Map<String, List<Password>> groupedPasswords = {};

    //Parse Rows (Skip Header)
    for (int i = 1; i < csvRows.length; i++) {
      // Current Row
      final row = csvRows[i];

      // Skip Empty Rows
      if (row.isEmpty) {
        continue;
      }

      // Split to Get Fields
      final fields = row.split(",");

      // Ensure Valid Rows Only (4 Fields)
      if (fields.length < 4) {
        debugPrint("Skipping invalid row: $fields");
        continue;
      }

      // Extract Values
      final name = fields[2].trim();
      final url = fields[1].trim();
      final passwordValue = fields[3].trim();

      // Check URL
      if (url.isEmpty) {
        debugPrint("Skipping row with empty URL: $fields");
        continue;
      }

      //Extract Site from URL
      final site = _extractSiteFromURL(url);

      //Invalid URL - Skip
      if (site.isEmpty) {
        debugPrint("Skipping row with invalid URL: $url");
        continue;
      }

      //Password object
      final password = Password(
        id: const Uuid().v4(),
        name: name,
        password: passwordValue,
      );

      //Add Password to Map
      groupedPasswords.putIfAbsent(site, () => []).add(password);
    }

    //Debug
    debugPrint(groupedPasswords.toString());

    //Return Grouped Passwords
    return groupedPasswords;
  }

  ///Extract Site from URL
  static String _extractSiteFromURL(String url) {
    //Remove HTTPS & Such
    final uri = Uri.tryParse(url);

    //Check if URI is Null
    if (uri != null) {
      //Return URL Without Sub-Paths
      return uri.host;
    }

    //Return Empty String if Invalid URL
    return "";
  }

  ///Add Password
  static Future<bool> add({required Password password}) async {
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

    //Return Accordingly
    added = addedPwd;
    return added;
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
