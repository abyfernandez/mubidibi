import 'dart:convert';
import 'package:mubidibi/models/media_file.dart';
import './movie.dart';

List<Crew> crewFromJson(String str) =>
    List<Crew>.from(json.decode(str).map((x) => Crew.fromJson(x)));

String crewToJson(List<Crew> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Crew {
  int id;
  int crewId;
  String firstName;
  String middleName;
  String lastName;
  String suffix;
  String name;
  final String birthday;
  final String deathdate;
  final bool isAlive;
  final String birthplace;
  final MediaFile displayPic;
  final List<MediaFile> gallery;
  final String description;
  List<dynamic> role; // roles in movies
  List<dynamic> type; // direktor/manunulat/aktor
  List<List<Movie>> movies;
  final bool isDeleted;
  bool saved;
  bool edit;

  Crew(
      {this.id,
      this.crewId,
      this.firstName,
      this.middleName,
      this.lastName,
      this.suffix,
      this.name,
      this.birthday,
      this.deathdate,
      this.isAlive,
      this.birthplace,
      this.displayPic,
      this.gallery,
      this.description,
      this.role,
      this.type,
      this.movies,
      this.isDeleted,
      this.saved,
      this.edit});

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'],
      crewId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      name: json['name'],
      birthday: json['birthday'],
      deathdate: json['deathdate'],
      isAlive: json['is_alive'],
      birthplace: json['birthplace'],
      displayPic: json['display_pic'] == null
          ? null
          : MediaFile.fromJson(json['display_pic']),
      gallery: json["gallery"] == null
          ? []
          : List<MediaFile>.from(
              json["gallery"].map((x) => MediaFile.fromJson(x))),
      description: json['description'],
      role: json["role"] == null ? [] : json["role"],
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
        "id": id,
        "crew_id": crewId,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "suffix": suffix,
        "name": name,
        "birthday": birthday,
        "deathdate": deathdate,
        "is_alive": isAlive,
        "birthplace": birthplace,
        "display_pic": displayPic,
        "gallery": gallery,
        "description": description,
        "role": role,
        "type": type,
        "movies": movies,
        "is_deleted": isDeleted,
        "edit": edit,
      };
}
