// import 'package:mubidibi/ui/shared/ui_helpers.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/viewmodels/signup_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/locator.dart';

class SignUpFirstPage extends StatefulWidget {
  SignUpFirstPage({Key key}) : super(key: key);
  _SignUpFirstPageState createState() => _SignUpFirstPageState();
}

// SIGN UP FIRST PAGE
class _SignUpFirstPageState extends State<SignUpFirstPage> {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final NavigationService _navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Color(0xFF73AEF5),
          elevation: 0,
          toolbarHeight: 100,
          leadingWidth: 70,
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                _navigationService.pop();
              }),
        ),
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
                        SizedBox(height: 30.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 35.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'OpenSans'),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: 30,
                        ),
                        // Email Address Form Field
                        InputField(
                          controller: emailController,
                          placeholder: "Email Address",
                          // icon: Icon(
                          //   Icons.email,
                          //   color: Colors.blue,
                          //   size: 20,
                          // ),
                        ),
                        SizedBox(height: 20.0),
                        // Password Form Field
                        InputField(
                          controller: passwordController,
                          placeholder: "Password",
                          password: true,
                          // icon: Icon(
                          //   Icons.lock,
                          //   color: Colors.blue,
                          //   size: 20,
                          // ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: RaisedButton(
                            elevation: 5,
                            padding: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: Colors.white,
                            child: Text(
                              'Next',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 16,
                                  fontFamily: 'OpenSans'),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpSecondPage([
                                          emailController.text,
                                          passwordController.text,
                                        ])),
                              );
                            },
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

// SIGN UP SECOND PAGE
class SignUpSecondPage extends StatefulWidget {
  final List<String> previousFields;

  SignUpSecondPage(this.previousFields);

  @override
  _SecondFormPageState createState() => _SecondFormPageState();
}

class _SecondFormPageState extends State<SignUpSecondPage> {
  // Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthdayController = TextEditingController();

  final NavigationService _navigationService = locator<NavigationService>();

  List<String> newUser = [];

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF73AEF5),
          elevation: 0,
          toolbarHeight: 100,
          leadingWidth: 70,
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                _navigationService.pop();
              }),
        ),
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
                        SizedBox(height: 30.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 35.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'OpenSans'),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        // First Name Form Field
                        InputField(
                          controller: firstNameController,
                          placeholder: "First Name",
                          // icon: null,
                        ),
                        SizedBox(height: 20.0),

                        // Last Name Form Field
                        InputField(
                          controller: lastNameController,
                          placeholder: "Last Name",
                          // icon: null,
                        ),
                        SizedBox(height: 20.0),

                        // Birthday Form Field
                        // TO DO: Change to DatePicker field
                        InputField(
                          controller: birthdayController,
                          placeholder: "Birthday",
                          // icon: null,
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: RaisedButton(
                            elevation: 5,
                            padding: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            color: Colors.white,
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 16,
                                  fontFamily: 'OpenSans'),
                            ),
                            onPressed: () {
                              this.submitData();
                            },
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

  // Submit your data
  void submitData() {
    newUser.addAll(widget.previousFields);
    newUser.addAll([
      firstNameController.text,
      lastNameController.text,
      birthdayController.text,
    ]);
    print("Printing user...");
    print(newUser);

    // TO DO: Save to database
  }
}

// TO DO: Modify input_field.dart or create separate textform fields for fields that are not email and password
// TO DO: Try to make keyboard visibility work
