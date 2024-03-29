import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:mubidibi/services/firestore_service.dart';
// import 'package:mubidibi/locator.dart';
import 'package:mubidibi/models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // final FirestoreService _firestoreService = locator<FirestoreService>();
  // final GoogleSignIn googleSignIn = GoogleSignIn();

  User _currentUser;
  User get currentUser => _currentUser;

  // Function: POPULATE CURRENT USER -- gets current user's details (basic sync)
  Future _populateCurrentUser(FirebaseUser user) async {
    print('TEST');
    if (user != null) {
      _currentUser = await getUser(userId: user.uid);
      print('currentUser: $_currentUser');
    } else {
      _currentUser = null;
    }
  }

  // Function: LOGIN -- log in using Email and Password, also sync's user's profile (basic sync)
  Future loginWithEmail({
    @required String email,
    @required String password,
  }) async {
    try {
      final AuthResult authResult = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final FirebaseUser user = authResult.user;

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _firebaseAuth.currentUser();
      assert(user.uid == currentUser.uid);

      await _populateCurrentUser(currentUser); // populate the user information

      return _currentUser != null;
    } catch (e) {
      return e.message;
    }
  }

  // Function: GET USER
  Future<User> getUser({@required String userId}) async {
    var queryParams = {
      'id': userId,
    };

    // create URI and attach params
    var uri = Uri.http(Config.apiNoHTTP, '/mubidibi/user/$userId', queryParams);

    // send API request
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
      if (response.body.isNotEmpty) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } else {
      throw Exception('Failed to load user');
    }
  }

  // Function: SIGN UP -- sign up using provided Email and Password
  Future signUpWithEmail({
    @required String email,
    @required String password,
    @required String firstName,
    @required String middleName,
    @required String lastName,
    @required String suffix,
    @required String birthday,
  }) async {
    try {
      var authResult = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      print(authResult.user.uid);

      // after creating user in firebase, create user in postgres db with the data provided.

      var response = await http.post(
        Config.api + 'sign-up/',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': authResult.user.uid,
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'suffix': suffix,
          'birthday': birthday,
          'email': email
        }),
      );

      if (response.statusCode == 200) {
        final FirebaseUser user = authResult.user;

        assert(!user.isAnonymous);
        assert(await user.getIdToken() != null);

        final FirebaseUser currentUser = await _firebaseAuth.currentUser();
        print(user.uid);
        print(currentUser.uid);
        assert(user.uid == currentUser.uid);

        print("FB: $user");
        print("CURRE: $currentUser");

        await _populateCurrentUser(
            currentUser); // populate the user information

        return _currentUser != null;
      } else {
        return currentUser == null;
      }
    } catch (e) {
      return e.message;
    }
  }

  // // Function: SIGN IN WITH GOOGLE -- sign in using provided gmail account
  // Future signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount googleSignInAccount =
  //         await googleSignIn.signIn();
  //     final GoogleSignInAuthentication googleSignInAuthentication =
  //         await googleSignInAccount.authentication;

  //     final AuthCredential credential = GoogleAuthProvider.getCredential(
  //       accessToken: googleSignInAuthentication.accessToken,
  //       idToken: googleSignInAuthentication.idToken,
  //     );

  //     final AuthResult authResult =
  //         await _firebaseAuth.signInWithCredential(credential);
  //     final FirebaseUser user = authResult.user;

  //     assert(!user.isAnonymous);
  //     assert(await user.getIdToken() != null);

  //     final FirebaseUser currentUser = await _firebaseAuth.currentUser();
  //     assert(user.uid == currentUser.uid);

  //     await _populateCurrentUser(currentUser);

  //     print("currentuser: $currentUser");
  //     print("User signed in.");

  //     return user != null;
  //   } catch (e) {}
  // }

  // Function: SIGN OUT -- signs out current user
  Future signOut() async {
    try {
      // await googleSignIn.signOut();
      await _firebaseAuth.signOut();

      var hasLoggedInUser =
          isUserLoggedIn(); // to refresh user information after logout
    } catch (e) {}
  }

  // Function: IS USER LOGGED IN -- checks if user is logged in
  Future<bool> isUserLoggedIn() async {
    var user = await _firebaseAuth.currentUser();
    if (user != null) {
      print("logged in");
    } else {
      print('not logged in');
    }
    await _populateCurrentUser(user); // populate the user information
    return user != null;
  }
}
