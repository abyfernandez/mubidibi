import 'package:flutter/services.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/locator.dart';
import 'package:flutter/material.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/login_view_model.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';

class LoginView extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final NavigationService _navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<LoginViewModel>.withConsumer(
      viewModel: LoginViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: <Widget>[
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF73AEF5),
                        Color(0xFF61A4F1),
                        Color(0xFF478DE0),
                        Color(0xFF398AE5),
                      ],
                      stops: [0.1, 0.4, 0.7, 0.9],
                    ),
                  ),
                ),
                Container(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 20.0),

                        // PLACEHOLDER
                        Placeholder(
                          color: Colors.white,
                          fallbackHeight: 100,
                        ),

                        // EMAIL ADDRESS FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 20.0),
                            Container(
                              child: InputField(
                                placeholder: 'Email Address',
                                controller: emailController,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.0,
                        ),

                        // PASSWORD FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              child: InputField(
                                placeholder: 'Password',
                                password: true,
                                controller: passwordController,
                              ),
                            ),
                          ],
                        ),

                        // FORGOT PASSWORD BUTTON
                        Container(
                          alignment: Alignment.centerRight,
                          child: FlatButton(
                            onPressed: () =>
                                print('Forgot Password Button Pressed'),
                            padding: EdgeInsets.only(right: 0.0),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),

                        // SIGN IN BUTTON
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 25.0),
                          width: double.infinity,
                          child: RaisedButton(
                            elevation: 5.0,
                            onPressed: () {
                              model.login(
                                email: emailController.text,
                                password: passwordController.text,
                              );
                            },
                            padding: EdgeInsets.all(15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            color: Colors.white,
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                color: Color(0xFF527DAA),
                                letterSpacing: 1.5,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),

                        // SIGN UP LINK
                        // Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: <Widget>[
                        //       Row(
                        //           mainAxisAlignment: MainAxisAlignment.center,
                        //           children: <Widget>[
                        //             Text("No account yet? Sign up ",
                        //                 style: TextStyle(
                        //                     color: Colors.white,
                        //                     fontSize: 16.0)),
                        //             InkWell(
                        //                 child: Text("here ",
                        //                     style: TextStyle(
                        //                         color: Colors.white,
                        //                         fontWeight: FontWeight.bold,
                        //                         fontSize: 16.0,
                        //                         decoration:
                        //                             TextDecoration.underline)),
                        //                 onTap: () => _navigationService
                        //                     .navigateTo(SignUpViewRoute)),
                        //             Text(".",
                        //                 style: TextStyle(color: Colors.white)),
                        //           ]),
                        //     ]),

                        // SizedBox(
                        //   height: 20.0,
                        // ),

                        // SIGN IN WITH GOOGLE

                        Column(
                          children: <Widget>[
                            Text(
                              '- OR -',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Text(
                              'Sign in with',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),

                        // SIGN IN WITH GOOGLE
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                  print("Sign in with Google");
                                  model.googleSignIn();
                                },
                                child: Container(
                                  height: 60.0,
                                  width: 60.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 6.0,
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/images/google.jpg',
                                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
