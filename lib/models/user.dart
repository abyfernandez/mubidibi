class User {
  final String uid;
  final String firstName;
  final String lastName;
  final String displayName;
  final String photoUrl;
  final String email;
  final String type;

  User({
    this.uid,
    this.firstName,
    this.lastName,
    this.displayName,
    this.photoUrl,
    this.email,
    this.type,
  });

  User.fromData(Map<String, dynamic> data)
      : uid = data['uid'],
        firstName = data['first_name'],
        lastName = data['last_name'],
        displayName = data['first_name'] + " " + data['last_name'],
        photoUrl = data['photo'],
        email = data['email'],
        type = data['type'];

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'photo': photoUrl,
      'email': email,
      'type': type,
    };
  }
}
