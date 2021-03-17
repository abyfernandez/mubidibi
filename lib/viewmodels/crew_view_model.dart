import 'base_model.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

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
