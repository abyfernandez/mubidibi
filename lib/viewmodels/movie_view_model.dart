import 'package:mubidibi/viewmodels/crew_view_model.dart';

import 'base_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/shared/list_items.dart';

class MovieViewModel extends BaseModel {
  // Function: GET ALL MOVIES
  Future<List<Movie>> getAllMovies() async {
    setBusy(true);
    final response = await http.get(Config.api + 'movies/');
    setBusy(false);
    if (response.statusCode == 200) {
      return movieFromJson(response.body);
    } else {
      throw Exception('Failed to load movies');
    }
  }

  // Function: ADD MOVIE -
  // Future<http.Response> addMovie({
  //   @required String title,
  //   String synopsis,
  //   String releaseDate,
  //   String poster,
  //   List<int> genre,
  //   List<int> directors,
  //   List<int> writers,
  //   String addedBy,
  // }) async {
  //   setBusy(true);

  //   List<String> filmGenres = [];

  //   for (var g in genre) {
  //     filmGenres.add(genres.singleWhere((i) => genres.indexOf(i) == g));
  //   }

  //   return http.post(
  //     Config.api + 'add-movie/',
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, dynamic>{
  //       'title': title,
  //       'synopsis': synopsis,
  //       'releaseDate': releaseDate,
  //       'poster': poster,
  //       'genre': filmGenres,
  //       'directors': directors,
  //       'writers': writers,
  //       'added_by': addedBy
  //     }),
  //   );
  // }

  Future<Movie> addMovie({
    @required String title,
    String synopsis,
    String releaseDate,
    String poster,
    List<int> genre,
    List<int> directors,
    List<int> writers,
    String addedBy,
  }) async {
    setBusy(true);

    List<String> filmGenres = [];
    Movie movie;

    for (var g in genre) {
      filmGenres.add(genres.singleWhere((i) => genres.indexOf(i) == g));
    }

    var response = await http.post(
      Config.api + 'add-movie/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'synopsis': synopsis,
        'releaseDate': releaseDate,
        'poster': poster,
        'genre': filmGenres,
        'directors': directors,
        'writers': writers,
        'added_by': addedBy
      }),
    );

    if (response.body != null) {
      // convert json response to type Movie
      movie = Movie.fromJson(json.decode(response.body));
    }

    return movie;
  }

  // DELETE MOVIE
  Future<http.Response> deleteMovie({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri = Uri.http(Config.apiNoHTTP, '/mubidibi/movies/$id', queryParams);

    final response = await http.delete(uri);
    return response;
  }
}
