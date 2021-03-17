import 'package:flutter/material.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/constants/route_names.dart';

class SignInCategoryView extends StatelessWidget {
  SignInCategoryView({Key key}) : super(key: key);

  final NavigationService _navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 30.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: SizedBox(height: 100),
                      flex: 1,
                    ),

                    // PLACEHOLDER
                    Placeholder(
                      color: Colors.red,
                      fallbackHeight: 100,
                    ),
                    Flexible(
                      child: SizedBox(height: 100),
                      flex: 1,
                    ),

                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        width: double.infinity,
                        child: FlatButton(
                          onPressed: () async {
                            await _navigationService.navigateTo(LoginViewRoute);
                          },
                          padding: EdgeInsets.all(18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: Colors.grey),
                          ),
                          color: Colors.black,
                          child: Text(
                            'LOGIN',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      flex: 1,
                    ),

                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        width: double.infinity,
                        child: FlatButton(
                          onPressed: () async {
                            await _navigationService
                                .navigateTo(SignUpViewRoute);
                          },
                          padding: EdgeInsets.all(18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: Colors.grey),
                          ),
                          color: Colors.black,
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      flex: 1,
                    ),

                    Flexible(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              child: Text(
                                "Help",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              onTap: () => {print("Help button tapped.")},
                            ),
                            InkWell(
                              child: Text(
                                "Privacy",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              onTap: () => {print("Privacy button tapped.")},
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
