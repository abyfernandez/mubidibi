// import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/line.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/services/authentication_service.dart';
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
  Future<List<Movie>> getAllMovies({@required String mode}) async {
    currentUser = _authenticationService.currentUser;

    setBusy(true);
    // add filter when retrieving data from the database ???? (filters)
    var response;

    // send API Request
    response = await http.post(Config.api + 'movies/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "user": currentUser != null && currentUser.isAdmin == true
              ? "admin"
              : "non-admin",
          "mode": mode,
        }));

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
    String runtime,
    List<MediaFile> posters,
    // String imageURI, // poster edit ??
    List<MediaFile> gallery,
    List<MediaFile> trailers,
    List<MediaFile> audios,
    List<String> genre,
    List<int> directors,
    List<int> writers,
    List<Crew> actors,
    List<Award> awards,
    List<Line> lines,
    String addedBy,
    int movieId,
  }) async {
    setBusy(true);

    var id;
    var images = []; // list for both posters and screenshots
    Response response;

    // TO DO: EDIT MOVIE
    if (posters.isNotEmpty) {
      images.addAll(posters
          .map((p) => MultipartFile.fromFileSync(p.file.path,
              filename: p.file.path.split('/').last,
              contentType: MediaType(lookupMimeType(p.file.path).split('/')[0],
                  lookupMimeType(p.file.path).split('/')[1])))
          .toList());
    }
    images.addAll(gallery
        .map((g) => MultipartFile.fromFileSync(g.file.path,
            filename: g.file.path.split('/').last,
            contentType: MediaType(lookupMimeType(g.file.path).split('/')[0],
                lookupMimeType(g.file.path).split('/')[1])))
        .toList());

    // prepare images for formdata

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
        'actors': actors,
        'awards': awards,
        'lines': lines,
        'added_by': addedBy,
        // 'posterURI': imageURI,  // for poster edit ??
        'poster_count': posters.length,
        'gallery_count': gallery.length,
        'trailer_count': trailers.length,
        'audio_count': audios.length,
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

    final response = await http.get(uri);

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
