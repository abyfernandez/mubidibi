import 'base_model.dart';
import 'package:mubidibi/models/review.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ReviewViewModel extends BaseModel {
  // Function: GET REVIEWS
  Future<List<Review>> getAllReview() async {
    setBusy(true);
    final response = await http.get(Config.api + 'review/');
    setBusy(false);
    if (response.statusCode == 200) {
      // calls reviewFromJson method from the model to convert from JSON to Review datatype
      return reviewFromJson(response.body);
    } else {
      throw Exception('Failed to get review');
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
