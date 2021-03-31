import 'dart:convert';

List<Review> reviewFromJson(String str) =>
    List<Review>.from(json.decode(str).map((x) => Review.fromJson(x)));

String reviewToJson(List<Review> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Review {
  final int reviewId;
  final int movieId;
  final String userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final double rating;
  final String review;
  final String addedAt;

  Review(
      {this.reviewId,
      this.movieId,
      this.userId,
      this.firstName,
      this.middleName,
      this.lastName,
      this.rating,
      this.review,
      this.addedAt});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['id'],
      movieId: json['movie_id'],
      userId: json['account_id'],
      rating: json['rating'] == 0 ? 0.00 : json['rating'],
      review: json['review'],
      addedAt: json['added_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": reviewId,
        "movie_id": reviewId,
        "account_id": userId,
        "rating": rating,
        "review": review,
        "added_at": addedAt,
      };
}
