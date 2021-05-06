import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import '../locator.dart';
import 'base_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'package:dio/dio.dart';

class MovieViewModel extends BaseModel {
  final List<Movie> movies = [];
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  var currentUser;

  // Function: GET ALL MOVIES
  Future<List<Movie>> getAllMovies() async {
    currentUser = _authenticationService.currentUser;
    print(currentUser.isAdmin);

    setBusy(true);
    // add filter when retrieving data from the database
    // TO DO: send the condition through body, not parameters. fix this when you wake up
    var response;

    // send API Request
    response = await http.post(Config.api + 'movies/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"is_admin": currentUser.isAdmin}));

    setBusy(false);
    if (response.statusCode == 200) {
      movies.addAll(movieFromJson(response.body));
      notifyListeners();
      return movieFromJson(response.body);
    } else {
      throw Exception('Failed to load movies');
    }
  }

  // Function: GET ONE MOVIE
  Future<Movie> getOneMovie({@required String movieId}) async {
    var queryParams = {
      'id': movieId,
    };
    setBusy(true);

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/movie/$movieId', queryParams);

    // send API Request
    final response = await http.get(uri);

    setBusy(false);

    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie');
    }
  }

  // Function: ADD MOVIE
  Future<int> addMovie({
    @required String title,
    String synopsis,
    String releaseDate,
    String mimetype,
    String runtime,
    File poster,
    String imageURI,
    List screenshots,
    List<String> genre,
    List<int> directors,
    List<int> writers,
    List<int> actors,
    List<List<String>> roles,
    String addedBy,
    int movieId,
  }) async {
    setBusy(true);

    var id;
    String filename;
    List<String> mime;
    var images = [];
    Response response;

    if (poster != null && mimetype.trim() != '') {
      filename = poster.path.split('/').last;
      mime = mimetype.split('/');
    }

    // TO DO: EDIT MOVIE
    void setImages() {
      if (poster != null) {
        images.add(MultipartFile.fromFileSync(poster.path,
            filename: filename,
            contentType:
                MediaType(mime[0], mime[1]))); // add poster in first index
      }
      images.addAll(screenshots
          .map((file) => MultipartFile.fromFileSync(file.path,
              filename: file.path.split('/').last,
              contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                  lookupMimeType(file.path).split('/')[1])))
          .toList());
    }

    // prepare images for formdata
    setImages();

    // multi-part request
    Dio dio = new Dio();
    FormData formData = new FormData.fromMap({
      "movie": jsonEncode(<String, dynamic>{
        'title': title,
        'synopsis': synopsis,
        'release_date': releaseDate,
        'running_time': runtime,
        'genre': genre,
        'directors': directors,
        'writers': writers,
        'added_by': addedBy,
        'posterURI': imageURI,
        'poster': poster == null ? false : true,
        'actors': actors,
        'roles': roles
      }),
      "files": images,
    });

    if (movieId != 0) {
      // UPDATE MOVIE
      response = await dio.put(Config.api + 'update-movie/$movieId',
          data: formData, queryParameters: {'id': movieId});
    } else {
      // INSERT MOVIE
      response = await dio.post(
        Config.api + 'add-movie/',
        data: formData,
      );
    }

    print(json.decode(response.data));

    if (response.statusCode == 200) {
      id = json.decode(response.data);
    } else {
      id = 0;
    }

    return id;
  }

  // DELETE MOVIE
  Future<int> deleteMovie({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri = Uri.http(Config.apiNoHTTP, '/mubidibi/movies/$id', queryParams);

    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }

  // RESTORE MOVIE
  Future<int> restoreMovie({@required String id}) async {
    // send API Request
    var response = await http.post(Config.api + "movies/restore/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{"id": id}));

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }
}
