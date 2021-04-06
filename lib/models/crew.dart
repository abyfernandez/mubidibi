import 'dart:convert';

List<Crew> crewFromJson(String str) =>
    List<Crew>.from(json.decode(str).map((x) => Crew.fromJson(x)));

String crewToJson(List<Crew> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Crew {
  final int crewId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String birthplace;
  final String displayPic;
  final List<String> photos;
  final String description;

  Crew(
      {this.crewId,
      this.firstName,
      this.middleName,
      this.lastName,
      this.birthday,
      this.birthplace,
      this.displayPic,
      this.photos,
      this.description});

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      crewId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      birthday: json['birthday'],
      birthplace: json['birthplace'],
      displayPic: json['display_pic'],
      photos: json["photos"] == null
          ? null
          : List<String>.from(json["photos"].map((x) => x)),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": crewId,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "birthday": birthday,
        "birthplace": birthplace,
        "display_pic": displayPic,
        "photos": photos,
        "description": description
      };
}
