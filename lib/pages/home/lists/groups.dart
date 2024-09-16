import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/services/groups/handler.dart';

class GroupsList extends StatefulWidget {
  const GroupsList({super.key});

  @override
  State<GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends State<GroupsList> {
  /// All Groups
  List<Group> allGroups = [];

  /// Filtered Groups
  List<Group> filteredGroups = [];

  /// Current Query
  String currentQuery = "";

  @override
  void initState() {
    super.initState();
    _listenForGroupChanges();
  }

  /// Listen for real-time group changes from the database
  void _listenForGroupChanges() {
    GroupsHandler.getAllGroups(
      onNewData: (data) {},
    ).listen((newGroups) {
      setState(() {
        allGroups = List.from(newGroups);
        _filterGroups(currentQuery); // Ensure filtering is applied to new data
      });
    });
  }

  /// Filter Groups and Passwords
  void _filterGroups(String query) {
    currentQuery = query.toLowerCase().trim();
    setState(() {
      filteredGroups = currentQuery.isEmpty
          ? allGroups
          : allGroups.where((group) {
              final groupNameMatches =
                  group.name.toLowerCase().contains(currentQuery);

              final passwords = group.passwords;

              final passwordMatches = passwords.any((password) {
                return password.name.toLowerCase().contains(currentQuery);
              });

              return groupNameMatches || passwordMatches;
            }).toList();
    });
  }

  /// Build Group Tile
  Widget _buildListTile(BuildContext context, Group group, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          title: Text(group.name),
          onTap: () => {},
          trailing: IconButton.filled(
            onPressed: () => _deleteGroup(group, index),
            color: Theme.of(context).cardColor,
            icon: const Icon(Ionicons.ios_trash_outline),
          ),
        ),
      ),
    );
  }

  /// Delete Group (remove from list)
  void _deleteGroup(Group group, int index) async {
    final deleted = await GroupsHandler.deleteGroup(groupID: group.id);

    if (deleted) {
      setState(() {
        allGroups.removeAt(index);
        _filterGroups(currentQuery); // Re-filter after deletion
      });
    }
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
              ? const Center(
                  child: Text(
                    "No Groups\nAdd One by Tapping +",
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    return _buildListTile(context, group, index);
                  },
                ),
        ),
      ],
    );
  }
}
