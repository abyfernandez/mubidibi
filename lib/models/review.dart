import 'dart:convert';

List<Review> reviewFromJson(String str) =>
    List<Review>.from(json.decode(str).map((x) => Review.fromJson(x)));

String reviewToJson(List<Review> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Review {
  final int reviewId;
  final int movieId;
  final String userId;
  final String rating;
  final String review;

  Review({
    this.reviewId,
    this.movieId,
    this.userId,
    this.rating,
    this.review,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['id'],
      movieId: json['movie_id'],
      userId: json['account_id'],
      rating: json['rating'],
      review: json['review'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": reviewId,
        "movie_id": reviewId,
        "account_id": userId,
        "rating": rating,
        "review": review,
      };
}
