import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';

///Toast Handler
class ToastHandler {
  ///Show Platform-Adaptive Toast with `message`
  static void toast({
    required String message,
  }) {
    toastification.show(
      title: const Text("Heads Up!"),
      description: Text(message),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }
}
