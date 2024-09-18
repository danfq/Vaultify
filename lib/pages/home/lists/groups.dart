import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/pages/home/lists/group_passwords.dart';

class GroupsList extends StatefulWidget {
  const GroupsList({super.key});

  @override
  State<GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends State<GroupsList> {
  ///List Key
  final Key _listKey = UniqueKey();

  /// All Groups
  List<Group> allGroups = [];

  /// Filtered Groups
  List<Group> filteredGroups = [];

  /// Current Query
  String currentQuery = "";

  /// Stream Subscription
  StreamSubscription<List<Group>>? _groupSubscription;

  /// Set to track expanded groups
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _listenForGroupChanges();
  }

  /// Listen for real-time group changes from the database
  void _listenForGroupChanges() {
    _groupSubscription = GroupsHandler.getAllGroups(
      onNewData: (data) {},
    ).listen((newGroups) {
      if (mounted) {
        setState(() {
          final uniqueGroups = <String, Group>{};

          for (var group in newGroups) {
            // Use both name and ID to ensure uniqueness
            if (!uniqueGroups.containsKey(group.id)) {
              uniqueGroups[group.id] = group;
            }
          }

          allGroups = uniqueGroups.values.toList();
          _filterGroups(currentQuery);

          // Debug
          print("All Groups: $allGroups");
        });
      }
    });
  }

  /// Filter Groups and Passwords
  void _filterGroups(String query) {
    //Current Query
    currentQuery = query.toLowerCase().trim();

    if (mounted) {
      setState(() {
        filteredGroups = currentQuery.isEmpty
            ? allGroups
            : allGroups.where((group) {
                final groupNameMatches =
                    group.name.toLowerCase().contains(currentQuery);

                final passwords = group.passwords;

                final passwordMatches = (passwords ?? []).any((password) {
                  return password.name.toLowerCase().contains(currentQuery);
                });

                return groupNameMatches || passwordMatches;
              }).toList();
      });
    }
  }

  /// Delete Group (remove from list)
  Future<void> _deleteGroup(Group group, int index) async {
    await GroupsHandler.deleteGroup(groupID: group.id).then(
      (deleted) {
        if (deleted) {
          setState(() {
            allGroups.removeWhere((item) => item.id == group.id);
            _filterGroups(currentQuery);
          });
        }
      },
    );
  }

  /// Cancel subscription on dispose
  @override
  void dispose() {
    _groupSubscription?.cancel();
    super.dispose();
  }

  /// Build Group Tile
  Widget _buildListTile(BuildContext context, Group group, int index) {
    //Check if Expanded
    final isExpanded = _expandedGroups.contains(group.id);

    //UI
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              isExpanded
                  ? Ionicons.ios_chevron_down
                  : Ionicons.ios_chevron_forward,
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedGroups.add(group.id);
                } else {
                  _expandedGroups.remove(group.id);
                }
              });
            },
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //See All
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(
                        () => GroupPasswords(
                          groupName: group.name,
                          passwords: group.passwords ?? [],
                        ),
                      )?.then((_) {
                        setState(() {});
                      }),
                      child: const Text(
                        "See All",
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),

              //Passwords
              if (group.passwords == null || group.passwords!.isEmpty)
                const ListTile(
                  title: Text(
                    "No Passwords",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  visualDensity: VisualDensity.compact,
                )
              else
                ...group.passwords!.take(3).map(
                      (password) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              password.name,
                              style: const TextStyle(fontSize: 14.0),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
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
          child: filteredGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimHandler.asset(animation: "empty", reverse: true),
                      const Text(
                        "No Groups\nAdd One by Tapping +",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  key: _listKey,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    //Group
                    final group = filteredGroups[index];

                    //Group UI
                    return _buildListTile(context, group, index);
                  },
                ),
        ),
      ],
    );
  }
}
