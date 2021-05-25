import 'dart:convert';
import './movie.dart';

List<Crew> crewFromJson(String str) =>
    List<Crew>.from(json.decode(str).map((x) => Crew.fromJson(x)));

String crewToJson(List<Crew> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// Crew crewFromJson(String str) => Crew.fromJson(json.decode(str));

// String crewToJson(Crew data) => json.encode(data.toJson());

class Crew {
  int crewId;
  String firstName;
  String middleName;
  String lastName;
  String suffix;
  final String birthday;
  final String deathdate;
  final bool isAlive;
  final String birthplace;
  final String displayPic;
  final List<String> photos;
  final String description;
  List<String> role; // roles in movies
  List<String> type; // direktor/manunulat/aktor
  List<List<Movie>> movies;
  final bool isDeleted;
  bool saved;

  Crew(
      {this.crewId,
      this.firstName,
      this.middleName,
      this.lastName,
      this.suffix,
      this.birthday,
      this.deathdate,
      this.isAlive,
      this.birthplace,
      this.displayPic,
      this.photos,
      this.description,
      this.role,
      this.type,
      this.movies,
      this.isDeleted,
      this.saved});

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      crewId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      birthday: json['birthday'],
      deathdate: json['deathdate'],
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
      type: json["type"] == null
          ? []
          : List<String>.from(json["type"].map((x) => x)),
      movies: json['movies'] == null
          ? []
          : List<List<Movie>>.from(json["movies"]
              .map((x) => List<Movie>.from(x.map((x) => Movie.fromJson(x))))),
      isDeleted: json['is_deleted'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": crewId,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "suffix": suffix,
        "birthday": birthday,
        "deathdate": deathdate,
        "is_alive": isAlive,
        "birthplace": birthplace,
        "display_pic": displayPic,
        "photos": photos,
        "description": description,
        "role": role,
        "type": type,
        "movies": movies,
        "is_deleted": isDeleted
      };
}
