///Password Item
class PasswordItem {
  ///ID
  final String id;

  ///Name
  final String name;

  ///Password
  final String password;

  ///Password Item
  PasswordItem({required this.id, required this.name, required this.password});

  ///`PasswordItem` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "name": name,
      "password": password,
    };
  }

  ///JSON Object to `PasswordItem`
  factory PasswordItem.fromJSON(Map<String, dynamic> json) {
    return PasswordItem(
      id: json["id"],
      name: json["name"],
      password: json["password"],
    );
  }
}
