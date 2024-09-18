import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/theming/controller.dart';

///Premium Handler
class PremiumHandler {
  ///Stripe Instance
  static final Stripe _stripe = Stripe.instance;

  ///Initialize Service
  static Future<void> init() async {
    //Attempt to Initialize Stripe
    try {
      //Set Pub Key
      Stripe.publishableKey = EnvVars.get(name: "STRIPE_PUB");

      //Set Merchant Identifier
      Stripe.merchantIdentifier = EnvVars.get(name: "APPLE_MER_ID");
    } on StripeError catch (error) {
      throw Exception(error.message);
    }
  }

  ///Purchase Premium
  ///
  ///Returns Payment Status as `bool`
  static Future<bool> purchasePremium() async {
    //Payment Status
    bool status = false;

    //Payment ID
    final paymentID = const Uuid().v4();

    //Payment Intent
    var intent = await _paymentIntent(id: paymentID);

    //Initialize Payment Sheet
    await _stripe.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent["client_secret"],
        googlePay: const PaymentSheetGooglePay(merchantCountryCode: "PT"),
        applePay: const PaymentSheetApplePay(merchantCountryCode: "PT"),
        style: ThemeController.current(context: Get.context!)
            ? ThemeMode.dark
            : ThemeMode.light,
        merchantDisplayName: "DanFQ",
      ),
    );

    //Attempt to Receive Payment
    try {
      //Show Payment Sheet
      await _stripe.presentPaymentSheet().then((_) async {
        //Clear Intent
        intent = null;

        //Set User as Premium
        final premiumStatus = await _setUserPremium();

        //Set Status
        status = premiumStatus;
      });
    } on StripeException catch (_) {
      status = false;
    }

    //Return Status
    return status;
  }

  ///Check if User is Premium
  ///
  ///Returns `bool` Accordingly
  static Future<bool> checkPremium() async {
    //User Data
    final userData = await AccountHandler.getUserData();

    //Check Data
    if (userData.isNotEmpty) {
      return userData["premium"];
    } else {
      return false;
    }
  }

  ///Generate Payment Intent
  static Future<dynamic> _paymentIntent({required String id}) async {
    try {
      //Payment Payload
      Map<String, dynamic> body = {
        "amount": (5 * 100).toInt().toString(), //5 EUR
        "currency": "EUR",
        "description": id,
      };

      //Stripe Payment Request
      var response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          "Authorization": "Bearer ${EnvVars.get(name: "STRIPE_SEC")}",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  ///Set User as Premium
  static Future<bool> _setUserPremium() async {
    //Current User ID
    final userID = AccountHandler.currentUser?.id;

    //Set as Premium
    final status = await RemoteData.addData(
      table: "users",
      data: {"id": userID, "premium": true},
    );

    //Return Status
    return status;
  }
}
