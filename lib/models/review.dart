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
  final String suffix;
  num rating;
  String review;
  int upvoteCount;
  int downvoteCount;
  bool upvoted;
  final bool isApproved;
  final String addedAt;

  Review(
      {this.reviewId,
      this.movieId,
      this.userId,
      this.firstName,
      this.middleName,
      this.lastName,
      this.suffix,
      this.rating,
      this.review,
      this.isApproved,
      this.addedAt,
      this.upvoteCount,
      this.downvoteCount,
      this.upvoted});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['id'],
      movieId: json['movie_id'],
      userId: json['account_id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      rating: json['rating'] != null ? double.parse(json['rating']) : 0.0,
      review: json['review'],
      upvoteCount: json['upvote_count'],
      downvoteCount: json['downvote_count'],
      upvoted: json['upvoted'],
      isApproved: json['is_approved'],
      addedAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": reviewId,
        "movie_id": movieId,
        "account_id": userId,
        "rating": rating,
        "review": review,
        "created_at": addedAt,
      };
}
