import 'package:intl/intl.dart';
// import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/viewmodels/signup_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:flutter/services.dart';
// import 'package:mubidibi/locator.dart';

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
  var middleNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var suffixController = TextEditingController();
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
    print(_isButtonDisabled);
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
            middleNameController,
            lastNameController,
            suffixController,
            birthdayController
          ],
        ),
      ),
    );
    emailController = result[0];
    passwordController = result[1];
    firstNameController = result[2];
    middleNameController = result[3];
    lastNameController = result[4];
    suffixController = result[5];
    birthdayController = result[6];
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
    // TO DO: include user's  email address
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
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
                        // TO DO: BEFORE PROCEEDING TO NEXT PAGE, VALIDTE EMAIL FIRST
                        InputField(
                          controller: emailController,
                          placeholder: "Email Address",
                          onChanged: (val) {
                            setState(() {
                              isButtonDisabled();
                            });
                          },
                        ),
                        SizedBox(height: 20.0),
                        // Password Form Field
                        InputField(
                          controller: passwordController,
                          placeholder: "Password",
                          password: true,
                          onChanged: (val) {
                            setState(() {
                              isButtonDisabled();
                            });
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
  var middleNameController;
  var lastNameController;
  var suffixController;
  var birthdayController;
  DateTime _birthday;

  // final NavigationService _navigationService = locator<NavigationService>();

  bool _isButtonDisabled = true;

  bool isButtonDisabled() {
    // middle name, birthday and suffix are not required
    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "") {
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
        initialDate: _birthday == null ? DateTime.now() : _birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return child;
        });

    if (_datePicker != null && _datePicker != _birthday) {
      setState(() {
        _birthday = _datePicker;
        birthdayController.text =
            DateFormat("MMM. d, y").format(_birthday) ?? '';
      });
      print(_birthday);
    }
  }

  @override
  void initState() {
    super.initState();
    emailController = previousFields[0];
    passwordController = previousFields[1];
    firstNameController = previousFields[2];
    middleNameController = previousFields[3];
    lastNameController = previousFields[4];
    suffixController = previousFields[5];
    birthdayController = previousFields[6];

    // middle name, birthday and suffix are not required
    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);

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
                          placeholder: "First Name *",
                          onChanged: (val) {
                            setState(() {
                              isButtonDisabled();
                            });
                          },
                        ),
                        SizedBox(height: 20.0),

                        // Middle Name Form Field
                        InputField(
                          controller: middleNameController,
                          placeholder: "Middle Name",
                          onChanged: (val) {
                            setState(() {
                              isButtonDisabled();
                            });
                          },
                        ),
                        SizedBox(height: 20.0),

                        // Last Name Form Field
                        InputField(
                          controller: lastNameController,
                          placeholder: "Last Name *",
                          onChanged: (val) {
                            setState(() {
                              isButtonDisabled();
                            });
                          },
                        ),
                        SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Suffix Form Field
                            Container(
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.black),
                              ),
                              height: 60.0,
                              width: (queryData.size.width / 2) - 50,
                              child: TextFormField(
                                controller: suffixController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    isButtonDisabled();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Suffix",
                                  hintStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                  labelText: "Suffix",
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                  ),
                                  contentPadding: EdgeInsets.only(left: 15),
                                ),

                                // field is not required
                                // validator: (value) {
                                //   if (value.isEmpty || value == null) {
                                //     return 'This field is required';
                                //   }
                                //   return null;
                                // },
                              ),
                            ),

                            Container(
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.black),
                              ),
                              height: 60.0,
                              width: (queryData.size.width / 2) - 50,
                              child: TextFormField(
                                controller: birthdayController,
                                readOnly: true,
                                onTap: () {
                                  _selectDate(context);
                                },
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: _birthday != null
                                      ? DateFormat("MMM. d, y")
                                          .format(_birthday)
                                      : "Birthday",
                                  hintStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                  labelText: "Birthday",
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                  ),
                                  contentPadding: EdgeInsets.only(left: 15),
                                ),

                                // field is not required
                                // validator: (value) {
                                //   if (value.isEmpty || value == null) {
                                //     return 'This field is required';
                                //   }
                                //   return null;
                                // },
                              ),
                            ),

                            // Birthday Form Field
                            // Container(
                            //   width: 100,
                            //   child: InputField(
                            //     controller: birthdayController,
                            //     isReadOnly: true,
                            //     onTap: () {
                            //       _selectDate(context);
                            //     },
                            //     placeholder: "Birthday",
                            //     hintText: _birthday != null
                            //         ? DateFormat("MMM. d, y").format(_birthday)
                            //         : "Birthday",
                            //   ),
                            // ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),

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
                                  middleNameController,
                                  lastNameController,
                                  suffixController,
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
    // create authenticated user in firebase using email address and password.
    // after creating user, save the remaining fields with the firebase user id in postgresql db
    // if adding to postgres db fails, delete the authenticated account from firebase

    var model = SignUpViewModel();
    model.signUp(
        email: emailController.text,
        password: passwordController.text,
        firstName: firstNameController.text,
        middleName: middleNameController?.text ?? null,
        lastName: lastNameController.text,
        suffix: suffixController?.text ?? null,
        birthday: _birthday != null ? _birthday.toIso8601String() : null);
  }
}
