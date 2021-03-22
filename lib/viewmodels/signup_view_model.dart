import 'base_model.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/authentication_service.dart';
import '../locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:flutter/foundation.dart';

class SignUpViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();

  Future signUp({
    @required String email,
    @required String password,
    @required firstName,
    @required lastName,
    @required birthday,
  }) async {
    setBusy(true);

    var result = await _authenticationService.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      birthday: birthday,
    );

    setBusy(false);
    if (result is bool) {
      if (result) {
        _navigationService.navigateTo(HomeViewRoute);
      } else {
        await _dialogService.showDialog(
          title: 'Sign Up Failed',
          description: 'Please check your inputs and try again later',
        );
      }
    } else {
      await _dialogService.showDialog(
        title: 'Sign Up Failed',
        description: 'Please check your inputs and try again later',
      );
    }
  }
}
