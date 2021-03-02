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
        resizeToAvoidBottomInset: false,
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
                        SizedBox(height: 60.0),

                        // PLACEHOLDER
                        Placeholder(
                          color: Colors.white,
                          fallbackHeight: 100,
                        ),

                        // EMAIL ADDRESS FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 50.0),
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
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              child: Row(
                                children: <Widget>[
                                  InkWell(
                                      child: Text("Sign up for an account",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                          )),
                                      onTap: () => _navigationService
                                          .navigateTo(SignUpViewRoute)),
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                  child: Text("Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                      )),
                                  onTap: () =>
                                      print("Forgot Password link tapped.")),
                            ),
                          ],
                        )),

                        // SIGN IN BUTTON
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          width: double.infinity,
                          child: RaisedButton(
                            elevation: 5.0,
                            onPressed: () {
                              model.login(
                                email: emailController.text,
                                password: passwordController.text,
                              );
                            },
                            padding: EdgeInsets.all(18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.0),
                            ),
                            color: Colors.blue[700],
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                // color: Color(0xFF527DAA),
                                color: Colors.white,
                                letterSpacing: 1.5,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          height: 10.0,
                        ),

                        // DIVIDER
                        Column(children: <Widget>[
                          Row(children: <Widget>[
                            Expanded(
                              child: new Container(
                                  margin: const EdgeInsets.only(
                                      left: 10.0, right: 20.0),
                                  child: Divider(
                                    color: Colors.white,
                                    height: 20,
                                  )),
                            ),
                            Text("OR LOG IN WITH",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontFamily: 'OpenSans',
                                )),
                            Expanded(
                              child: new Container(
                                  margin: const EdgeInsets.only(
                                      left: 20.0, right: 10.0),
                                  child: Divider(
                                    color: Colors.white,
                                    height: 20,
                                  )),
                            ),
                          ]),
                        ]),

                        // SIGN IN WITH GOOGLE
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              // Text("Sign in with",
                              //     style: TextStyle(
                              //       fontFamily: 'OpenSans',
                              //       color: Colors.white,
                              //       fontSize: 16.0,
                              //     )),
                              // SizedBox(height: 20.0),
                              GestureDetector(
                                onTap: () {
                                  print("Sign in with Google");
                                  model.googleSignIn();
                                },
                                child: Container(
                                  height: 50.0,
                                  width: 50.0,
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
