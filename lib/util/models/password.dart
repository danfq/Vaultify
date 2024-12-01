///Password Item
class Password {
  ///ID
  final String id;

  ///Name
  final String name;

  ///Password
  final String password;

  ///Password Item
  Password({required this.id, required this.name, required this.password});

  ///`Password` to JSON Object
  Map<String, dynamic> toJSON() {
    return {
      "id": id,
      "name": name,
      "encrypted_password": password,
    };
  }

  ///JSON Object to `Password`
  factory Password.fromJSON(Map<dynamic, dynamic> json) {
    return Password(
      id: json["id"],
      name: json["name"],
      password: json["encrypted_password"],
    );
  }
}
