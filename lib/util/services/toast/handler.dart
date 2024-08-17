import 'package:fluttertoast/fluttertoast.dart';

///Toast Handler
class ToastHandler {
  ///Show Platform-Adaptive Toast with `message`
  static void toast({required String message}) async {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      fontSize: 16.0,
    );
  }
}
