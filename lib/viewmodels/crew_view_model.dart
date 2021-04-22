import 'base_model.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CrewViewModel extends BaseModel {
  // Function: GET CREW
  Future<List<Crew>> getAllCrew() async {
    setBusy(true);
    final response = await http.get(Config.api + 'crew/');
    setBusy(false);
    if (response.statusCode == 200) {
      // calls crewFromJson method from the model to convert from JSON to Crew datatype
      return crewFromJson(response.body);
    } else {
      throw Exception('Failed to get crew');
    }
  }

  // Function: GET ALL CREW ACCORDING TO CREW TYPE
  Future<List<List<Crew>>> getAllCrewTypes() async {
    setBusy(true);

    // send API Request
    final response = await http.get(Config.api + 'all-crew/');

    List<List<Crew>> crew = [];
    var items = json.decode(response.body);

    if (response.statusCode == 200) {
      // create a list of CREW
      if (items.isNotEmpty) {
        crew = List<List<Crew>>.from(
            items.map((x) => List<Crew>.from(x.map((x) => Crew.fromJson(x)))));
      }
    } else {
      throw Exception('Failed to get crew');
    }
    return crew;
  }

  // Function: GET CREW for Movie Detail View
  Future<List<List<Crew>>> getCrewForDetails({@required String movieId}) async {
    var queryParams = {
      'id': movieId,
    };

    setBusy(true);

    // create URI and attach the params
    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/crew/$movieId', queryParams);

    // send API Request
    final response = await http.get(uri);
    List<List<Crew>> crew = [];
    var items = json.decode(response.body);

    if (response.statusCode == 200) {
      // create a list of CREW
      if (items.isNotEmpty) {
        crew = List<List<Crew>>.from(
            items.map((x) => List<Crew>.from(x.map((x) => Crew.fromJson(x)))));
      }
    } else {
      throw Exception('Failed to get crew');
    }
    return crew;
  }

  // // Function: ADD CREW (Director/Writer) -
  // Future<http.Response> addCrew({
  //   @required String title,
  //   String synopsis,
  //   String releaseDate,
  //   String poster,
  //   List<int> genre,
  //   String addedBy,
  // }) async {
  //   setBusy(true);

  //   List<String> filmGenres = [];

  //   for (var g in genre) {
  //     print(genres.singleWhere((i) => genres.indexOf(i) == g));
  //     filmGenres.add(genres.singleWhere((i) => genres.indexOf(i) == g));
  //   }

  //   return http.post(
  //     Config.api + 'add-crew/',
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, dynamic>{
  //       'title': title,
  //       'synopsis': synopsis,
  //       'releaseDate': releaseDate,
  //       'poster': poster,
  //       'genre': filmGenres,
  //       'added_by': addedBy
  //     }),
  //   );
  // }
}
