import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:vaultify/util/models/password.dart';

///Group
class Group with CustomDropdownListFilter {
  ///ID
  final String id;

  ///Name
  final String name;

  ///Passwords
  final List<dynamic> passwords;

  ///User ID
  final String uid;

  ///Group
  Group({
    required this.id,
    required this.name,
    required this.passwords,
    required this.uid,
  });

  ///JSON Object to `Group`
  factory Group.fromJSON(Map<dynamic, dynamic> json) {
    return Group(
      id: json["id"],
      name: json["name"],
      passwords: json["passwords"],
      uid: json["uid"],
    );
  }

  ///`Group` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "name": name,
      "passwords": passwords,
      "uid": uid,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}
