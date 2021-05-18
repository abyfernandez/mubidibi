import 'base_model.dart';
import 'package:mubidibi/models/review.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ReviewViewModel extends BaseModel {
  List<Review> reviews = [];
  Review userReview;
  Review _editingReview;
  bool isEditing = false;
  bool isEmpty = false;
  num overAllRating = 0.0;

  void setReviews(List<Review> response) {
    reviews = response;
    notifyListeners();
  }

  void setUserReview(Review review) {
    userReview = review;
    notifyListeners();
  }

  // TO DO: Deprecate
  void setEditing(Review editingReview) {
    _editingReview = editingReview;
    notifyListeners();
  }

  // TO DO: Deprecate
  void setEdit(bool value) {
    isEditing = value;
    notifyListeners();
  }

  void setLength(bool empty) {
    isEmpty = empty;
    notifyListeners();
  }

  void setOverAllRating(num rating) {
    overAllRating = rating;
    notifyListeners();
  }

  // Function: GET ALL REVIEWS OF A SPECIFIC MOVIE
  Future getAllReviews({@required String movieId, String accountId}) async {
    setBusy(true);

    // send API request
    final response = await http.post(Config.api + 'movie-reviews/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'movie_id': movieId,
          'account_id': accountId != null ? accountId : "0"
        }));

    setBusy(false);

    if (response.statusCode == 200) {
      // calls reviewFromJson method from the model to convert from JSON to Review datatype
      var items = reviewFromJson(response.body);
      var userReview = items.singleWhere((review) => review.userId == accountId,
          orElse: () => null);
      var empty = items.every((item) => item.isApproved == false);
      setLength(empty);
      setReviews(items);
      setUserReview(userReview);
    } else {
      throw Exception('Failed to get reviews');
    }
  }

  // Function: ADD REVIEW
  Future addReview(
      {@required reviewId,
      @required movieId,
      @required userId,
      @required rating,
      @required review}) async {
    setBusy(true);

    return http.post(
      Config.api + 'add-review/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'review_id': reviewId,
        'movie_id': movieId,
        'account_id': userId,
        'rating': rating,
        'review': review,
      }),
    );
  }

  // vote for a review
  Future<List<Review>> vote(
      {@required int reviewId,
      @required int movieId,
      @required String userId,
      @required String type,
      @required bool value}) async {
    setBusy(true);

    var response = await http.post(
      Config.api + 'vote/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'review_id': reviewId,
        'movie_id': movieId,
        'account_id': userId,
        'type': type,
        'upvote': value
      }),
    );

    if (response.statusCode == 200) {
      // returns freshly fetched set of reviews
      // calls reviewFromJson method from the model to convert from JSON to Review datatype
      var items = reviewFromJson(response.body);
      var userReview = items.singleWhere((review) => review.userId == userId,
          orElse: () => null);

      setReviews(items);
      setUserReview(userReview);
      return items;
    } else {
      throw Exception('Failed to get updated reviews');
    }
  }

  // DELETE REVIEW
  Future<int> deleteReview({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/delete-review/$id', queryParams);

    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }

  // APPROVE / HIDE A REVIEW
  Future<bool> changeReviewStatus(
      {@required int id, @required bool status, int movieId}) async {
    final response = await http.post(
      Config.api + 'change-status/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'id': id,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    } else {
      throw Exception('Failed to change review status');
    }
  }

  // Get one review
  Future<Review> getReview(
      {@required String accountId, @required int movieId}) async {
    setBusy(true);

    final response = await http.post(
      Config.api + 'review/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'account_id': accountId,
        'movie_id': movieId,
      }),
    );

    setBusy(false);

    if (response.statusCode == 200) {
      print(json.decode(response.body));
      if (json.decode(response.body).is_approved == true) {
        setLength(false);
      }
      return Review.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load review');
    }
  }
}
