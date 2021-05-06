import 'base_model.dart';
import 'package:mubidibi/models/award.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AwardViewModel extends BaseModel {
  final List<Award> awards = [];

  // Function: GET AWARDS
  Future<List<Award>> getAllAwards() async {
    setBusy(true);
    final response = await http.get(Config.api + 'all-awards/');
    setBusy(false);
    if (response.statusCode == 200) {
      // calls awardFromJson method from the model to convert from JSON to Award datatype
      return awardFromJson(response.body);
    } else {
      throw Exception('Failed to get awards');
    }
  }

  // Function: GET AWARDS for Awards Detail View
  Future<List<Award>> getAwards({String movieId, String awardId}) async {
    setBusy(true);

    // send API Request
    final response = await http.post(Config.api + "awards/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, dynamic>{"movieId": movieId, "awardId": awardId}));

    if (response.statusCode == 200) {
      awards.addAll(awardFromJson(response.body));
      notifyListeners();
      return awardFromJson(response.body);
    } else {
      throw Exception('Failed to get awards');
    }
  }
}
