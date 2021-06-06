import 'dart:convert';

List<Award> awardFromJson(String str) =>
    List<Award>.from(json.decode(str).map((x) => Award.fromJson(x)));

String awardToJson(List<Award> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Award {
  int awardId;
  final int movieId;
  String name;
  List<String> category; // movie, actor
  String year;
  String type; //  nominated, won
  String description;
  final String addedBy;
  bool isDeleted;
  bool saved;

  Award({
    this.awardId,
    this.movieId,
    this.name,
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
        awardId: json['id'],
        movieId: json['movie_id'],
        name: json['name'],
        category: json["category"] == null
            ? []
            : List<String>.from(json["category"].map((x) => x)),
        year: json['year'].toString(),
        type: json['award_type'],
        description: json['description'],
        addedBy: json['added_by'],
        isDeleted: json['is_deleted']);
  }

  Map<String, dynamic> toJson() => {
        "id": awardId,
        "movie_id": movieId,
        "name": name,
        "category": category,
        "year": year,
        "award_type": type,
        "description": description,
        "added_by": addedBy,
        "is_deleted": isDeleted,
      };
}
