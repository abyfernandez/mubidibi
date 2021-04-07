class User {
  final String userId;
  final String prefix;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String birthday;
  final bool isAdmin;
  // final String photoUrl;

  User({
    this.userId,
    this.prefix,
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
      prefix: json['prefix'],
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
        'prefix': prefix,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'suffix': suffix,
        'birthday': birthday,
        'is_admin': isAdmin,
      };
}
