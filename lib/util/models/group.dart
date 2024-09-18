import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:vaultify/util/models/password.dart';

///Group
class Group with CustomDropdownListFilter {
  ///ID
  final String id;

  ///Name
  final String name;

  ///Passwords
  final List<Password>? passwords;

  ///User ID
  final String uid;

  ///Group
  Group({
    required this.id,
    required this.name,
    this.passwords,
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

  ///Return Altered Group
  Group copyWith({
    String? id,
    String? name,
    List<Password>? passwords,
    String? uid,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      passwords: passwords ?? this.passwords,
      uid: uid ?? this.uid,
    );
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
