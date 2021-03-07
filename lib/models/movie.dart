class Movie {
  final int movieId;
  final String title;
  final String synopsis;
  final List<dynamic> genre;
  // final num rating;
  final String releaseDate;
  final String addedAt;
  // final DocumentReference authorRef;
  // final double runningTime;

  Movie({
    this.movieId,
    this.title,
    this.synopsis,
    this.genre,
    this.releaseDate,
    this.addedAt,
    // this.rating,
    // this.releaseDate,
    // this.authorRef,
    // this.runningTime,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieId: json['movie_id'],
      title: json['title'],
      synopsis: json['synopsis'],
      genre: json['genre'],
      releaseDate: json['release_date'],
      addedAt: json['added_at'],
    );
  }

  // Movie.fromData(Map<String, dynamic> data)
  //     : movieId = data['movie_id'],
  //       title = data['title'],
  //       synopsis = data['synopsis'],
  //       genre = data['genre'],
  //       releaseDate = data['release_date'],
  //       addedAt = data['added_at'];
  // // rating = data['rating'],
  // // releaseDate = data['release_date'];
  // // authorRef = data['author_ref'];
  // // runningTime = data['running_time'];

  // Map<String, dynamic> toJson() {
  //   return {
  //     'movie_id': movieId,
  //     'title': title,
  //     'synopsis': synopsis,
  //     'genre': genre,
  //     'release_date': releaseDate,
  //     'added_at': addedAt
  //     // 'rating': rating,
  //     // 'release_date': releaseDate,
  //     // 'authorRef': authorRef,
  //     // 'runningTime': runningTime,
  //   };
  // }
}
