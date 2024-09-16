import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';

class GroupsList extends StatefulWidget {
  const GroupsList({super.key});

  @override
  State<GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends State<GroupsList> {
  ///All Groups
  List<Group> allGroups = [];

  /// Filtered Groups
  ValueNotifier<List<Group>> filteredGroups = ValueNotifier([]);

  /// Current Query
  String currentQuery = "";

  /// Key for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();

    //Set Filtered Groups
    filteredGroups.value = allGroups;
  }

  /// Filter Groups and Passwords
  void _filterGroups(String query) {
    currentQuery = query.toLowerCase().trim();
    filteredGroups.value = currentQuery.isEmpty
        ? allGroups
        : allGroups.where((group) {
            //Group Name Match
            final groupNameMatches =
                group.name.toLowerCase().contains(currentQuery);

            //Passwords
            final passwords = group.passwords as List<Map<String, dynamic>>;

            //Passwords Match
            final passwordMatches = passwords.any((password) {
              return password["name"].toLowerCase().contains(currentQuery);
            });

            //Return Matches
            return groupNameMatches || passwordMatches;
          }).toList();
  }

  ///Build Password Tile
  Widget _buildListTile(BuildContext context, Group item, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          title: Text(item.name),
          onTap: () => {},
          trailing: IconButton.filled(
            onPressed: () => {},
            color: Theme.of(context).cardColor,
            icon: const Icon(Ionicons.ios_trash_outline),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: CupertinoSearchTextField(
            placeholder: "Search...",
            onChanged: _filterGroups,
          ),
        ),
        const Divider(indent: 40.0, endIndent: 40.0, thickness: 0.4),
        Expanded(
          child: StreamBuilder(
            stream: GroupsHandler.getAllGroups(
              onNewData: (data) {
                if (mounted) {
                  setState(() {
                    allGroups = data;
                    _filterGroups(currentQuery);
                  });
                }
              },
            ),
            builder: (context, snapshot) {
              return ValueListenableBuilder(
                valueListenable: filteredGroups,
                builder: (context, groups, _) {
                  // No Groups
                  if (groups.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Groups",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // List of Groups with Passwords
                  return AnimatedList(
                    key: _listKey,
                    initialItemCount: groups.length,
                    itemBuilder: (context, index, animation) {
                      //Group
                      final group = groups[index];

                      //Item UI
                      return FadeTransition(
                        opacity: animation,
                        child: _buildListTile(context, group, index),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
