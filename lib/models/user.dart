import 'dart:convert';

List<User> userFromJson(String str) =>
    List<User>.from(json.decode(str).map((x) => User.fromJson(x)));

String userToJson(List<User> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
  final String userId;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String name;
  final String birthday;
  bool isAdmin;

  User({
    this.userId,
    this.email,
    this.firstName,
    this.middleName,
    this.lastName,
    this.suffix,
    this.name,
    this.birthday,
    this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      name: json['name'],
      birthday: json['birthday'],
      isAdmin: json['is_admin'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': userId,
        'email': email,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'suffix': suffix,
        'name': name,
        'birthday': birthday,
        'is_admin': isAdmin,
      };
}
