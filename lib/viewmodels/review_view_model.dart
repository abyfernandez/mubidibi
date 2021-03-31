import 'base_model.dart';
import 'package:mubidibi/models/review.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ReviewViewModel extends BaseModel {
  List<Review> reviews = [];

  void setReviews(List<Review> response) {
    reviews = response;
    notifyListeners();
    print("notified listeners");
  }

  // Function: GET ALL REVIEWS OF A SPECIFIC MOVIE
  void getAllReviews({@required String movieId}) async {
    var queryParams = {'movie_id': movieId};

    setBusy(true);

    // build URI and attach params
    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/reviews/$movieId', queryParams);

    // send API request
    final response = await http.get(uri);

    setBusy(false);

    if (response.statusCode == 200) {
      // calls reviewFromJson method from the model to convert from JSON to Review datatype
      var items = reviewFromJson(response.body);
      setReviews(items);
      // return items;
    } else {
      throw Exception('Failed to get reviews');
    }
  }

  // Function: ADD REVIEW
  Future addReview(
      {@required movieId,
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
        'movie_id': movieId,
        'account_id': userId,
        'rating': rating,
        'review': review,
      }),
    );
  }
}
