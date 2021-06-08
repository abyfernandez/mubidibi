// MovieActor Class

class MovieActor {
  int id;
  int movieId;
  String movieTitle;
  List<String> role;
  bool saved;

  MovieActor({
    this.id,
    this.movieId,
    this.movieTitle,
    this.role,
    this.saved,
  });

  Map<String, dynamic> toJson() =>
      {"id": id, "movie_id": movieId, "title": movieTitle, "role": role};
}
