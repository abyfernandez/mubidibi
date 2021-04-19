import 'dart:convert';

List<Crew> crewFromJson(String str) =>
    List<Crew>.from(json.decode(str).map((x) => Crew.fromJson(x)));

String crewToJson(List<Crew> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Crew {
  final int crewId;
  final String prefix;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String birthday;
  final bool isAlive;
  final String birthplace;
  final String displayPic;
  final List<String> photos;
  final String description;
  final List<String> role;

  Crew(
      {this.crewId,
      this.prefix,
      this.firstName,
      this.middleName,
      this.lastName,
      this.suffix,
      this.birthday,
      this.isAlive,
      this.birthplace,
      this.displayPic,
      this.photos,
      this.description,
      this.role});

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      crewId: json['id'],
      prefix: json['prefix'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      birthday: json['birthday'],
      isAlive: json['is_alive'],
      birthplace: json['birthplace'],
      displayPic: json['display_pic'],
      photos: json["photos"] == null
          ? []
          : List<String>.from(json["photos"].map((x) => x)),
      description: json['description'],
      role: json["role"] == null
          ? []
          : List<String>.from(json["role"].map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": crewId,
        "prefix": prefix,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "suffix": suffix,
        "birthday": birthday,
        "is_alive": isAlive,
        "birthplace": birthplace,
        "display_pic": displayPic,
        "photos": photos,
        "description": description,
        "role": role,
      };
}
