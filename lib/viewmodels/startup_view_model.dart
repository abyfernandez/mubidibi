import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/navigation_service.dart';

import 'base_model.dart';

class StartUpViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  Future handleStartUpLogic() async {
    var hasLoggedInUser = await _authenticationService.isUserLoggedIn();

    if (hasLoggedInUser) {
      await _navigationService.navigateTo(HomeViewRoute);
    } else {
      await _navigationService.navigateTo(LoginViewRoute);
    }
  }
}
