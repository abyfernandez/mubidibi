// MovieActor Class

class MovieActor {
  int movieId;
  String movieTitle;
  List<String> role;
  bool saved;

  MovieActor({
    this.movieId,
    this.movieTitle,
    this.role,
    this.saved,
  });

  Map<String, dynamic> toJson() =>
      {"id": movieId, "title": movieTitle, "role": role};
}
