// FORM VIEW: CREW (DIRECTORS, WRITERS, ACTORS)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// FOR DYNAMIC WIDGET ACTOR
List dynamicList = [];
List<Award> addedAward = [];
var size;
List<bool> opened = []; // state values of awards in listview

class AddCrew extends StatefulWidget {
  final Crew crew;

  AddCrew({Key key, this.crew}) : super(key: key);

  @override
  _AddCrewState createState() => _AddCrewState(crew);
}

// ADD MOVIE FIRST PAGE
class _AddCrewState extends State<AddCrew> {
  final Crew crew;

  _AddCrewState(this.crew);

  // Local state variables
  bool _saving = false;
  int crewId;
  File imageFile; // for uploading display photo w/ image picker
  final picker = ImagePicker();
  var mimetype;
  String base64Image; // picked image in base64 format
  var photos = List(); // for uploading crew photos
  var imageURI = ''; // for crew edit

  // CREW FIELD CONTROLLERS
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final suffixController = TextEditingController();
  DateTime _birthday;
  final birthdayController = TextEditingController();
  final birthplaceController = TextEditingController();
  bool isAlive = true;
  DateTime _deathdate;
  final deathdateController = TextEditingController();
  final descriptionController = TextEditingController();

  // CREW FIELD NODES
  final firstNameNode = FocusNode();
  final middleNameNode = FocusNode();
  final lastNameNode = FocusNode();
  final suffixNode = FocusNode();
  final birthdayNode = FocusNode();
  final birthplaceNode = FocusNode();
  final isAliveNode = FocusNode();
  final deathdateNode = FocusNode();
  final descriptionNode = FocusNode();

