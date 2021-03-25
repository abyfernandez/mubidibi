import 'dart:convert';

List<Movie> movieFromJson(String str) =>
    List<Movie>.from(json.decode(str).map((x) => Movie.fromJson(x)));

String movieToJson(List<Movie> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Movie {
  final int movieId;
  final String title;
  final String synopsis;
  final String poster;
  final List<dynamic> genre;
  final String releaseDate;
  final String addedBy;

  Movie({
    this.movieId,
    this.title,
    this.synopsis,
    this.poster,
    this.genre,
    this.releaseDate,
    this.addedBy,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieId: json['id'],
      title: json['title'],
      synopsis: json['synopsis'],
      poster: json['poster'],
      genre: json['genre'],
      releaseDate: json['release_date'],
      addedBy: json['added_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": movieId,
        "title": title,
        "synopsis": synopsis,
        "poster": poster,
        "genre": genre,
        "release_date": releaseDate,
        "added_by": addedBy,
      };
}
