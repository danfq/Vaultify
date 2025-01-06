import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

///HIBP Service
class HIBP {
  ///Check if Password is Leaked
  ///
  ///Returns `true` if Password is Leaked
  static Future<bool> checkPassword(String password) async {
    //Generate SHA-1 Hash of Password
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();

    //Split Hash into Prefix (First 5 Chars) and Suffix (Remaining Chars)
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);

    //Query HIBP API with Hash Prefix
    final response = await http.get(
      Uri.parse("https://api.pwnedpasswords.com/range/$prefix"),
    );

    //Check if Hash Suffix Appears in Response
    return response.statusCode == 200 &&
        response.body.toUpperCase().contains(suffix);
  }
}
