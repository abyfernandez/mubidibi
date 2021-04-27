class User {
  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String birthday;
  final bool isAdmin;

  User({
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.suffix,
    this.birthday,
    this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      birthday: json['birthday'],
      isAdmin: json['is_admin'],
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': userId,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'suffix': suffix,
        'birthday': birthday,
        'is_admin': isAdmin,
      };
}