  // CREW FORMKEYS
  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = ["Basic Details", "Photos", "Awards", "Review"];

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // Function: Shows datepicker and update value of Date
  Future<Null> _selectDate(BuildContext context, String mode) async {
    if (mode == "birthday") {
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
      }
    } else {
      DateTime _datePicker = await showDatePicker(
          context: context,
          initialDate: _deathdate == null ? DateTime.now() : _deathdate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
          initialDatePickerMode: DatePickerMode.day,
          builder: (BuildContext context, Widget child) {
            return child;
          });

      if (_datePicker != null && _datePicker != _deathdate) {
        setState(() {
          _deathdate = _datePicker;
          deathdateController.text =
              DateFormat("MMM. d, y").format(_deathdate) ?? '';
        });
      }
    }
  }

  // Function: get image using image picker for crew's display photo
  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      setState(() {
        imageFile = imageFile;
        mimetype = lookupMimeType(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  // Function: get images using image picker for movie screenshots
  Future getPhotos() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      var image = File(pickedFile.path);
      setState(() {
        photos.add(image);
      });
    } else {
      print('No image selected.');
    }
  }

  // Function: display screenshots in a scrollable horizontal view
  Widget displayPhotos(String mode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: photos
          .map(
            (pic) => Stack(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 70,
                  width: 70,
                  child: Image.file(
                    pic,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                mode == "edit"
                    ? Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        child: GestureDetector(
                          child: Icon(Icons.close),
                          onTap: () {
                            setState(() {
                              photos.remove(pic);
                            });
                          },
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(0.0, 1.0),
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                      )
                    : Container(),
              ],
            ),
          )
          .toList(),
    );
  }

  // Function: adds AwardWidget in the ListView builder
  addAward() {
    setState(() {
      size = dynamicList.length; // pass the index of the widget to the class

      // add award widget to list
      dynamicList.add(
          AwardWidget(key: ObjectKey(size), item: new Award(), size: size));
      opened.add(true);
    });
  }

  Widget displayAwards() {
    var count = 1;
    // return Container();
    return Column(
        children: dynamicList.map((item) {
      return Text(count.toString() + ". " + item.item.name != null
          ? item.item.name
          : "test" + " ");
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    return ViewModelProvider<CrewViewModel>.withConsumer(
      viewModel: CrewViewModel(),
      onModelReady: (model) async {
        crewId = crew?.crewId ?? 0;

        // update controller's text field
        firstNameController.text = crew?.firstName ?? "";
        middleNameController.text = crew?.middleName ?? "";
        lastNameController.text = crew?.lastName ?? "";
        suffixController.text = crew?.suffix ?? "";
        _birthday =
            crew?.birthday != null ? DateTime.parse(crew?.birthday) : null;
        birthplaceController.text = crew?.birthplace ?? "";
        isAlive = crew?.isAlive ?? true;
        deathdateController.text = crew?.deathdate ?? "";
        _deathdate =
            crew?.birthday != null ? DateTime.parse(crew?.birthday) : null;
        descriptionController.text = crew?.description ?? "";
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();

              var response = await _dialogService.showConfirmationDialog(
                  title: "Confirm cancellation",
                  cancelTitle: "No",
                  confirmationTitle: "Yes",
                  description: "Are you sure that you want to close the form?");
              if (response.confirmed == true) {
                _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            crew != null
                ? "Mag-edit ng Personalidad"
                : "Magdagdag ng Personalidad",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            child: Stack(
              children: <Widget>[
                Container(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.0,
                    ),
                    // TO DO: UI IDEA -> gawing collapsible yung add photo pag nagscroll para di masyadong matakaw sa space
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        MyStepper(
                          type: MyStepperType.vertical,
                          currentStep: currentStep,
                          onStepTapped: (step) async {
                            FocusScope.of(context).unfocus();
                            if (currentStep == 0) {
                              // first step
                              setState(() {
                                if (_formKeys[currentStep]
                                    .currentState
                                    .validate()) {
                                  currentStep = step;
                                }
                              });
                            } else {
                              // allow tapping of steps
                              setState(() => currentStep = step);
                            }
                          },
                          onStepCancel: () {
                            FocusScope.of(context).unfocus();

                            if (currentStep != 0) setState(() => --currentStep);
                          }, // else do nothing
                          onStepContinue: () async {
                            if (currentStep + 1 != stepperTitle.length) {
                              FocusScope.of(context).unfocus();
                              // do not allow user to continue to next step if inputs aren't filled out yet
                              switch (currentStep) {
                                case 0: // basic details
                                  setState(() {
                                    if (_formKeys[currentStep]
                                        .currentState
                                        .validate()) {
                                      currentStep++;
                                    }
                                  });
                                  break;

                                case 1: // photos
                                  setState(() {
                                    FocusScope.of(context).unfocus();
                                    currentStep++;
                                  });
                                  break;

                                case 2: // awards
                                  FocusScope.of(context).unfocus();
                                  setState(() => ++currentStep);
                                  break;
                              }
                            } else {
                              // last step
                              FocusScope.of(context).unfocus();
                              var confirm =
                                  await _dialogService.showConfirmationDialog(
                                      title: "Confirm Details",
                                      cancelTitle: "No",
                                      confirmationTitle: "Yes",
                                      description:
                                          "Are you sure that you want to continue?");
                              if (confirm.confirmed == true) {
                                _saving =
                                    true; // set saving to true to trigger circular progress indicator

                                final response = await model.addCrew(
                                    firstName: firstNameController.text,
                                    middleName: middleNameController.text,
                                    lastName: lastNameController.text,
                                    suffix: suffixController.text,
                                    birthday: _birthday != null
                                        ? _birthday.toIso8601String()
                                        : '',
                                    birthplace: birthplaceController.text,
                                    isAlive: isAlive,
                                    deathdate: _deathdate != null
                                        ? _deathdate.toIso8601String()
                                        : '',
                                    description: descriptionController.text,
                                    displayPic: imageFile,
                                    imageURI: imageURI,
                                    photos: photos,
                                    mimetype: mimetype,
                                    addedBy: currentUser.userId,
                                    crewId: crewId);

                                // when response is returned, stop showing circular progress indicator

                                if (response != 0) {
                                  _saving =
                                      false; // set saving to false to trigger circular progress indicator
                                  // show success snackbar
                                  _scaffoldKey.currentState.showSnackBar(
                                      mySnackBar(
                                          context,
                                          'Crew added successfully.',
                                          Colors.green));

                                  _saving =
                                      true; // set saving to true to trigger circular progress indicator

                                  // get movie using id redirect to detail view using response
                                  var crewRes = await model.getOneCrew(
                                      crewId: response.toString());

                                  if (crewRes != null) {
                                    _saving =
                                        false; // set saving to false to trigger circular progress indicator
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CrewView(
                                            crewId: crewRes.crewId.toString()),
                                      ),
                                    );
                                  }
                                } else {
                                  _saving =
                                      false; // set saving to false to trigger circular progress indicator
                                  // show error snackbar
                                  _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                      context,
                                      'Something went wrong. Check your inputs and try again.',
                                      Colors.red));
                                }
                              }
                            }
                          },
                          steps: [
                            for (var i = 0; i < stepperTitle.length; i++)
                              MyStep(
                                title: Text(
                                  stepperTitle[i],
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                isActive: i <= currentStep,
                                state: i == currentStep
                                    ? MyStepState.editing
                                    : i < currentStep
                                        ? MyStepState.complete
                                        : MyStepState.indexed,
                                content: LimitedBox(
                                  maxWidth: 300,
                                  child: Form(
                                      key: _formKeys[i], child: getContent(i)),
                                ),
                              ),
                          ],
                        ),
                        // Container(
                        //   alignment: Alignment.center,
                        //   height: 130,
                        //   width: 130,
                        //   decoration: BoxDecoration(
                        //       color: Color.fromRGBO(240, 240, 240, 1),
                        //       borderRadius: BorderRadius.circular(100)),
                        //   child: GestureDetector(
                        //       child: Icon(Icons.camera_alt_outlined,
                        //           size: 30, color: Colors.grey),
                        //       onTap: () {
                        //         print('add display pic');
                        //       }),
                        // ),

                        // SizedBox(height: 20),
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

  Widget getContent(int index) {
    switch (index) {
      case 0: // basic details
        return Container(
          child: Column(
            children: [
              SizedBox(height: 15),
              // CREW FIRST NAME
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  autofocus: true,
                  focusNode: firstNameNode,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  controller: firstNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    middleNameNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    filled: true,
                    labelText: "First Name *",
                    contentPadding: EdgeInsets.all(10),
                  ),
                  validator: (value) {
                    if (value.isEmpty || value == null) {
                      return 'Required ang field na ito.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 15),
              // CREW MIDDLE NAME
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: TextFormField(
                  focusNode: middleNameNode,
                  textCapitalization: TextCapitalization.words,
                  controller: middleNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    lastNameNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Middle Name",
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CREW LAST NAME
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: lastNameNode,
                  textCapitalization: TextCapitalization.words,
                  controller: lastNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    suffixNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Last Name *",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                  validator: (value) {
                    if (value.isEmpty || value == null) {
                      return 'Required ang field na ito.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 15),
              // CREW SUFFIX
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: suffixNode,
                  textCapitalization: TextCapitalization.words,
                  controller: suffixController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    birthdayNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Suffix",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CREW BIRTHDAY
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  children: [
                    TextFormField(
                      readOnly: true,
                      focusNode: birthdayNode,
                      keyboardType: TextInputType.datetime,
                      controller: birthdayController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      onFieldSubmitted: (val) {
                        birthplaceNode.requestFocus();
                      },
                      onTap: () {
                        _selectDate(context, "birthday");
                      },
                      decoration: InputDecoration(
                        labelText: "Birthday",
                        filled: true,
                        fillColor: Color.fromRGBO(240, 240, 240, 1),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    _birthday != null
                        ? PositionedDirectional(
                            top: 10,
                            end: 10,
                            bottom: 10,
                            child: GestureDetector(
                              child: Icon(Icons.close_outlined,
                                  color: Color.fromRGBO(150, 150, 150, 1)),
                              onTap: () {
                                setState(() {
                                  _birthday = null;
                                  birthdayController.text = "";
                                });
                              },
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // CREW BIRTHPLACE
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: birthplaceNode,
                  textCapitalization: TextCapitalization.words,
                  controller: birthplaceController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    isAliveNode.requestFocus();
                  },
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Birthplace",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Text("Is this person still alive?",
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic)),
                    Row(
                      children: [
                        Switch(
                          focusNode: isAliveNode,
                          value: isAlive == null ? true : isAlive,
                          onChanged: (bool newValue) {
                            setState(() {
                              isAlive = newValue;
                            });
                          },
                        ),
                        // CREW DEATHDATE
                        isAlive == false
                            ? Flexible(
                                child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Stack(
                                  children: [
                                    TextFormField(
                                      readOnly: true,
                                      focusNode: deathdateNode,
                                      keyboardType: TextInputType.datetime,
                                      controller: deathdateController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      onTap: () {
                                        _selectDate(context, "deathdate");
                                      },
                                      decoration: InputDecoration(
                                        labelText: "Death date",
                                        filled: true,
                                        fillColor:
                                            Color.fromRGBO(240, 240, 240, 1),
                                        contentPadding: EdgeInsets.all(10),
                                      ),
                                    ),
                                    _birthday != null
                                        ? PositionedDirectional(
                                            top: 10,
                                            end: 10,
                                            bottom: 10,
                                            child: GestureDetector(
                                              child: Icon(Icons.close_outlined,
                                                  color: Color.fromRGBO(
                                                      150, 150, 150, 1)),
                                              onTap: () {
                                                setState(() {
                                                  _deathdate = null;
                                                  deathdateController.text = "";
                                                });
                                              },
                                            ),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ))
                            : SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        );
      case 1: // photos
        return Container(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text('Display Photo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              Stack(
                children: [
                  GestureDetector(
                    onTap: getImage,
                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      height: 200,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: imageFile != null || imageURI.trim() != ''
                          ? Container(
                              height: 200,
                              width: 150,
                              child: imageFile != null
                                  ? Image.file(
                                      imageFile,
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      imageURI,
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ))
                          : Container(
                              height: 200,
                              width: 150,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey[800],
                              ),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(240, 240, 240, 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                    ),
                  ),
                  imageFile != null || imageURI.trim() != ''
                      ? Container(
                          margin: EdgeInsets.only(left: 25, top: 5),
                          width: 25,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            child: Icon(Icons.close),
                            onTap: () {
                              setState(() {
                                imageFile = null;
                                imageURI = '';
                              });
                            },
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                offset: Offset(0.0, 2.0),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                        )
                      : Container(),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Text('Mga Litrato',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              // TO DO: multiple files for screenshots
              Padding(
                padding: EdgeInsets.only(left: 15),
                child: Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            child: GestureDetector(
                              child: Icon(Icons.image),
                              onTap: getPhotos,
                            ),
                            width: 70,
                            height: 70,
                            color: Color.fromRGBO(240, 240, 240, 1)),
                        photos.length != 0
                            ? displayPhotos("edit")
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 2: // awards
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mga Award:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 140,
                child: dynamicList.isEmpty
                    ? FlatButton(
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addAward,
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1_outlined),
                            Text(" Dagdagan")
                          ],
                        ),
                      )
                    : null,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView(
                    shrinkWrap: true,
                    children: dynamicList.map((item) {
                      // TO DO: remove delete button when item is closed
                      return Stack(
                        key: ObjectKey(item),
                        children: [
                          item,
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              child: OutlineButton(
                                padding: EdgeInsets.all(0),
                                color: Colors.white,
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() {
                                    opened.removeAt(dynamicList
                                        .indexOf(item)); // TO DO: Fix this
                                    dynamicList
                                        .removeAt(dynamicList.indexOf(item));
                                    // addedAward.removeAt() // TO DO: ANONG IDEDELETE
                                  });
                                },
                                child: Text('Tanggalin'),
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  Container(
                    width: 140,
                    alignment: Alignment.centerLeft,
                    child: dynamicList.isNotEmpty
                        ? FlatButton(
                            color: Color.fromRGBO(192, 192, 192, 1),
                            onPressed: addAward,
                            child: Row(
                              children: [
                                Icon(Icons.person_add_alt_1_outlined),
                                Text(" Dagdagan")
                              ],
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 3: // review
        return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color.fromRGBO(240, 240, 240, 1),
            ),
            padding: EdgeInsets.all(10),
            child: Scrollbar(
              child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Name: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          firstNameController.text +
                              (middleNameController.text.trim() != ""
                                  ? " " + middleNameController.text
                                  : "") +
                              " " +
                              lastNameController.text +
                              (suffixController.text.trim() != ""
                                  ? " " + suffixController.text
                                  : ""),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _birthday != null ? SizedBox(height: 10) : SizedBox(),
                      _birthday != null
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Birthday: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : SizedBox(),
                      _birthday != null
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                _birthday == null
                                    ? ''
                                    : DateFormat("MMM. d, y").format(_birthday),
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ))
                          : SizedBox(),
                      birthplaceController.text.trim() != ""
                          ? SizedBox(height: 10)
                          : SizedBox(),
                      birthplaceController.text.trim() != ""
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Birthplace: ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : SizedBox(),
                      birthplaceController.text.trim() != ""
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                birthplaceController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ))
                          : SizedBox(),
                      isAlive == false ? SizedBox(height: 10) : SizedBox(),
                      isAlive == false
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text("Died: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      isAlive == false
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                  _deathdate == null
                                      ? 'No information'
                                      : DateFormat("MMM. d, y")
                                          .format(_deathdate),
                                  style: TextStyle(
                                    fontStyle: _deathdate == null
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      imageFile != null ? SizedBox(height: 10) : SizedBox(),
                      imageFile != null
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text("Display Photo: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      imageFile != null
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: imageFile != null
                                  ? Image.file(
                                      imageFile,
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            )
                          : SizedBox(),
                      photos.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                      photos.isNotEmpty
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text("Mga Litrato: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      photos.isNotEmpty ? displayPhotos("display") : SizedBox(),

                      // TO DO: add awards
                      dynamicList.isNotEmpty ? displayAwards() : SizedBox()
                    ],
                  )),
            ));
    }
    return null;
  }
}

// CLASS AWARD WIDGET
class AwardWidget extends StatefulWidget {
  final Award item;
  final size;

  const AwardWidget({Key key, this.item, this.size}) : super(key: key);

  @override
  AwardWidgetState createState() => AwardWidgetState();
}

class AwardWidgetState extends State<AwardWidget> {
  // Temp Variables
  String name;
  String year;
  String description;
  String type; // nominated, won
  bool closed = false;

  // FocusNodes
  final nameNode = FocusNode();
  final descriptionNode = FocusNode();
  final typeNode = FocusNode();
  final yearNode = FocusNode();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return closed == false
        ? Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromRGBO(240, 240, 240, 1),
                  ),
                  child: TextFormField(
                    initialValue: widget.item.name,
                    autofocus: true,
                    focusNode: nameNode,
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    onFieldSubmitted: (val) {
                      yearNode.requestFocus();
                    },
                    onChanged: (val) {
                      setState(() {
                        name = val;
                        widget.item.name = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Award *",
                      // contentPadding: EdgeInsets.all(10),
                      filled: true,
                      fillColor: Color.fromRGBO(240, 240, 240, 1),
                    ),
                    validator: (value) {
                      if (value.isEmpty || value == null) {
                        return 'Required ang field na ito.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color.fromRGBO(240, 240, 240, 1),
                        ),
                        child: TextFormField(
                          initialValue: widget.item.year,
                          focusNode: yearNode,
                          keyboardType: TextInputType.number,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          onFieldSubmitted: (val) {
                            typeNode.requestFocus();
                          },
                          onChanged: (val) {
                            setState(() {
                              year = val;
                              widget.item.year = val;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "Year",
                            contentPadding: EdgeInsets.all(10),
                            filled: true,
                            fillColor: Color.fromRGBO(240, 240, 240, 1),
                          ),
                          validator: (value) {
                            var date = DateFormat("y").format(DateTime.now());
                            if ((value.length < 4 && value.length > 0) ||
                                (value.length > 4 &&
                                    int.parse(value) > int.parse(date))) {
                              return 'Mag-enter ng tamang taon.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.black54)),
                          color: Color.fromRGBO(240, 240, 240, 1),
                        ),
                        child: DropdownButton(
                          autofocus: false,
                          focusNode: typeNode,
                          value: widget.item.type,
                          items: [
                            DropdownMenuItem(
                                child: Text("Pumili ng isa",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true),
                                value: ""),
                            DropdownMenuItem(
                                child: Text("Nominated"), value: "nominated"),
                            DropdownMenuItem(child: Text("Won"), value: "won"),
                          ],
                          hint: Text('Type'),
                          elevation: 0,
                          isDense: false,
                          underline: Container(),
                          onChanged: (val) {
                            setState(() {
                              type = val;
                              widget.item.type = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: TextFormField(
                    initialValue: widget.item.description,
                    focusNode: descriptionNode,
                    textCapitalization: TextCapitalization.sentences,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    maxLines: null, // 5
                    decoration: InputDecoration(
                      labelText: "Description",
                      contentPadding: EdgeInsets.all(10),
                      filled: true,
                      fillColor: Color.fromRGBO(240, 240, 240, 1),
                    ),
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (val) {
                      setState(() {
                        description = val;
                        widget.item.description = val;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  child: OutlineButton(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    color: Colors.white,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      if (_formKey.currentState.validate()) {
                        setState(() {
                          opened[widget.size] = false;
                          widget.item.name = name;
                          widget.item.year = year;
                          widget.item.description = description;
                          widget.item.type = type;
                          closed = true;

                          addedAward[widget.size] = widget.item;
                        });
                      }
                    },
                    child: Text('Save'),
                  ),
                  alignment: Alignment.center,
                ),
              ],
            ))
        : ListTile(
            contentPadding: EdgeInsets.all(10),
            tileColor: Color.fromRGBO(240, 240, 240, 1),
            title: Text(
                (widget.item.name != null ? widget.item.name : '') +
                    (widget.item.year != null
                        ? " (" + widget.item.year + ") "
                        : ''),
                softWrap: true,
                overflow: TextOverflow.clip),
            subtitle: Text(
                widget.item.description != null ? widget.item.description : '',
                style: TextStyle(
                  fontSize: 14,
                ),
                textAlign: TextAlign.justify),
            trailing: GestureDetector(
              child: Icon(Icons.edit),
              onTap: () {
                setState(() {
                  closed = false;
                  opened[widget.size] = true;
                });
              },
            ),
          );
  }
}
