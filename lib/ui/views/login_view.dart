import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mubidibi/locator.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/login_view_model.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:shimmer/shimmer.dart';

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

  // final DialogService _dialogService = locator<DialogService>();
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
    return ViewModelProvider<LoginViewModel>.withConsumer(
      viewModel: LoginViewModel(),
      builder: (context, model, child) => Scaffold(
        // resizeToAvoidBottomInset: false,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, // change your color here
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();
              _navigationService.navigateTo(HomeViewRoute);
            },
          ),
        ),
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
                            SizedBox(
                              width: 300,
                              height: 100,
                              child: Center(
                                child: Shimmer.fromColors(
                                  period: Duration(seconds: 2),
                                  baseColor: Colors.blue,
                                  highlightColor: Colors.red,
                                  child: Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "mubidibi",
                                      style: TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // EMAIL ADDRESS FIELD
                            SizedBox(height: 50.0),
                            Container(
                              child: InputField(
                                fieldFocusNode: emailNode,
                                nextFocusNode: passwordlNode,
                                placeholder: 'Email Address *',
                                controller: emailController,
                                onChanged: (val) {
                                  setState(() {
                                    isButtonDisabled();
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 10.0),

                            // PASSWORD FIELD
                            Container(
                              child: InputField(
                                fieldFocusNode: passwordlNode,
                                nextFocusNode: loginButtonNode,
                                placeholder: 'Password *',
                                password: true,
                                controller: passwordController,
                                onChanged: (val) {
                                  setState(() {
                                    isButtonDisabled();
                                  });
                                },
                                enterPressed: isButtonDisabled()
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();

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

                                          Fluttertoast.showToast(
                                              msg: 'Login successful.',
                                              backgroundColor: Colors.green,
                                              textColor: Colors.white,
                                              fontSize: 16); // 16

                                          _navigationService
                                              .navigateTo(HomeViewRoute);
                                        } else {
                                          FocusScope.of(context).unfocus();

                                          // set _saving to false and display error dialog box or snackbar/flutter toast for login error

                                          setState(() {
                                            _saving = false;
                                          });
                                        }
                                      },
                              ),
                            ),

                            // LOG IN BUTTON

                            Container(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              width: double.infinity,
                              child: FlatButton(
                                focusNode: loginButtonNode,
                                onPressed: isButtonDisabled()
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();

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

                                          Fluttertoast.showToast(
                                              msg: 'Login successful.',
                                              backgroundColor: Colors.green,
                                              textColor: Colors.white,
                                              fontSize: 16);

                                          _navigationService
                                              .navigateTo(HomeViewRoute);
                                        } else {
                                          FocusScope.of(context).unfocus();

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

                            // link to sign up
                            Wrap(
                              // mainAxisAlignment: MainAxisAlignment.center,
                              alignment: WrapAlignment.center,
                              children: [
                                Text('Gumawa ng bagong account '),
                                InkWell(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();

                                      _navigationService
                                          .navigateTo(SignUpViewRoute);
                                    },
                                    child: Text('dito',
                                        style: TextStyle(
                                            color: Colors.lightBlue,
                                            decoration:
                                                TextDecoration.underline))),
                                Text('.'),
                              ],
                            ),

                            SizedBox(height: 10.0),
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
