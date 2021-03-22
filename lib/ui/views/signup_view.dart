import 'package:intl/intl.dart';
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
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var birthdayController = TextEditingController();

  // we update the value of this variable so that we can manipulate the 'next' button
  bool _isButtonDisabled = true;

  bool isButtonDisabled() {
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
    return _isButtonDisabled;
  }

  _goToSecondPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpSecondPage(
          [
            emailController,
            passwordController,
            firstNameController,
            lastNameController,
            birthdayController
          ],
        ),
      ),
    );
    emailController = result[0];
    passwordController = result[1];
    firstNameController = result[2];
    lastNameController = result[3];
    birthdayController = result[4];
  }

  @override
  void initState() {
    super.initState();
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.lightBlue, //change your color here
          ),
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
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 50.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.lightBlue,
                                fontSize: 35.0,
                                fontWeight: FontWeight.bold,
                              ),
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
                          onChanged: (val) {
                            isButtonDisabled();
                          },
                        ),
                        SizedBox(height: 20.0),
                        // Password Form Field
                        InputField(
                          controller: passwordController,
                          placeholder: "Password",
                          password: true,
                          onChanged: (val) {
                            isButtonDisabled();
                          },
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: RaisedButton(
                              elevation: 5,
                              padding: EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              color: Colors.lightBlue,
                              disabledColor: Color.fromRGBO(192, 192, 192, 1),
                              child: Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: isButtonDisabled()
                                  ? null
                                  : () {
                                      _goToSecondPage(context);
                                    }),
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
  final List<TextEditingController> previousFields;

  SignUpSecondPage(this.previousFields);

  @override
  _SecondFormPageState createState() => _SecondFormPageState(previousFields);
}

class _SecondFormPageState extends State<SignUpSecondPage> {
  List<TextEditingController> previousFields;

  _SecondFormPageState(this.previousFields);

  // Controllers
  var emailController;
  var passwordController;
  var firstNameController;
  var lastNameController;
  var birthdayController;
  DateTime _birthday = DateTime.now();

  final NavigationService _navigationService = locator<NavigationService>();

  bool _isButtonDisabled = true;

  bool isButtonDisabled() {
    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "" &&
        birthdayController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
    return _isButtonDisabled;
  }

  // for birthday input field
  Future<Null> _selectDate(BuildContext context) async {
    DateTime _datePicker = await showDatePicker(
        context: context,
        initialDate: _birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData(
              primarySwatch: Colors.lightBlue,
              primaryColor: Colors.lightBlue,
              accentColor: Colors.white,
            ),
            child: child,
          );
        });

    if (_datePicker != null && _datePicker != _birthday) {
      setState(() {
        _birthday = _datePicker;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    emailController = previousFields[0];
    passwordController = previousFields[1];
    firstNameController = previousFields[2];
    lastNameController = previousFields[3];
    birthdayController = previousFields[4];

    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "" &&
        birthdayController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
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
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 50.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.lightBlue,
                                fontSize: 35.0,
                                fontWeight: FontWeight.bold,
                              ),
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
                          onChanged: (val) {
                            isButtonDisabled();
                          },
                        ),
                        SizedBox(height: 20.0),

                        // Last Name Form Field
                        InputField(
                          controller: lastNameController,
                          placeholder: "Last Name",
                          onChanged: (val) {
                            isButtonDisabled();
                          },
                        ),
                        SizedBox(height: 20.0),

                        // Birthday Form Field
                        // TO DO: Change to DatePicker field
                        InputField(
                          controller: birthdayController,
                          textInputType: TextInputType.datetime,
                          placeholder: "Birthday",
                          onChanged: (val) {
                            isButtonDisabled();
                          },
                        ),
                        // InputField(
                        //   controller: birthdayController,
                        //   isReadOnly: true,
                        //   onTap: () {
                        //     _selectDate(context);
                        //   },
                        //   placeholder: "Birthday",
                        //   hintText: DateFormat("MMM. d, y").format(_birthday),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            RaisedButton(
                              padding: EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              color: Colors.white,
                              child: Text(
                                'Back',
                                style: TextStyle(
                                  color: Color.fromRGBO(50, 50, 50, 1),
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context, [
                                  emailController,
                                  passwordController,
                                  firstNameController,
                                  lastNameController,
                                  birthdayController
                                ]);
                              },
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            RaisedButton(
                              padding: EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              color: Colors.lightBlue,
                              disabledColor: Color.fromRGBO(192, 192, 192, 1),
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: isButtonDisabled()
                                  ? null
                                  : () {
                                      this.submitData();
                                    },
                            ),
                          ],
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
    // newUser.addAll(widget.previousFields);
    // newUser.addAll([
    //   firstNameController.text,
    //   lastNameController.text,
    //   birthdayController.text,
    // ]);

    // created this array because i noticed that when u click the submit button multiple times it just appends the new data from the 2nd page
    List<String> newUser = [];
    newUser.addAll([
      emailController.text,
      passwordController.text,
      firstNameController.text,
      lastNameController.text,
      birthdayController.text,
    ]);

    // TO DO: Save to database
    print(newUser);
    // var model = SignUpViewModel();
    // var
  }
}
