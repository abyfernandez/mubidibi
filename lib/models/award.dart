import 'dart:convert';

List<Award> awardFromJson(String str) =>
    List<Award>.from(json.decode(str).map((x) => Award.fromJson(x)));

String awardToJson(List<Award> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Award {
  int id; // id from the award table
  int awardId; // id from the crew_media and movie_media award table
  final int movieId; // movie_award.movie_id
  final int crewId; // crew_award.crew_id
  String name;
  String event;
  List<String> category; // movie, actor
  String year;
  String type; //  nominated, panalo
  String description;
  final String addedBy;
  bool isDeleted;
  bool saved;

  Award({
    this.id,
    this.awardId,
    this.movieId,
    this.crewId,
    this.name,
    this.event,
    this.category,
    this.year,
    this.type,
    this.description,
    this.addedBy,
    this.isDeleted,
    this.saved,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
        id: json['id'],
        awardId: json['award_id'],
        movieId: json['movie_id'],
        crewId: json['crew_id'],
        name: json['name'],
        event: json['event'],
        category: json["category"] == null
            ? []
            : List<String>.from(json["category"].map((x) => x)),
        year: json['year'] != null ? json['year'].toString() : null,
        type: json['type'],
        description: json['description'],
        addedBy: json['added_by'],
        isDeleted: json['is_deleted']);
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "award_id": awardId,
        "movie_id": movieId,
        "crew_id": crewId,
        "name": name,
        "event": event,
        "category": category,
        "year": year,
        "type": type,
        "description": description,
        "added_by": addedBy,
        "is_deleted": isDeleted,
      };
}
