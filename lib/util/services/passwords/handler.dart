import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
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
                          "Skipping duplicate password: ${password.name}",
                        );
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

    //Encrypt Password
    final encryptedPwd = await EncryptionHandler.encryptPassword(
      message: password.password,
      publicKey: EncryptionHandler.pemToPublicKey(
        await EncryptionHandler.publicKey ?? "",
      ),
    );

    //Add Password
    final addedPwd = (await _supabase.from("passwords").upsert(
      {
        "id": password.id,
        "name": password.name,
        "encrypted_password": encryptedPwd,
        "uid": _currentUserID,
      },
    ).select())
        .isNotEmpty;

    //Return Accordingly
    added = addedPwd;
    return added;
  }

  ///Get By ID
  static Future<Password> getByID({required String id}) async {
    //Matching Password
    final matPwd =
        (await _supabase.from("passwords").select().eq("id", id).limit(1))[0];

    //Parse Password
    final password = Password.fromJSON(matPwd);

    //Return Password
    return password;
  }

  ///Update Password based on ID
  ///
  ///Will also update Group, if provided.
  static Future<bool> updateByID({
    required Password password,
    Group? group,
  }) async {
    try {
      //Check if Group is Provided
      if (group != null) {
        debugPrint('Group data: ID=${group.id}, Name=${group.name}');
      }

      //Updated
      bool updated = false;
      PostgrestList? groupUpdated;

      //Encrypt Password
      final encryptedPwd = await EncryptionHandler.encryptPassword(
        message: password.password,
        publicKey: EncryptionHandler.pemToPublicKey(
          await EncryptionHandler.publicKey ?? "",
        ),
      );

      //Update Password
      final updateData = {
        "id": password.id,
        "name": password.name,
        "encrypted_password": encryptedPwd,
        "uid": _currentUserID,
      };

      //Update Password
      final updatedPwd = await _supabase
          .from("passwords")
          .update(updateData)
          .eq("id", password.id)
          .select();

      //Updated Group - if Provided
      if (group != null) {
        try {
          //Check if Relation Exists
          final existingRelation = await _supabase
              .from("group_passwords")
              .select()
              .eq("password_id", password.id)
              .limit(1);

          //Group Update Data
          final groupUpdateData = {
            "group_id": group.id,
            "password_id": password.id,
            "uid": _currentUserID,
          };

          //If Relation Doesn't Exist, Insert
          if (existingRelation.isEmpty) {
            groupUpdated = await _supabase
                .from("group_passwords")
                .insert(groupUpdateData)
                .select();
          } else {
            groupUpdated = await _supabase
                .from("group_passwords")
                .update(groupUpdateData)
                .eq("password_id", password.id)
                .select();
          }
        } catch (groupError) {
          return false;
        }
      }

      //Set Updated Status
      updated =
          updatedPwd.isNotEmpty && (group == null || groupUpdated!.isNotEmpty);

      return updated;
    } catch (error) {
      return false;
    }
  }

  ///Add Password with Group
  static Future<bool> addWithGroup({
    required Password password,
    required String groupID,
  }) async {
    try {
      //Public Key
      final publicKeyPem = await EncryptionHandler.publicKey;

      //Check if Public Key is Available
      if (publicKeyPem == null || publicKeyPem.isEmpty) {
        throw Exception("No Public Key Available for Encryption");
      }

      // Parse the public key
      final publicKey = EncryptionHandler.pemToPublicKey(publicKeyPem);

      // Encrypt the password
      final encryptedPassword = await EncryptionHandler.encryptPassword(
        message: password.password,
        publicKey: publicKey,
      );

      // Create new password object with encrypted password
      final encryptedPasswordObj = Password(
        id: password.id,
        name: password.name,
        password: encryptedPassword,
      );

      //Added Status
      bool added = false;

      //Add Password
      final addedPwd = (await _supabase.from("passwords").upsert(
        {
          "id": encryptedPasswordObj.id,
          "name": encryptedPasswordObj.name,
          "encrypted_password": encryptedPasswordObj.password,
          "uid": _currentUserID,
        },
      ).select())
          .isNotEmpty;

      //Add Relationship with Group
      final addedRel = (await _supabase.from("group_passwords").upsert({
        "group_id": groupID,
        "password_id": encryptedPasswordObj.id,
        "uid": _currentUserID,
      }).select())
          .isNotEmpty;

      //Check if All is Good
      if (addedPwd && addedRel) {
        added = true;
      }

      //Return Added Status
      return added;
    } catch (e) {
      debugPrint("Error adding password with group: $e");
      return false;
    }
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

  ///Delete All Passwords
  static Future<void> deleteAll() async {
    //Delete Passwords
    await _supabase.from("passwords").delete().eq("uid", _currentUserID);
  }
}
