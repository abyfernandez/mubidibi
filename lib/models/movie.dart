import 'dart:convert';
import 'package:mubidibi/models/line.dart';
import 'package:mubidibi/models/media_file.dart';

List<Movie> movieFromJson(String str) =>
    List<Movie>.from(json.decode(str).map((x) => Movie.fromJson(x)));

String movieToJson(List<Movie> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Movie {
  final int movieId;
  final String title;
  final String synopsis;
  final num runtime;
  final List<dynamic> genre;
  final List<MediaFile> posters;
  final List<MediaFile> gallery;
  final List<MediaFile> trailers;
  final List<MediaFile> audios;
  final List<Line> quotes;
  final String releaseDate;
  final String addedBy;
  final bool isDeleted;
  final List<dynamic> role; // for crew view purposes only

  Movie({
    this.movieId,
    this.title,
    this.synopsis,
    this.runtime,
    this.posters,
    this.genre,
    this.gallery,
    this.trailers,
    this.audios,
    this.quotes,
    this.releaseDate,
    this.addedBy,
    this.isDeleted,
    this.role,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieId: json['id'],
      title: json['title'],
      synopsis: json['synopsis'],
      runtime: json['runtime'],
      posters: json['posters'] == null
          ? null
          : List<MediaFile>.from(
              json["posters"].map((x) => MediaFile.fromJson(x))),
      gallery: json['gallery'] == null
          ? null
          : List<MediaFile>.from(
              json["gallery"].map((x) => MediaFile.fromJson(x))),
      trailers: json['trailers'] == null
          ? null
          : List<MediaFile>.from(
              json["trailers"].map((x) => MediaFile.fromJson(x))),
      audios: json['audios'] == null
          ? null
          : List<MediaFile>.from(
              json["audios"].map((x) => MediaFile.fromJson(x))),
      quotes: json['quotes'] == null
          ? null
          : List<Line>.from(json["quotes"].map((x) => Line.fromJson(x))),
      genre: json['genre'],
      releaseDate: json['release_date'],
      addedBy: json['added_by'],
      isDeleted: json['is_deleted'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": movieId,
        "title": title,
        "synopsis": synopsis,
        "runtime": runtime,
        "posters": posters,
        "genre": genre,
        "gallery": gallery,
        "trailers": trailers,
        "audios": audios,
        "release_date": releaseDate,
        "added_by": addedBy,
        "is_deleted": isDeleted,
        "role": role,
      };
}
