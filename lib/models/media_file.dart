// Movie Media Class

import 'dart:io';

class MediaFile {
  int id;
  int movieId;
  int crewId;
  String url;
  String description;
  String type; // poster, gallery, trailer, audio, display_pic
  File file;
  String category; // movie or crew
  String format; // resource type provided by cloudinary
  bool saved;

  MediaFile({
    this.id,
    this.movieId,
    this.crewId,
    this.url,
    this.description,
    this.type,
    this.file,
    this.category,
    this.format,
    this.saved,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
        id: json['id'],
        movieId: json['movie_id'],
        crewId: json['crew_id'],
        url: json['url'],
        description: json['description'],
        type: json['type'],
        category: json['crew_id'] == null
            ? (json['movie_id'] == null ? null : 'movie')
            : 'crew',
        format: json['format']);
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "movie_id": movieId,
        "crew_id": crewId,
        "url": url,
        "description": description,
        "type": type,
        "category": category,
        "format": format,
      };
}
