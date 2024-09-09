import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vaultify/util/widgets/main.dart';
import 'package:vaultify/util/widgets/team.dart';

class Team extends StatelessWidget {
  const Team({super.key});

  @override
  Widget build(BuildContext context) {
    ///Team Members
    final List<TeamMember> teamMembers = [
      //Dan
      TeamMember(
        icon: Ionicons.ios_git_branch,
        name: "DanFQ",
        position: "Programmer",
        url: "https://github.com/danfq",
      ),

      //VEIGA
      TeamMember(
        icon: Ionicons.ios_brush,
        name: "VEIGA",
        position: "Design & iOS QA Testing",
        url: "https://instagram.com/veigadesigns",
      ),

      //Mati
      TeamMember(
        icon: Fontisto.test_tube_alt,
        name: "MatiFFQ",
        position: "Android QA Testing",
        url: "https://instagram.com/tide_ff",
      ),

      //Inês Pratas
      TeamMember(
        icon: Fontisto.test_tube_alt,
        name: "Inês Pratas",
        position: "iOS QA Testing",
        url: "https://instagram.com/seni_satarp",
      ),

      //Inês Costa
      TeamMember(
        icon: Fontisto.test_tube_alt,
        name: "Inês Costa",
        position: "iOS QA Testing",
        url: "https://instagram.com/1nescosta",
      ),
    ];

    //Helper function to create SettingsTile
    SettingsTile createTeamTile(TeamMember member) {
      return SettingsTile.navigation(
        leading: Icon(member.icon),
        title: Text(member.name),
        onPressed: (context) {
          launchUrl(Uri.parse(member.url));
        },
      );
    }

    //UI
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Team")),
      body: SafeArea(
        child: SettingsList(
          physics: const BouncingScrollPhysics(),
          lightTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          darkTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          sections: [
            //Programmers
            SettingsSection(
              title: const Text("Programmers"),
              tiles: [
                createTeamTile(teamMembers[0]), //DanFQ
              ],
            ),

            //Design & iOS QA Testing
            SettingsSection(
              title: const Text("Design"),
              tiles: [
                createTeamTile(teamMembers[1]), //VEIGA
              ],
            ),

            //iOS QA Testing
            SettingsSection(
              title: const Text("iOS QA Testing"),
              tiles: [
                createTeamTile(teamMembers[3]), //Inês Pratas
                createTeamTile(teamMembers[4]), //Inês Costa
              ],
            ),

            //Android QA Testing
            SettingsSection(
              title: const Text("Android QA Testing"),
              tiles: [
                createTeamTile(teamMembers[2]), //MatiFFQ
              ],
            ),
          ],
        ),
      ),
    );
  }
}
