import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
// import 'package:mubidibi/locator.dart';
import 'package:flutter/material.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/login_view_model.dart';
// import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // final NavigationService _navigationService = locator<NavigationService>();

  bool _isButtonDisabled = true;

  bool isButtonDisabled() {
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "")
      _isButtonDisabled = false;
    else
      _isButtonDisabled = true;
    return _isButtonDisabled;
  }

  @override
  void initState() {
    super.initState();

    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else
      _isButtonDisabled = true;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<LoginViewModel>.withConsumer(
      viewModel: LoginViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color.fromRGBO(20, 20, 20, 1),
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          backgroundColor: Color.fromRGBO(20, 20, 20, 1),
          centerTitle: true,
          titleSpacing: 1.5,
          title: Text("mubidibi",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          actions: [
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(right: 20),
              child: InkWell(
                  child: Text(
                    "Help",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  onTap: () {
                    print("Help button pressed.");
                  }),
            ),
          ],
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: <Widget>[
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
                        // EMAIL ADDRESS FIELD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: 50.0),
                            Container(
                              child: InputField(
                                placeholder: 'Email Address',
                                controller: emailController,
                                onChanged: (val) {
                                  isButtonDisabled();
                                },
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
                                onChanged: (val) {
                                  isButtonDisabled();
                                },
                                controller: passwordController,
                              ),
                            ),
                          ],
                        ),

                        // LOG IN BUTTON
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          width: double.infinity,
                          child: FlatButton(
                            onPressed: isButtonDisabled()
                                ? null
                                : () async {
                                    model.login(
                                        email: emailController.text,
                                        password: passwordController.text);
                                  },
                            // onPressed: () async {
                            //   model.login(
                            //       email: emailController.text,
                            //       password: passwordController.text);
                            // },
                            padding: EdgeInsets.all(18.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(color: Colors.black)),
                            color: Color.fromRGBO(229, 9, 20, 1),
                            disabledColor: Color.fromRGBO(20, 20, 20, 1),
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
                              GestureDetector(
                                onTap: () {
                                  print("Sign in with Google");
                                  model.googleSignIn();
                                },
                                child: Container(
                                  height: 40.0,
                                  width: 40.0,
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
