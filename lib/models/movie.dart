class Movie {
  final String uid;
  final String title;
  final String synopsis;
  final double rating;
  final String releaseDate;
  // final DocumentReference authorRef;
  // final double runningTime;

  Movie({
    this.uid,
    this.title,
    this.synopsis,
    this.rating,
    this.releaseDate,
    // this.authorRef,
    // this.runningTime,
  });

  Movie.fromData(Map<String, dynamic> data)
      : uid = data['uid'],
        title = data['title'],
        synopsis = data['synopsis'],
        rating = data['rating'],
        releaseDate = data['release_date'];
  // authorRef = data['author_ref'];
  // runningTime = data['running_time'];

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'title': title,
      'synopsis': synopsis,
      'rating': rating,
      'release_date': releaseDate,
      // 'authorRef': authorRef,
      // 'runningTime': runningTime,
    };
  }
}
