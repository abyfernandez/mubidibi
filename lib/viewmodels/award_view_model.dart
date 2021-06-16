import 'package:http/http.dart';

import 'base_model.dart';
import 'package:mubidibi/models/award.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AwardViewModel extends BaseModel {
  final List<Award> awards = [];

  // Function: GET AWARDS FOR DROPDOWNS AND LIST VIEW
  // if category is null, both categories will be searched
  Future<List<Award>> getAllAwards(
      {@required String user, @required String mode, String category}) async {
    setBusy(true);
    final response = await http.post(Config.api + "all-awards/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "user": user,
          "mode": mode,
          "category": category
        }));

    setBusy(false);
    if (response.statusCode == 200) {
      // calls awardFromJson method from the model to convert from JSON to Award datatype
      return awardFromJson(response.body);
    } else {
      throw Exception('Failed to get awards');
    }
  }

  // Function: GET AWARDS for Movie Detail View
  Future<List<Award>> getAwards(
      {@required int movieId, @required String user}) async {
    setBusy(true);

    // send API Request
    final response = await http.post(Config.api + "awards/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"movie_id": movieId, "user": user}));

    if (response.statusCode == 200) {
      awards.addAll(awardFromJson(response.body));
      notifyListeners();
      return awardFromJson(response.body);
    } else {
      throw Exception('Failed to get awards');
    }
  }

  // Function: GET AWARDS for Awards Detail View
  Future<List<Award>> getCrewAwards(
      {@required int crewId, @required String user}) async {
    setBusy(true);

    // send API Request
    final response = await http.post(Config.api + "crew-awards/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"crew_id": crewId, "user": user}));

    if (response.statusCode == 200) {
      awards.addAll(awardFromJson(response.body));
      notifyListeners();
      return awardFromJson(response.body);
    } else {
      throw Exception('Failed to get awards');
    }
  }

  // Function: GET AWARD (single)
  Future<Award> getAward({int awardId}) async {
    setBusy(true);

    // send API Request
    final response = await http.post(Config.api + "award/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"award_id": awardId}));

    if (response.statusCode == 200) {
      return Award.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get award');
    }
  }

  // Function: ADD AWARD
  Future<int> addAward({
    @required awardId,
    @required name,
    @required event,
    @required description,
    @required category,
    @required addedBy,
  }) async {
    setBusy(true);

    Response response;

    if (awardId != 0) {
      // UPDATE AWARD
      response = await http.put(
        Config.api + 'update-award/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'award_id': awardId,
          'name': name,
          'event': event,
          'description': description,
          'category': category,
          'added_by': addedBy,
        }),
      );
    } else {
      // ADD
      response = await http.post(
        Config.api + 'add-award/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'award_id': awardId,
          'name': name,
          'event': event,
          'description': description,
          'category': category,
          'added_by': addedBy,
        }),
      );
    }

    var id;
    if (response.statusCode == 200) {
      id = json.decode(response.body);
    } else {
      id = 0;
    }
    return id;
  }

  // DELETE AWARD
  Future<int> deleteAward({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/delete-award/$id', queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }

  // RESTORE AWARD
  Future<int> restoreAward({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/restore-award/$id', queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }
}
