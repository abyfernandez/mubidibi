import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/movie_actor.dart';
import 'package:mubidibi/services/authentication_service.dart';
import '../locator.dart';
import 'base_model.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CrewViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  var currentUser;

  // Function: GET CREW
  Future<List<Crew>> getAllCrew({@required String mode}) async {
    currentUser = _authenticationService.currentUser;

    setBusy(true);
    final response = await http.post(Config.api + 'crew/',
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
      // calls crewFromJson method from the model to convert from JSON to Crew datatype
      return crewFromJson(response.body);
    } else {
      throw Exception('Failed to get crew');
    }
  }

  // Function: GET CREW for Movie Detail View
  Future<List<List<Crew>>> getCrewForDetails({@required int movieId}) async {
    setBusy(true);

    final response = await http.post(Config.api + 'crew-for-movie/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "user": currentUser != null && currentUser.isAdmin == true
              ? "admin"
              : "non-admin",
          "movie_id": movieId,
        }));

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

  // Function: GET ONE CREW for Crew View Details
  Future<Crew> getOneCrew({@required String crewId}) async {
    var queryParams = {
      'id': crewId,
    };
    setBusy(true);

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/one-crew/$crewId', queryParams);

    // send API Request
    final response = await http.get(uri);

    setBusy(false);

    if (response.statusCode == 200) {
      return Crew.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load crew');
    }
  }

  // Function: ADD CREW (Director/Writer) -
  Future<int> addCrew({
    @required String firstName,
    String middleName,
    @required String lastName,
    String suffix,
    String birthday,
    String birthplace,
    String description,
    bool isAlive,
    String deathdate,
    String mimetype,
    File displayPic,
    String descDP,
    List<String> galleryDesc,
    List<File> gallery,
    String addedBy,
    int crewId, // for edit function,
    List<int> directors,
    List<int> writers,
    List<MovieActor> actors,
    List<Award> awards,

    // for crew edit purposes
    List<int> directorsToDelete,
    List<int> writersToDelete,
    List<int> actorsToDelete,
    List<int> awardsToDelete,
    List<int> galleryToDelete,
    int displayPicToDelete,
    // original lists for comparison in movie edit
    List<int> ogAct,
    List<int> ogAwards,
  }) async {
    setBusy(true);

    var id;
    String filename;
    List<String> mime;

    var media = []; // media
    var mediaType = [];
    Response response;

    if (displayPic != null && mimetype.trim() != '') {
      filename = displayPic.path.split('/').last;
      mime = mimetype.split('/');
    }

    if (displayPic != null) {
      media.add(MultipartFile.fromFileSync(displayPic.path,
          filename: filename,
          contentType:
              MediaType(mime[0], mime[1]))); // add displayPic in first index
      mediaType.add("display_pic");
    }

    media.addAll(gallery
        .map((file) => MultipartFile.fromFileSync(file.path,
            filename: file.path.split('/').last,
            contentType: MediaType(lookupMimeType(file.path).split('/')[0],
                lookupMimeType(file.path).split('/')[1])))
        .toList());
    mediaType.addAll(gallery.map((item) => "gallery").toList());

    // multi-part request
    Dio dio = new Dio();
    FormData formData = new FormData.fromMap({
      "crew": jsonEncode(<String, dynamic>{
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'suffix': suffix,
        'birthday': birthday,
        'birthplace': birthplace,
        'description': description,
        'is_alive': isAlive,
        'deathdate': deathdate,
        'added_by': addedBy,
        'displayPic': displayPic == null ? false : true,
        'directors': directors,
        'writers': writers,
        'actors': actors,
        'awards': awards,
        'desc_dp': descDP,
        'gallery_desc': galleryDesc,
        'media_type': mediaType,
        // For movie edit purposes:
        'directors_to_delete': directorsToDelete,
        'writers_to_delete': writersToDelete,
        'actors_to_delete': actorsToDelete,
        'awards_to_delete': awardsToDelete,
        'gallery_to_delete': galleryToDelete,
        'display_pic_to_delete': displayPicToDelete,
        // original lists for comparison in movie update
        'og_act': ogAct,
        'og_awards': ogAwards,
      }),
      "files": media,
    });

    if (crewId != 0) {
      // UPDATE CREW
      response = await dio.put(Config.api + 'update-crew/$crewId',
          data: formData, queryParameters: {'id': crewId});
    } else {
      // INSERT CREW
      response = await dio.post(
        Config.api + 'add-crew/',
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

  // DELETE CREW
  Future<int> deleteCrew({@required String id}) async {
    var queryParams = {
      'id': id,
    };

    var uri =
        Uri.http(Config.apiNoHTTP, '/mubidibi/delete-crew/$id', queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }

  // RESTORE CREW
  Future<int> restoreCrew({@required int id}) async {
    // send API Request
    var response = await http.post(Config.api + "crew/restore/",
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{"id": id}));

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }
}
