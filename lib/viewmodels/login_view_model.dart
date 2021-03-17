import 'base_model.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:flutter/foundation.dart';
import 'package:mubidibi/models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class LoginViewModel extends BaseModel {
  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  // // Function: GET USER
  // Future<http.Response> login() async {
  //   setBusy(true);

  //   // Uri.http("example.org", "/path", { "q" : "dart" });

  //   final response = await Uri.http(Config.api, 'login/', {"email"}
  //   headers: <String, String> {
  //     'Content-type': 'application/json; charset=UTF-8',
  //   },

  //   );
  //   setBusy(false);
  //   if (response.statusCode == 200) {
  //     return (User.fromJson(jsonDecode(response.body)));
  //   } else {
  //     throw Exception('Failed to load album');
  //   }
  // }

  //   return http.post(
  //     Config.api + 'add-movie/',
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

  // Function: LOG IN -- log in with Email and Password
  Future login({@required String email, @required String password}) async {
    setBusy(true);

    var result = await _authenticationService.loginWithEmail(
        email: email, password: password);

    setBusy(false);

    if (result is bool) {
      if (result) {
        _navigationService.navigateTo(HomeViewRoute);
      } else {
        await _dialogService.showDialog(
          title: 'Login Failure',
          description: 'Couldn\'t login at this moment. Please try again later',
        );
      }
    } else {
      await _dialogService.showDialog(
        title: 'Login Failure',
        description: result,
      );
    }
  }

  // Function: Google Sign In -- signs in user with Google and creates user account using the details from Google
  Future googleSignIn() async {
    setBusy(true);
    var result = await _authenticationService.signInWithGoogle();
    setBusy(false);

    if (result is bool) {
      // RegExp regExp = new RegExp(
      //   r"^[A-Za-z0-9._%+-]+@up.edu.ph$",
      //   caseSensitive: false,
      //   multiLine: false,
      // );
      // if (result && regExp.hasMatch(currentUser.email) && (currentUser.rating > 2 || currentUser.rating == 0)) {
      //   await _authenticationService.syncUserProfile(currentUser.uid);
      //   await _navigationService.navigateTo(HomeViewRoute);
      // } else {
      //   await _authenticationService.signOutGoogle();
      //   await _navigationService.navigateTo(LoginErrorViewRoute);
      // }

      if (result) {
        // TO DO: sync user profile here
        await _navigationService.navigateTo(HomeViewRoute);
      } else {
        await _authenticationService.signOut();
        await _navigationService.navigateTo(LoginViewRoute);
        // TO DO: create login error route  and replace the above line of code
      }
    }
  }
}
