import 'base_model.dart';
// import 'package:mubidibi/services/dialog_service.dart';
// import 'package:mubidibi/services/firestore_service.dart';
// import 'package:mubidibi/locator.dart';

import 'package:mubidibi/models/movie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class MovieViewModel extends BaseModel {
  Future<Movie> getMovie() async {
    print(Config.api);

    setBusy(true);
    final response = await http.get(Config.api + 'movies/');
    setBusy(false);
    if (response.statusCode == 200) {
      return (Movie.fromJson(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to load album');
    }
  }
}
