import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubidibi/models/user.dart';

class FirestoreService {
  // COLLECTION REFERENCES //

  final CollectionReference _usersCollectionReference =
      Firestore.instance.collection('users');

  // END OF COLLECTION REFERENCES //

  // USER FUNCTIONS //

  // Function: Get User -- retrieves user details for profile syncing
  Future getUser(String uid) async {
    try {
      var userData = await _usersCollectionReference.document(uid).get();
      return User.fromJson(userData.data);
    } catch (e) {}
  }

  // Function: Create User -- Creates user using the provided user data
  Future createUser(User user) async {
    try {
      await _usersCollectionReference
          .document(user.userId)
          .setData(user.toJson());
    } catch (e) {
      return e.message;
    }
  }

  // END OF USER FUNCTIONS //

}
