import 'dart:convert';

List<Movie> movieFromJson(String str) =>
    List<Movie>.from(json.decode(str).map((x) => Movie.fromJson(x)));

String movieToJson(List<Movie> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Movie {
  final int movieId;
  final String title;
  final String synopsis;
  final num runtime;
  final String poster;
  final List<dynamic> genre;
  final List<String> screenshot;
  final String releaseDate;
  final String addedBy;
  final bool isDeleted;

  Movie(
      {this.movieId,
      this.title,
      this.synopsis,
      this.runtime,
      this.poster,
      this.genre,
      this.screenshot,
      this.releaseDate,
      this.addedBy,
      this.isDeleted});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
        movieId: json['id'],
        title: json['title'],
        synopsis: json['synopsis'],
        runtime: json['runtime'],
        poster: json['poster'],
        genre: json['genre'],
        screenshot: json['screenshot'] == null
            ? null
            : List<String>.from(json["screenshot"].map((x) => x)),
        releaseDate: json['release_date'],
        addedBy: json['added_by'],
        isDeleted: json['is_deleted']);
  }

  Map<String, dynamic> toJson() => {
        "id": movieId,
        "title": title,
        "synopsis": synopsis,
        "runtime": runtime,
        "poster": poster,
        "genre": genre,
        "screenshot": screenshot,
        "release_date": releaseDate,
        "added_by": addedBy,
        "is_deleted": isDeleted,
      };
}
