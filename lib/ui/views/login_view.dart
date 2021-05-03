import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/locator.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/login_view_model.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';
import 'package:mubidibi/constants/route_names.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // focusnodes
  final emailNode = FocusNode();
  final passwordlNode = FocusNode();
  final loginButtonNode = FocusNode();

  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();

  // we update the value of this variable so that we can manipulate the 'next' button
  bool _isButtonDisabled = true;
  bool _saving = false;

  bool isButtonDisabled() {
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
    print(_isButtonDisabled);
    return _isButtonDisabled;
  }

  @override
  void initState() {
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
    super.initState();
  }

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // TO DO: include user's  email address
    return ViewModelProvider<LoginViewModel>.withConsumer(
      viewModel: LoginViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.lightBlue, // change your color here
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          titleSpacing: 1.5,
          title: Text("mubidibi",
              style: TextStyle(
                  color: Colors.lightBlue, fontWeight: FontWeight.bold)),
          actions: [
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(right: 20),
              child: InkWell(
                  child: Text(
                    "Help",
                    style: TextStyle(
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  onTap: () {
                    print("Help button pressed.");
                  }),
            ),
          ],
        ),

        // TO DO: Close the keyboard when login button is clicked so it does not appear when the loading icon is shown
        body: ModalProgressHUD(
          inAsyncCall: _saving,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // EMAIL ADDRESS FIELD
                            // TO DO: validate with regex before allowing to be dubmitted
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(height: 50.0),
                                Container(
                                  child: InputField(
                                    fieldFocusNode: emailNode,
                                    nextFocusNode: passwordlNode,
                                    placeholder: 'Email Address',
                                    controller: emailController,
                                    onChanged: (val) {
                                      setState(() {
                                        isButtonDisabled();
                                      });
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
                                    fieldFocusNode: passwordlNode,
                                    nextFocusNode: loginButtonNode,
                                    placeholder: 'Password',
                                    password: true,
                                    controller: passwordController,
                                    onChanged: (val) {
                                      setState(() {
                                        isButtonDisabled();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // LOG IN BUTTON
                            // TO DO: After clicking login button, close keyboard
                            // TO DO: allow user to submit using the 'enter' key in the keyboard
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 30.0),
                              width: double.infinity,
                              child: FlatButton(
                                focusNode: loginButtonNode,
                                // onPressed: () async {
                                //   if (_formKey.currentState.validate()) {
                                //     model.login(
                                //         email: emailController.text,
                                //         password: passwordController.text);
                                //   }
                                // },
                                onPressed: isButtonDisabled()
                                    ? null
                                    : () async {
                                        _saving =
                                            true; // set saving to true to trigger circular progress indicator
                                        var response = await model.login(
                                            email: emailController.text,
                                            password: passwordController.text);

                                        if (response == true) {
                                          // set _saving to false and redirect to dashboard view
                                          setState(() {
                                            _saving = false;
                                          });

                                          // show snack bar or flutter toast (success)
                                          // TO DO: flutter toast or snackbar to notify that user has successfully logged in
                                          _navigationService
                                              .navigateTo(HomeViewRoute);
                                        } else {
                                          // set _saving to false and display error dialog box or snackbar/flutter toast for login error
                                          setState(() {
                                            _saving = false;
                                          });
                                        }
                                      },
                                padding: EdgeInsets.all(18.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                color: Colors.lightBlue,
                                disabledColor: Color.fromRGBO(192, 192, 192, 1),
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

                            // // DIVIDER
                            // Column(children: <Widget>[
                            //   Row(children: <Widget>[
                            //     Expanded(
                            //       child: new Container(
                            //           margin: const EdgeInsets.only(
                            //               left: 10.0, right: 20.0),
                            //           child: Divider(
                            //             color: Colors.black,
                            //             height: 20,
                            //           )),
                            //     ),
                            //     Text("OR LOG IN WITH",
                            //         style: TextStyle(
                            //           color: Colors.black,
                            //           fontSize: 16.0,
                            //         )),
                            //     Expanded(
                            //       child: new Container(
                            //           margin: const EdgeInsets.only(
                            //               left: 20.0, right: 10.0),
                            //           child: Divider(
                            //             color: Colors.black,
                            //             height: 20,
                            //           )),
                            //     ),
                            //   ]),
                            // ]),

                            //  TO DO: SIGN IN WITH GOOGLE
                            // // SIGN IN WITH GOOGLE
                            // Padding(
                            //   padding: EdgeInsets.symmetric(vertical: 20.0),
                            //   child: Column(
                            //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //     children: <Widget>[
                            //       GestureDetector(
                            //         onTap: () {
                            //           print("Sign in with Google");
                            //           model.googleSignIn();
                            //         },
                            //         child: Container(
                            //           height: 40.0,
                            //           width: 40.0,
                            //           decoration: BoxDecoration(
                            //             shape: BoxShape.circle,
                            //             color: Colors.white,
                            //             boxShadow: [
                            //               BoxShadow(
                            //                 color: Colors.black26,
                            //                 offset: Offset(0, 2),
                            //                 blurRadius: 6.0,
                            //               ),
                            //             ],
                            //             image: DecorationImage(
                            //               image: AssetImage(
                            //                 'assets/images/google.jpg',
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
