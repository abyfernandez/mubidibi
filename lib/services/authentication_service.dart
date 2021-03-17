import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mubidibi/services/firestore_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/models/user.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User _currentUser;
  User get currentUser => _currentUser;

  // Function: POPULATE CURRENT USER -- gets current user's details (basic sync)
  Future _populateCurrentUser(FirebaseUser user) async {
    if (user != null) {
      _currentUser = await _firestoreService.getUser(user.uid);
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
      print(_currentUser.toJson());

      return _currentUser != null;
    } catch (e) {
      return e.message;
    }
  }

  // Function: SIGN UP -- sign up using provided Email and Password
  Future signUpWithEmail({
    // TO DO: complete user profile before saving to firestore

    // @required User user,
    @required String email,
    @required String password,
    @required String firstName,
    @required String lastName,
    @required String birthday,
  }) async {
    try {
      var authResult = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _firestoreService.createUser(User(
          uid: authResult.user.uid,
          email: authResult.user.email,
          firstName: firstName,
          lastName: lastName,
          type: "user"));

      return authResult.user != null;
    } catch (e) {
      return e.message;
    }
  }

  // Function: SIGN IN WITH GOOGLE -- sign in using provided gmail account
  Future signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final AuthResult authResult =
          await _firebaseAuth.signInWithCredential(credential);
      final FirebaseUser user = authResult.user;

      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _firebaseAuth.currentUser();
      assert(user.uid == currentUser.uid);

      await _populateCurrentUser(currentUser);

      print(currentUser);

      await _firestoreService.createUser(User(
          uid: currentUser.uid,
          displayName: currentUser.displayName,
          photoUrl: currentUser.photoUrl,
          email: currentUser.email,
          type: "user"));

      print("User signed in.");

      return user != null;
    } catch (e) {}
  }

  // Function: SIGN OUT -- signs out current user
  Future signOut() async {
    try {
      await googleSignIn.signOut();
      await _firebaseAuth.signOut();
      print("User signed out.");
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
