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
    final currentUserID = AccountHandler.currentUser?.id;

    //Null User ID
    if (currentUserID == null) {
      return Stream.value([]);
    }

    //Return Stream of Decrypted Passwords for Current User
    return _supabase
        .from(table)
        .stream(primaryKey: ["id"])
        .eq(
          "uid",
          currentUserID,
        )
        .map(
          (data) {
            onNewData(data);

            return data;
          },
        );
  }

  ///Remove Data from `table` by `id`
  static Future<void> deleteDataByID({
    required String table,
    required String id,
  }) async {
    await _supabase.from(table).delete().eq("id", id);
  }
}
