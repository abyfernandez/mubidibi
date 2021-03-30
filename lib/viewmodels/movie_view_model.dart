import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'base_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/shared/list_items.dart';
import 'package:dio/dio.dart';

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

  // Function: ADD MOVIE
  Future<Movie> addMovie({
    @required String title,
    String synopsis,
    String releaseDate,
    String mimetype,
    File poster,
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

    String filename = poster.path.split('/').last;
    List<String> mime = mimetype.split('/');

    // multi-part request
    Dio dio = new Dio();
    FormData formData = new FormData.fromMap({
      "movie": jsonEncode(<String, dynamic>{
        'title': title,
        'synopsis': synopsis,
        'release_date': releaseDate,
        'genre': filmGenres,
        'directors': directors,
        'writers': writers,
        'added_by': addedBy,
      }),
      "file": MultipartFile.fromFileSync(poster.path,
          filename: filename, contentType: MediaType(mime[0], mime[1])),
    });
    var response = await dio.post(
      Config.api + 'add-movie/',
      data: formData,
    );

    print(response);

    if (response.statusCode == 200) {
      // convert json response to type Movie
      movie = Movie.fromJson(json.decode(response.data.toString()));
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
