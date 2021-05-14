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

  void setReviews(List<Review> response) {
    reviews = response;
    print(jsonEncode(reviews));
    notifyListeners();
    print("notified listeners");
  }

  void setUserReview(Review review) {
    userReview = review;
    print('userReview');
    print(jsonEncode(userReview));
    notifyListeners();
    print("notified listeners");
  }

  void setEditing(Review editingReview) {
    _editingReview = editingReview;
    notifyListeners();
  }

  void setEdit(bool value) {
    isEditing = value;
    notifyListeners();
  }

  // Function: GET ALL REVIEWS OF A SPECIFIC MOVIE
  void getAllReviews({@required String movieId, String accountId}) async {
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
  void vote(
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
      print("HERE");
      var items = reviewFromJson(response.body);
      var userReview = items.singleWhere((review) => review.userId == userId,
          orElse: () => null);

      setReviews(items);
      setUserReview(userReview);
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
}
