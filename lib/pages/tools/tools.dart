import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/tools/generate/generate.dart';
import 'package:vaultify/util/widgets/buttons.dart';

class Tools extends StatelessWidget {
  const Tools({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: 20.0,
      children: [
        //Generate Password
        Center(
          child: Buttons.elevatedIcon(
            text: "Generate Password",
            icon: Ionicons.ios_lock_open_outline,
            onTap: () => showModalBottomSheet(
              showDragHandle: true,
              isScrollControlled: true,
              context: context,
              builder: (context) => const SizedBox(
                width: double.infinity,
                child: GeneratePassword(),
              ),
            ),
          ),
        ),

        //Check For Leaks
        Center(
          child: Buttons.elevatedIcon(
            text: "Check For Leaks",
            icon: MaterialCommunityIcons.pipe_leak,
            onTap: () => showModalBottomSheet(
              showDragHandle: true,
              isScrollControlled: true,
              context: context,
              builder: (context) => const SizedBox(
                width: double.infinity,
                child: GeneratePassword(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
