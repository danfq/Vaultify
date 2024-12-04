import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/widgets/items.dart';

class PasswordsList extends StatefulWidget {
  const PasswordsList({super.key});

  @override
  State<PasswordsList> createState() => _PasswordsListState();
}

class _PasswordsListState extends State<PasswordsList> {
  ///All Passwords
  List<Map<String, dynamic>> allPasswords =
      LocalData.boxData(box: "passwords")["list"] ?? [];

  ///Filtered Passwords
  ValueNotifier<List<Map>> filteredPasswords = ValueNotifier([]);

  ///Current Query
  String currentQuery = "";

  /// Key for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    filteredPasswords.value = allPasswords;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listKey.currentState != null) {
        setState(() {});
      }
    });
  }

  ///Filter Passwords
  void _filterPasswords(String query) {
    currentQuery = query.toLowerCase().trim();
    filteredPasswords.value = currentQuery.isEmpty
        ? allPasswords
        : allPasswords.where((item) {
            return item["name"].toLowerCase().contains(currentQuery);
          }).toList();
  }

  ///Build Password Tile
  Widget _buildListTile(BuildContext context, Password item, int index) {
    return Items.password(password: item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: CupertinoSearchTextField(
            placeholder: "Search...",
            onChanged: _filterPasswords,
          ),
        ),
        const Divider(indent: 40.0, endIndent: 40.0, thickness: 0.4),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: RemoteData.getData(
              table: "passwords",
              onNewData: (data) {
                setState(() {
                  allPasswords = data;
                  _filterPasswords(currentQuery);
                });
              },
            ),
            builder: (context, snapshot) {
              // Show empty container while loading
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              return ValueListenableBuilder(
                valueListenable: filteredPasswords,
                builder: (context, passwords, _) {
                  // Show empty animation only if we have data but passwords list is empty
                  if (passwords.isEmpty && allPasswords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimHandler.asset(
                            animation: "empty",
                            reverse: true,
                          ),
                          const Text(
                            "No Passwords\nAdd One by Tapping +",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(begin: 1.0, end: 0.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * value),
                        child: Opacity(
                          opacity: 1 - value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedList(
                      key: _listKey,
                      physics: const BouncingScrollPhysics(),
                      initialItemCount: passwords.length,
                      itemBuilder: (context, index, animation) {
                        if (index >= passwords.length) {
                          return const SizedBox.shrink();
                        }
                        final item = Password.fromJSON(passwords[index]);
                        return FadeTransition(
                          opacity: animation,
                          child: _buildListTile(context, item, index),
                        );
                      },
                    ),
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
