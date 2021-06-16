import 'package:flutter/material.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:shimmer/shimmer.dart';

class SignInCategoryView extends StatelessWidget {
  SignInCategoryView({Key key}) : super(key: key);

  final NavigationService _navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 30.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Shimmer.fromColors(
                  period: Duration(milliseconds: 500),
                  baseColor: Colors.blue,
                  highlightColor: Colors.red,
                  child: Container(
                    height: 100,
                    child: Text(
                      "mubidibi",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 350,
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: FlatButton(
                          onPressed: () async {
                            await _navigationService.navigateTo(LoginViewRoute);
                          },
                          padding: EdgeInsets.all(18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(color: Colors.lightBlue),
                          ),
                          color: Colors.lightBlue,
                          child: Text(
                            'MAG-LOGIN',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 350,
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: FlatButton(
                          onPressed: () async {
                            await _navigationService
                                .navigateTo(SignUpViewRoute);
                          },
                          padding: EdgeInsets.all(18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(color: Colors.lightBlue),
                          ),
                          color: Colors.lightBlue,
                          child: Text(
                            'GUMAWA NG ACCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}
