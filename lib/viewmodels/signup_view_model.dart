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

  Future<bool> signUp({
    @required String email,
    @required String password,
    @required firstName,
    @required middleName,
    @required lastName,
    @required suffix,
    @required birthday,
  }) async {
    setBusy(true);

    var result = await _authenticationService.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      suffix: suffix,
      birthday: birthday,
    );

    setBusy(false);
    if (result is bool) {
      if (result) {
        return true;
      } else {
        await _dialogService.showDialog(
          title: 'Sign Up Failed',
          description: 'Please check if your inputs are correct.',
        );
      }
      return false;
    } else {
      await _dialogService.showDialog(
        title: 'Sign Up Failed',
        description: result,
      );
      return false;
    }
  }
}
