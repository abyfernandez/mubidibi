import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/line.dart';
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
          "account_id": currentUser != null ? currentUser.userId : null,
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
  Future<Movie> getOneMovie({@required int movieId}) async {
    currentUser = _authenticationService.currentUser;

    // send API Request
    setBusy(true);
    var response;

    // send API Request
    response = await http.post(Config.api + 'movie/get-one-movie/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "account_id": currentUser != null ? currentUser.userId : null,
          "id": movieId
        }));

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
    List<File> posters,
    List<String> posterDesc,
    List<File> gallery,
    List<String> galleryDesc,
    List<File> trailers,
    List<String> trailerDesc,
    List<File> audios,
    List<String> audioDesc,
    List<String> genre,
    List<int> directors,
    List<int> writers,
    List<Crew> actors,
    List<Award> awards,
    List<Line> lines,
    String addedBy,
    int movieId,
    // for movie edit purposes:
    List<int> directorsToDelete,
    List<int> writersToDelete,
    List<int> actorsToDelete,
    List<int> awardsToDelete,
    List<int> linesToDelete,
    List<String> genresToDelete,
    List<int> postersToDelete,
    List<int> galleryToDelete,
    List<int> trailersToDelete,
    List<int> audiosToDelete,
    // original lists for comparison in movie edit
    List<int> ogAct,
    List<int> ogLines,
    List<int> ogAwards,
  }) async {
    setBusy(true);

    var id;
    var media = []; // media
    Response response;
    var mediaType = []; // track the type of the media upload

    // append posters
    media.addAll(posters
        .map((file) => MultipartFile.fromFileSync(file.path,
            filename: file.path.split('/').last,
            contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                lookupMimeType(file.path).split('/')[1])))
        .toList());

    mediaType.addAll(posters.map((item) => "poster").toList());

    // append gallery
    media.addAll(gallery
        .map((file) => MultipartFile.fromFileSync(file.path,
            filename: file.path.split('/').last,
            contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                lookupMimeType(file.path).split('/')[1])))
        .toList());

    mediaType.addAll(gallery.map((item) => "gallery").toList());

    // append trailers
    media.addAll(trailers
        .map((file) => MultipartFile.fromFileSync(file.path,
            filename: file.path.split('/').last,
            contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                lookupMimeType(file.path).split('/')[1])))
        .toList());

    mediaType.addAll(trailers.map((item) => "trailer").toList());

    // append audio
    media.addAll(audios
        .map((file) => MultipartFile.fromFileSync(file.path,
            filename: file.path.split('/').last,
            contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                lookupMimeType(file.path).split('/')[1])))
        .toList());

    mediaType.addAll(audios.map((item) => "audio").toList());

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
        'poster_desc': posterDesc,
        'gallery_desc': galleryDesc,
        'trailer_desc': trailerDesc,
        'audio_desc': audioDesc,
        'media_type': mediaType,

        // For movie edit purposes:
        'directors_to_delete': directorsToDelete,
        'writers_to_delete': writersToDelete,
        'actors_to_delete': actorsToDelete,
        'lines_to_delete': linesToDelete,
        'awards_to_delete': awardsToDelete,
        'genres_to_delete': genresToDelete,
        'posters_to_delete': postersToDelete,
        'gallery_to_delete': galleryToDelete,
        'trailers_to_delete': trailersToDelete,
        'audios_to_delete': audiosToDelete,

        // original lists for comparison in movie update
        'og_act': ogAct,
        'og_lines': ogLines,
        'og_awards': ogAwards,
      }),
      "files": media,
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

  // Function: GET FAVORITES
  Future<List<Movie>> getFavorites({@required String mode}) async {
    currentUser = _authenticationService.currentUser;

    setBusy(true);
    // add filter when retrieving data from the database ???? (filters)
    var response;

    // send API Request
    response = await http.post(Config.api + 'favorite-movies/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "account_id": currentUser != null ? currentUser.userId : null,
          "user": currentUser != null && currentUser.isAdmin == true
              ? "admin"
              : "non-admin",
          "mode": mode,
        }));

    setBusy(false);
    if (response.statusCode == 200) {
      return movieFromJson(response.body);
    } else {
      throw Exception('Failed to load movies');
    }
  }

  // UPDATE FAVORITE MOVIE
  Future<int> updateFavorites(
      {@required int movieId, @required String type}) async {
    currentUser = _authenticationService.currentUser;

    // send API Request
    var response = await http.post(Config.api + "movies/update-favorites/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "movie_id": movieId,
          "type": type,
          "account_id": currentUser != null ? currentUser.userId : null,
        }));

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }
}
