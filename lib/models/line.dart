// Line Class (iconic lines)

class Line {
  int id;
  int movieId;
  String line;
  String role;
  bool saved;

  Line({
    this.id,
    this.movieId,
    this.line,
    this.role,
    this.saved,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      id: json['id'],
      movieId: json['movie_id'],
      line: json['quotation'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() =>
      {"id": id, "movie_id": movieId, "quotation": line, "role": role};
}
