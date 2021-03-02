import 'base_model.dart';
// import 'package:mubidibi/services/dialog_service.dart';
// import 'package:mubidibi/services/firestore_service.dart';
// import 'package:mubidibi/locator.dart';

import 'package:mubidibi/models/movie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class MovieViewModel extends BaseModel {
  // final DialogService _dialogService = locator<DialogService>();

  Future<Movie> getMovie() async {
    print(Config.api);
    final response = await http.get(Config.api + 'movies/');

    if (response.statusCode == 200) {
      print(Movie.fromData(jsonDecode(response.body)));
      return (Movie.fromData(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to load album');
    }
    // }
    //   setBusy(true);

    //   var result = await _firestoreService.getMovie();

    //   setBusy(false);

    //   if (result is bool) {
    //     if (result) {
    //       print("Data retrieval done!");
    //     } else {
    //       await _dialogService.showDialog(
    //         title: 'Data Retrieval Failure',
    //         description: 'Try again later.',
    //       );
    //     }
    //   } else {
    //     await _dialogService.showDialog(
    //       title: 'Data Retrieval Failure',
    //       description: result,
    //     );
    //   }
  }
}
