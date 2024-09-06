import 'package:flutter/material.dart';
import 'package:vaultify/util/widgets/main.dart';

class GetPremium extends StatelessWidget {
  const GetPremium({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Vaultify Premium")),
    );
  }
}
