///Group Password
class GroupPassword {
  ///Group ID
  final String groupID;

  ///Password ID
  final String passwordID;

  ///Group Password
  GroupPassword({required this.groupID, required this.passwordID});

  ///JSON Object to `GroupPassword`
  factory GroupPassword.fromJSON(Map<String, dynamic> json) {
    return GroupPassword(
      groupID: json["group_id"],
      passwordID: json["password_id"],
    );
  }

  ///`Group` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "group_id": groupID,
      "password_id": passwordID,
    };
  }
}
