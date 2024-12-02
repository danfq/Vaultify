import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/util/services/account/handler.dart';

///Remote Data
class RemoteData {
  ///Supabase Instance
  static final SupabaseClient _supabase = Supabase.instance.client;

  ///Add `data` to `table`.
  ///
  ///Returns `bool` according to success.
  static Future<bool> addData({
    required String table,
    required Map data,
  }) async {
    //Data Added Status
    bool dataAdded = false;

    //Attempt to Add Data
    try {
      await _supabase.from(table).upsert(data).select().then(
        (data) {
          //Return True if Data is Not Empty
          dataAdded = data.isNotEmpty;
        },
      );
    } on Exception catch (error) {
      //Debug
      debugPrint(error.toString());

      //Return False
      dataAdded = false;
    }

    //Return Data Added Status
    return dataAdded;
  }

  ///Get Data
  static Stream<List<Map<String, dynamic>>> getData({
    required String table,
    required Function(List<Map<String, dynamic>> data) onNewData,
  }) {
    //Current User ID
    final currentUserID =
        AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

    //Null User ID
    if (currentUserID == null) {
      return Stream.value([]);
    }

    //Attempt to Return Data
    try {
      //Return Data Stream
      return _supabase
          .from(table)
          .stream(primaryKey: ["id"])
          .eq(
            "uid",
            currentUserID.trim(),
          )
          .map(
            (data) {
              onNewData(data);

              return data;
            },
          );
    } on Exception catch (_) {
      return Stream.value([]);
    }
  }

  ///Update Data by ID on Table
  static Future<bool> updateData({
    required String table,
    required String id,
    required Map data,
  }) async {
    //Upsert Data
    final updated = (await _supabase
            .from(table)
            .upsert(data)
            .eq("id", id)
            .select()
            .limit(1))
        .isNotEmpty;

    //Return if Added
    return updated;
  }

  ///Remove Data from `table` by `id`
  static Future<void> deleteDataByID({
    required String table,
    required String id,
    bool? isPassword,
  }) async {
    try {
      //Delete Group Password Relationship
      if (isPassword == true) {
        //Delete Group Password Relationship
        await _supabase.from("group_passwords").delete().eq("password_id", id);

        //Add Small Delay
        await Future.delayed(const Duration(milliseconds: 100));
      }

      //Delete Data
      await _supabase.from(table).delete().eq("id", id);
    } catch (e) {
      debugPrint('Error deleting data: $e');
      rethrow; // Rethrow to handle in calling code
    }
  }
}
