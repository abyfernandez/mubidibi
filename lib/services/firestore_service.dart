import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubidibi/models/user.dart';
import 'package:mubidibi/models/movie.dart';

class FirestoreService {
  // COLLECTION REFERENCES //

  final CollectionReference _usersCollectionReference =
      Firestore.instance.collection('users');
  final CollectionReference _moviesCollectionReference =
      Firestore.instance.collection('movies');

  // END OF COLLECTION REFERENCES //

  // USER FUNCTIONS //

  // Function: Get User -- retrieves user details for profile syncing
  Future getUser(String uid) async {
    try {
      var userData = await _usersCollectionReference.document(uid).get();
      return User.fromData(userData.data);
    } catch (e) {}
  }

  // Function: Create User -- Creates user using the provided user data
  Future createUser(User user) async {
    try {
      await _usersCollectionReference.document(user.uid).setData(user.toJson());
    } catch (e) {
      return e.message;
    }
  }

  // END OF USER FUNCTIONS //

  // MOVIE FUNCTIONS //

  // Function: Get Movie -- retrieves movie details
  Future getMovie() async {
    try {
      var movieData = await _moviesCollectionReference
          .document("G1XTXGx8uzwny6p9bDBJ")
          .get();
      return Movie.fromJson(movieData.data);
      // create movie model and please fix your pages !!!!
    } catch (e) {}
  }

  // END OF MOVIE FUNCTIONS //

}
