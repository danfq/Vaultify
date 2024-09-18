import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class EditGroup extends StatefulWidget {
  const EditGroup({super.key, required this.group});

  ///Group
  final Group group;

  @override
  State<EditGroup> createState() => _EditGroupState();
}

class _EditGroupState extends State<EditGroup> {
  ///Name Controller
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: Text(widget.group.name)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Name
              Input(
                controller: _nameController,
                placeholder: "New Name (${widget.group.name})",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Buttons.elevatedIcon(
          text: "Save Changes",
          icon: Ionicons.ios_save,
          onTap: () async {
            //Name
            final newName = _nameController.text.trim();

            if (newName.isNotEmpty) {
              //New Group Data
              final groupData = Group(
                id: widget.group.id,
                name: newName,
                uid: widget.group.uid,
              );

              //Update Group Data
              await RemoteData.updateData(
                table: "groups",
                id: widget.group.id,
                data: {
                  "id": groupData.id,
                  "name": groupData.name,
                  "uid": groupData.uid,
                },
              );

              //Go Back
              Get.back();
            }
          },
        ),
      ),
    );
  }
}
