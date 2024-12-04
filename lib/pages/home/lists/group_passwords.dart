import 'package:flutter/material.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/widgets/items.dart';
import 'package:vaultify/util/widgets/main.dart';

class GroupPasswords extends StatefulWidget {
  const GroupPasswords({
    super.key,
    required this.groupName,
    required this.passwords,
  });

  ///Group Name
  final String groupName;

  ///Passwords
  final List<Password> passwords;

  @override
  State<GroupPasswords> createState() => _GroupPasswordsState();
}

class _GroupPasswordsState extends State<GroupPasswords> {
  ///Build Password Tile
  Widget _buildListTile(BuildContext context, Password item, int index) {
    return Items.password(password: item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: Text(widget.groupName),
      ),
      body: SafeArea(
        child: widget.passwords.isNotEmpty
            ? ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.passwords.length,
                itemBuilder: (context, index) {
                  //Password
                  final password = widget.passwords[index];

                  //UI
                  return _buildListTile(context, password, index);
                },
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimHandler.asset(animation: "empty", reverse: true),
                    const Text("No Passwords"),
                  ],
                ),
              ),
      ),
    );
  }
}
