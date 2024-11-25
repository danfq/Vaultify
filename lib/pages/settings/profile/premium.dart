import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/main.dart';

class GetPremium extends StatefulWidget {
  const GetPremium({super.key});

  @override
  State<GetPremium> createState() => _GetPremiumState();
}

class _GetPremiumState extends State<GetPremium> {
  ///Premium Status
  bool? premiumStatus;
  bool _isLoading = true;

  ///Get Premium Status
  Future<void> getPremiumStatus() async {
    //Premium Status
    final status = await PremiumHandler.checkPremium();

    //Set Status
    setState(() {
      premiumStatus = status;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    //Get Premium Status
    getPremiumStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Vaultify Premium")),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _isLoading
            ? Container(key: const ValueKey("loading"))
            : SafeArea(
                key: const ValueKey("content"),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    //Icon
                    const Icon(Ionicons.ios_shield, size: 100.0),

                    //Spacing
                    const SizedBox(height: 60.0),

                    //Current Status
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            premiumStatus ?? false
                                ? Ionicons.ios_star
                                : Ionicons.ios_star_outline,
                          ),
                          title: const Text("Status"),
                          trailing: Text(
                            premiumStatus ?? false ? "Premium" : "Standard",
                          ),
                        ),
                      ),
                    ),

                    //Spacing
                    const SizedBox(height: 20.0),

                    //Thanks
                    Text(premiumStatus ?? false
                        ? "Thanks for your support!"
                        : ""),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _isLoading
          ? null
          : Padding(
              padding: const EdgeInsets.all(40.0),
              child: Buttons.elevated(
                enabled: !(premiumStatus ?? false),
                text: premiumStatus ?? false ? "Already Premium" : "Go Premium",
                onTap: () async {
                  //Purchase Premium
                  final status = await PremiumHandler.purchasePremium();

                  //Set Premium Status
                  await LocalData.updateValue(
                    box: "premium",
                    item: "status",
                    value: status,
                  );

                  setState(() {
                    premiumStatus = status;
                  });

                  //Notify User Accordingly
                  if (premiumStatus ?? true) {
                    ToastHandler.toast(message: "Thanks for your support!");
                  }
                },
              ),
            ),
    );
  }
}
