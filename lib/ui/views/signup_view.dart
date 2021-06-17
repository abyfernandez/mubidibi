import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/viewmodels/signup_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

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
  DateTime birthday;

  var emailNode = FocusNode();
  var passwordNode = FocusNode();

  // we update the value of this variable so that we can manipulate the 'next' button
  bool _isButtonDisabled = true;

  bool isButtonDisabled() {
    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "" &&
        passwordController.text.length >= 6) {
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
            middleNameController,
            lastNameController,
            suffixController,
            birthdayController,
            birthday,
          ],
        ),
      ),
    );

    if (result != null) {
      emailController = result[0];
      passwordController = result[1];
      firstNameController = result[2];
      middleNameController = result[3];
      lastNameController = result[4];
      suffixController = result[5];
      birthdayController = result[6];
      birthday = result[7];
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tz.initializeTimeZones();

    if (emailController.text.trim() != "" &&
        passwordController.text.trim() != "") {
      _isButtonDisabled = false;
    } else {
      _isButtonDisabled = true;
    }
  }

  final GlobalKey<FormState> _formKeyFirst = GlobalKey<FormState>();
  bool isPassword = true;
  String emailValidationMessage;
  String passwordValidationMessage;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SignUpViewModel>.withConsumer(
      viewModel: SignUpViewModel(),
      builder: (context, model, child) => Scaffold(
        // resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
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
                    child: Form(
                      key: _formKeyFirst,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 50.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Gumawa ng Account",
                                style: TextStyle(
                                  color: Colors.lightBlue,
                                  fontSize: 30.0, // 35
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
                            placeholder: "Email Address *",
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
                            placeholder: "Password *",
                            password: true,
                            onChanged: (val) {
                              setState(() {
                                isButtonDisabled();
                              });
                            },
                            enterPressed: isButtonDisabled()
                                ? null
                                : () {
                                    _goToSecondPage(context);
                                  },
                          ),

                          SizedBox(height: 20.0),

                          Container(
                            alignment: Alignment.centerRight,
                            child: FlatButton(
                                padding: EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                color: Colors.lightBlue,
                                disabledColor: Color.fromRGBO(240, 240, 240, 1),
                                child: Text(
                                  'Sumunod',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: isButtonDisabled()
                                    ? null
                                    : () {
                                        if (_formKeyFirst.currentState
                                            .validate()) {
                                          _goToSecondPage(context);
                                        }
                                      }),
                          ),
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
    );
  }
}

// SIGN UP SECOND PAGE
class SignUpSecondPage extends StatefulWidget {
  final List previousFields;

  SignUpSecondPage(this.previousFields);

  @override
  _SecondFormPageState createState() => _SecondFormPageState(previousFields);
}

class _SecondFormPageState extends State<SignUpSecondPage> {
  List previousFields;

  _SecondFormPageState(this.previousFields);

  // Controllers
  var emailController;
  var passwordController;
  var firstNameController;
  var middleNameController;
  var lastNameController;
  var suffixController;
  var birthdayController;
  DateTime birthday;

  // FocusNodes

  final suffixNode = FocusNode();
  final birthdayNode = FocusNode();

  final NavigationService _navigationService = locator<NavigationService>();

  bool _isButtonDisabled = true;
  bool _saving = false;

  bool isButtonDisabled() {
    // middle name and suffix are not required
    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "" &&
        birthday != null &&
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
        initialDate: birthday == null ? DateTime.now() : birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return child;
        });

    if (_datePicker != null && _datePicker != birthday) {
      setState(() {
        birthday = _datePicker;
        birthdayController.text =
            DateFormat("MMM. d, y", "fil").format(birthday) ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tz.initializeTimeZones();

    emailController = previousFields[0];
    passwordController = previousFields[1];
    firstNameController = previousFields[2];
    middleNameController = previousFields[3];
    lastNameController = previousFields[4];
    suffixController = previousFields[5];
    birthdayController = previousFields[6];
    birthday = previousFields[7];

    // middle name and suffix are not required
    if (firstNameController.text.trim() != "" &&
        lastNameController.text.trim() != "" &&
        birthday != null &&
        birthdayController.text.trim() != '') {
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
            backgroundColor: Colors.white,
            shadowColor: Colors.transparent,
            iconTheme: IconThemeData(
              color: Colors.black, //change your color here
            ),
            leading: GestureDetector(
                child: Icon(Icons.arrow_back),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context, [
                    emailController,
                    passwordController,
                    firstNameController,
                    middleNameController,
                    lastNameController,
                    suffixController,
                    birthdayController,
                    birthday,
                  ]);
                })),
        backgroundColor: Colors.white,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // SizedBox(height: 50.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Gumawa ng Account",
                                style: TextStyle(
                                  color: Colors.lightBlue,
                                  fontSize: 30.0, // 35
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Suffix Form Field
                              Container(
                                // height: 60.0,
                                width: (queryData.size.width / 2) - 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                  controller: suffixController,
                                  keyboardType: TextInputType.text,
                                  focusNode: suffixNode,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (val) {
                                    setState(() {
                                      isButtonDisabled();
                                    });
                                  },
                                  onEditingComplete: () {
                                    FocusScope.of(context)
                                        .requestFocus(birthdayNode);
                                  },
                                  onFieldSubmitted: (value) {
                                    birthdayController.requestFocus();
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                                    border: InputBorder.none,
                                    labelText: 'Suffix',
                                    labelStyle: TextStyle(
                                      color: Colors.black54,
                                    ),
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                              ),

                              // Birthday Form Field

                              Container(
                                // height: 60.0,
                                width: (queryData.size.width / 2) - 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    TextFormField(
                                      readOnly: true,
                                      onTap: () {
                                        _selectDate(context);
                                      },
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      controller: birthdayController,
                                      keyboardType: TextInputType.datetime,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        hintText: birthday != null
                                            ? DateFormat("MMM. d, y", "fil")
                                                .format(birthday)
                                            : "",
                                        hintStyle: TextStyle(
                                          color: Colors.black,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Color.fromRGBO(240, 240, 240, 1),
                                        border: InputBorder.none,
                                        labelText: 'Birthday *',
                                        labelStyle: TextStyle(
                                          color: Colors.black54,
                                        ),
                                        contentPadding: EdgeInsets.all(10),
                                      ),
                                      validator: (value) {
                                        if (value.isEmpty || value == null) {
                                          return 'This field is required.';
                                        }
                                        return null;
                                      },
                                    ),
                                    birthday != null
                                        ? Positioned(
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => setState(() {
                                                setState(() {
                                                  birthdayController.clear();
                                                  birthday = null;
                                                });
                                              }),
                                              child: Container(
                                                  height: 55,
                                                  width: 55,
                                                  alignment: Alignment.center,
                                                  child: Icon(Icons.close,
                                                      color: Colors.black54)),
                                            ),
                                          )
                                        : SizedBox(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FlatButton(
                                padding: EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                color: Colors.transparent,
                                child: Text(
                                  'Bumalik',
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
                                    birthdayController,
                                    birthday,
                                  ]);
                                },
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              FlatButton(
                                padding: EdgeInsets.all(10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                color: Colors.lightBlue,
                                disabledColor: Color.fromRGBO(240, 240, 240, 1),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: isButtonDisabled()
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();
                                        _saving = true;

                                        // Submit your data
                                        // create authenticated user in firebase using email address and password.
                                        // after creating user, save the remaining fields with the firebase user id in postgresql db
                                        // if adding to postgres db fails, delete the authenticated account from firebase

                                        var response = await model.signUp(
                                            email: emailController.text,
                                            password: passwordController.text,
                                            firstName: firstNameController.text,
                                            middleName:
                                                middleNameController?.text ??
                                                    null,
                                            lastName: lastNameController.text,
                                            suffix:
                                                suffixController?.text ?? null,
                                            birthday: birthday != null
                                                ? birthday.toUtc().toString()
                                                : null);

                                        if (response == true) {
                                          setState(() {
                                            _saving = false;
                                          });

                                          Fluttertoast.showToast(
                                              msg:
                                                  'Account creation successful.',
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
      ),
    );
  }
}
