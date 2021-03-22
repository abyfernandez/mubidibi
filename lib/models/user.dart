class User {
  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final bool isAdmin;
  // final String photoUrl;

  User({
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.birthday,
    this.isAdmin,
    // this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      birthday: json['birthday'],
      isAdmin: json['is_admin'],
      // photoUrl: json['photo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': userId,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        // 'photo': photoUrl,
        'birthday': birthday,
        'is_admin': isAdmin,
      };
}
