import 'package:flutter/material.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/locator.dart';

final AuthenticationService _authenticationService =
    locator<AuthenticationService>();
final NavigationService _navigationService = locator<NavigationService>();

class HomeView extends StatelessWidget {
  const HomeView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          padding: EdgeInsets.symmetric(vertical: 25.0),
          width: double.infinity,
          child: Column(
            children: [
              RaisedButton(
                elevation: 5.0,
                onPressed: () async {
                  await _authenticationService.signOut();
                  await _navigationService.navigateTo(LoginViewRoute);
                },
                padding: EdgeInsets.all(15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                color: Colors.white,
                child: Text(
                  'LOGOUT',
                  style: TextStyle(
                    color: Color(0xFF527DAA),
                    letterSpacing: 1.5,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              RaisedButton(
                elevation: 5.0,
                onPressed: () async {
                  await _navigationService.navigateTo(TempMovieRoute);
                },
                padding: EdgeInsets.all(15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                color: Colors.white,
                child: Text(
                  'Get Movie',
                  style: TextStyle(
                    color: Color(0xFF527DAA),
                    letterSpacing: 1.5,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
