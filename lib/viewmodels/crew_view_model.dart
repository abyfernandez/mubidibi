import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
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
      print(json.decode(response.body));
      return Crew.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load crew');
    }
  }

  // Function: ADD CREW (Director/Writer) -
  Future<int> addCrew(
      {@required String firstName,
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
      String imageURI,
      List photos,
      String addedBy,
      int crewId // for edit function
      }) async {
    setBusy(true);

    var id;
    String filename;
    List<String> mime;
    var images = [];
    Response response;

    if (displayPic != null && mimetype.trim() != '') {
      filename = displayPic.path.split('/').last;
      mime = mimetype.split('/');
    }

    // TO DO: EDIT MOVIE
    void setImages() {
      if (displayPic != null) {
        images.add(MultipartFile.fromFileSync(displayPic.path,
            filename: filename,
            contentType:
                MediaType(mime[0], mime[1]))); // add displayPic in first index
      }
      images.addAll(photos
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
        'displayPicURI': imageURI,
        'displayPic': displayPic == null ? false : true,
      }),
      "files": images,
    });

    if (crewId != 0) {
      print(crewId);
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

    print(json.decode(response.data));

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

    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return (json.decode(response.body));
    }
    return 0;
  }

  // RESTORE CREW
  Future<int> restoreCrew({@required String id}) async {
    // send API Request
    var response = await http.post(Config.api + "crew/restore/",
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
