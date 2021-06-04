// FORM VIEW: CREW (DIRECTORS, WRITERS, ACTORS)

import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/movie_actor.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/widgets/award_widget.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
// import 'package:mubidibi/globals.dart' as Config;

// Global Variables for dynamic Widgets
List<int> movieActorsFilter = []; // movies

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
  var currentUser;
  bool _saving = false;
  int crewId;
  File imageFile; // for uploading display photo w/ image picker
  var mimetype;
  var photos = List(); // for uploading crew photos
  var imageURI = ''; // for crew edit

  List<Movie> movieOptions;
  List<Award> awardOptions;
  List<Movie> movieDirector = [];
  List<Movie> movieWriter = [];
  List<AwardWidget> awardList = [];
  List<AwardWidget> filteredAwards = [];
  List<MovieActorWidget> movieActorList = [];
  List<MovieActorWidget> filteredMovieActorList = [];

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
    GlobalKey<FormState>(),
  ];

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Mga Basic na Detalye",
    "Mga Pelikula",
    "Mga Larawan",
    "Mga Award",
    "Review"
  ];

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // Function: Display MovieActor in the Review Step
  Widget displayMovieActors() {
    filteredMovieActorList =
        movieActorList.where((item) => item.movieActor.saved == true).toList();

    return Column(
      children: [
        filteredMovieActorList.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredMovieActorList.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Bilang Aktor: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        // TO DO: fix overflow issue when text is too long
        filteredMovieActorList.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredMovieActorList.map((film) {
                    if (film.movieActor.saved == true) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              new Expanded(
                                child: Text(film.movieActor.movieTitle,
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: film.movieActor.role.length != 0
                                ? Text(" - " + film.movieActor.role.join(" / "),
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip)
                                : SizedBox(),
                          ),
                        ],
                      );
                    }
                  }).toList(),
                ),
              )
            : SizedBox(),
      ],
    );
  }

  addMovieActor() {
    setState(() {
      // add Movie Actor widget to the list
      movieActorList.add(MovieActorWidget(
          movieOptions: movieOptions,
          movieActor: new MovieActor(),
          open: ValueNotifier<bool>(true)));
    });
  }

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
    FilePickerResult result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);

    if (result != null) {
      imageFile = File(result.files.single.path);
      setState(() {
        imageFile = imageFile;
        mimetype = lookupMimeType(result.files.single.path);
      });
    } else {
      // User canceled the picker
      print("No image selected.");
    }
  }

  // Function: get images using image picker for movie screenshots
  Future getPhotos() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png']);

    if (result != null) {
      List imagePaths =
          photos.isNotEmpty ? photos.map((img) => img.path).toList() : [];

      List toUpload = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        }
      }).toList();

      if (toUpload.isNotEmpty) {
        setState(() {
          for (var i = 0; i < toUpload.length; i++) {
            if (toUpload[i] != null) {
              photos.add(toUpload[i]);
            }
          }
        });
      }
    } else {
      // User canceled the picker
      print('No image selected.');
    }
  }

  // Function: display photos in a scrollable horizontal view
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
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(0.0, 0.0),
                              blurRadius: 0.0,
                            ),
                          ],
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          )
          .toList(),
    );
  }

  // Function: adds AwardWidget in the ListView builder
  addAward() {
    setState(() {
      // add award widget to list
      awardList.add(AwardWidget(
          awardOptions: awardOptions,
          item: new Award(),
          open: ValueNotifier<bool>(true)));
    });
  }

  // Function: Display Awards in the Review Step
  Widget displayAwards() {
    filteredAwards =
        awardList.where((award) => award.item.saved == true).toList();

    return Column(
      children: [
        filteredAwards.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredAwards.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Award: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        // TO DO: fix overflow issue when text is too long
        filteredAwards.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredAwards.map((award) {
                    if (award.item.saved == true) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          new Icon(Icons.fiber_manual_record, size: 16),
                          SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text(
                                award.item.name +
                                    (award.item.year != null
                                        ? " (" + award.item.year + ") "
                                        : ""),
                                style: TextStyle(fontSize: 16),
                                softWrap: true,
                                overflow: TextOverflow.clip),
                          ),
                          award.item.type != null
                              ? Text(
                                  " - " +
                                      (award.item.type == "nominated"
                                          ? "Nominado"
                                          : "Panalo"),
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 16),
                                  softWrap: true,
                                  overflow: TextOverflow.clip)
                              : SizedBox(),
                        ],
                      );
                    }
                  }).toList(),
                ),
              )
            : SizedBox(),
      ],
    );
  }

  Future<bool> onBackPress() async {
    // used in onwillpopscope function
    var response = await _dialogService.showConfirmationDialog(
        title: "Confirm cancellation",
        cancelTitle: "No",
        confirmationTitle: "Yes",
        description: "Are you sure that you want to close the form?");
    if (response.confirmed == true) {
      setState(() {
        movieActorsFilter =
            []; // clears list para pag binalikan sya empty na ulit
      });
      await _navigationService.pop();
    }
    return Future.value(false);
  }

  void fetchMovies() async {
    var model = MovieViewModel();
    movieOptions = await model.getAllMovies(mode: "form");
  }

  void fetchAwards() async {
    var model = AwardViewModel();
    awardOptions = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'crew');
  }

  @override
  void initState() {
    currentUser = _authenticationService.currentUser;
    fetchMovies();
    fetchAwards();
    super.initState();
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
                setState(() {
                  movieActorsFilter = [];
                });
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
        body: WillPopScope(
          onWillPop: onBackPress,
          child: ModalProgressHUD(
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
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            MyStepper(
                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons.movie_outlined, // Mga Pelikula
                                Icons.image, // Mga Larawan
                                Icons.emoji_events_outlined, // Mga Award
                                Icons.grading // Review
                              ],
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

                                if (currentStep != 0)
                                  setState(() => --currentStep);
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

                                    case 1: // movies
                                      setState(() {
                                        FocusScope.of(context).unfocus();
                                        currentStep++;
                                      });
                                      break;

                                    case 2: // photos
                                      FocusScope.of(context).unfocus();
                                      setState(() => ++currentStep);
                                      break;

                                    case 3: // awards
                                      FocusScope.of(context).unfocus();
                                      setState(() => ++currentStep);
                                      break;
                                  }
                                } else {
                                  // last step
                                  FocusScope.of(context).unfocus();
                                  var confirm = await _dialogService
                                      .showConfirmationDialog(
                                          title: "Confirm Details",
                                          cancelTitle: "No",
                                          confirmationTitle: "Yes",
                                          description:
                                              "Are you sure that you want to continue?");
                                  if (confirm.confirmed == true) {
                                    _saving =
                                        true; // set saving to true to trigger circular progress indicator

                                    // actors
                                    List<MovieActor> movieActorsToSave = [];
                                    if (filteredMovieActorList.isNotEmpty) {
                                      movieActorsToSave = filteredMovieActorList
                                          .map((a) => a.movieActor)
                                          .toList();
                                    }

                                    // awards
                                    List<Award> awardsToSave = [];
                                    if (filteredAwards.isNotEmpty) {
                                      awardsToSave = filteredAwards
                                          .map((a) => a.item)
                                          .toList();
                                    }

                                    // movieDirectors
                                    List<int> movieDirectorsToSave = [];
                                    if (movieDirector.isNotEmpty) {
                                      movieDirectorsToSave = movieDirector
                                          .map((a) => a.movieId)
                                          .toList();
                                    }

                                    // movieWriters
                                    List<int> movieWritersToSave = [];
                                    if (movieWriter.isNotEmpty) {
                                      movieWritersToSave = movieWriter
                                          .map((a) => a.movieId)
                                          .toList();
                                    }

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
                                        director: movieDirectorsToSave,
                                        writer: movieWritersToSave,
                                        actor: movieActorsToSave,
                                        awards: awardsToSave,
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
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CrewView(
                                                  crewId: crewRes.crewId
                                                      .toString()),
                                            ),
                                          );
                                        });
                                      }
                                    } else {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
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
                                          key: _formKeys[i],
                                          child: getContent(i)),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
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
                    labelText: "Last Name",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
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
                        : SizedBox(),
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
      case 1: // Movies
        return Container(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 10),
            Text('Bilang Direktor:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(240, 240, 240, 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ChipsInput(
                initialValue: movieDirector,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();
                    return movieOptions.where((item) {
                      return item.title
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return movieOptions;
                },
                onChanged: (data) {
                  movieDirector = data;
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c.title),
                    onDeleted: () => state.deleteChip(c),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.title),
                    onTap: () => state.selectSuggestion(c),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Bilang Manunulat:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(240, 240, 240, 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ChipsInput(
                initialValue: movieWriter,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();
                    return movieOptions.where((item) {
                      return item.title
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return movieOptions;
                },
                onChanged: (data) {
                  movieWriter = data;
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c.title),
                    onDeleted: () => state.deleteChip(c),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.title),
                    onTap: () => state.selectSuggestion(c),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Bilang Aktor:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 140,
              child: movieActorList.isEmpty
                  ? FlatButton(
                      // focusNode: addActorNode,
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addMovieActor,
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined),
                          Text(" Dagdagan")
                        ],
                      ),
                    )
                  : null,
            ),
            ListView.builder(
                itemCount: movieActorList.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int i) {
                  return ValueListenableBuilder(
                      valueListenable: movieActorList[i].open,
                      builder: (context, value, widget) {
                        return Stack(
                          children: [
                            movieActorList[i],
                            value == true
                                ? Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      child: OutlineButton(
                                        padding: EdgeInsets.all(0),
                                        color: Colors.white,
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            movieActorList.removeAt(i);
                                          });
                                        },
                                        child: Text('Tanggalin'),
                                      ),
                                      alignment: Alignment.centerRight,
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        );
                      });
                }),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 140,
              child: movieActorList.isNotEmpty
                  ? FlatButton(
                      // focusNode: addActorNode,
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addMovieActor,
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined),
                          Text(" Dagdagan")
                        ],
                      ),
                    )
                  : null,
            ),
            SizedBox(
              height: 10,
            ),
            Divider(height: 1, thickness: 2),
          ]),
        );
      case 2: // Photos
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
                  // SizedBox(height: 20),
                  GestureDetector(
                    onTap: getImage,
                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      height: 200, // 200
                      width: 150, // 150
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: imageFile != null || imageURI.trim() != ''
                          ?
                          // Container(
                          //     alignment: Alignment.center,
                          //     height: 130,
                          //     width: 130,
                          //     decoration: BoxDecoration(
                          //         color: Color.fromRGBO(240, 240, 240, 1),
                          //         borderRadius: BorderRadius.circular(100)),
                          //     child: GestureDetector(
                          //         child: Icon(Icons.camera_alt_outlined,
                          //             size: 30, color: Colors.black),
                          //         onTap: () {
                          //           print('add display pic');
                          //         }),
                          //   )
                          Container(
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
                          :
                          // Container(
                          //     alignment: Alignment.center,
                          //     height: 130,
                          //     width: 130,
                          //     decoration: BoxDecoration(
                          //         color: Color.fromRGBO(240, 240, 240, 1),
                          //         borderRadius: BorderRadius.circular(100)),
                          //     child: GestureDetector(
                          //         child: Icon(Icons.camera_alt_outlined,
                          //             size: 30, color: Colors.black),
                          //         onTap: () {
                          //           print('add display pic');
                          //         }),
                          //   ),
                          Container(
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
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                offset: Offset(0.0, 0.0),
                                blurRadius: 0.0,
                              ),
                            ],
                          ),
                        )
                      : SizedBox(),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Text('Mga Larawan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
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
                        photos.length != 0 ? displayPhotos("edit") : SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 3: // Awards
        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                child: awardList.isEmpty
                    ? FlatButton(
                        // focusNode: addActorNode,
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
              ListView.builder(
                  itemCount: awardList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: awardList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              awardList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              awardList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              SizedBox(
                height: 10,
              ),
              Container(
                width: 140,
                child: awardList.isNotEmpty
                    ? FlatButton(
                        // focusNode: addActorNode,
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
              SizedBox(
                height: 10,
              ),
              Divider(height: 1, thickness: 2),
            ],
          ),
        );
      case 4: // review
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          overflow: TextOverflow.clip,
                          softWrap: true,
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
                                overflow: TextOverflow.clip,
                                softWrap: true,
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
                                      ? 'Walang record'
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
                      movieDirector.isNotEmpty
                          ? SizedBox(height: 10)
                          : SizedBox(),
                      movieDirector.isNotEmpty
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text("Bilang Direktor: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      movieDirector.isNotEmpty
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Column(
                                  children: movieDirector.map<Widget>((film) {
                                return new Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    new Expanded(
                                      child: Text(
                                        film.title,
                                        style: TextStyle(fontSize: 16),
                                        overflow: TextOverflow.clip,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList()),
                            )
                          : SizedBox(),
                      movieWriter.isNotEmpty
                          ? SizedBox(height: 10)
                          : SizedBox(),
                      movieWriter.isNotEmpty
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Text("Bilang Manunulat: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            )
                          : SizedBox(),
                      movieWriter.isNotEmpty
                          ? Container(
                              alignment: Alignment.topLeft,
                              child: Column(
                                  children: movieWriter.map<Widget>((film) {
                                return new Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    new Expanded(
                                      child: Text(
                                        film.title,
                                        style: TextStyle(fontSize: 16),
                                        overflow: TextOverflow.clip,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList()),
                            )
                          : SizedBox(),
                      displayMovieActors(),
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
                      displayAwards(),
                      SizedBox(height: 15),
                    ],
                  )),
            ));
    }
    return null;
  }
}

// Movie Actor Widget
class MovieActorWidget extends StatefulWidget {
  final List<Movie> movieOptions;
  final MovieActor movieActor;
  final open;

  const MovieActorWidget(
      {Key key, this.movieActor, this.movieOptions, this.open})
      : super(key: key);

  @override
  MovieActorWidgetState createState() => MovieActorWidgetState();
}

class MovieActorWidgetState extends State<MovieActorWidget> {
  List<String> tempRoles;
  Movie tempMovie;
  var temp;
  bool showError = true;
  List<Movie> movieActorId = [];

  @override
  void initState() {
    widget.movieActor.saved =
        widget.movieActor.saved == null ? false : widget.movieActor.saved;
    if (widget.movieActor.movieId != null) {
      var film = widget.movieOptions
          .singleWhere((a) => a.movieId == widget.movieActor.movieId);

      if (film != null) movieActorId = [film];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.open.value == true
        ? Container(
            child: Column(children: [
            SizedBox(
              height: 15,
            ),
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(240, 240, 240, 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ChipsInput(
                initialValue: movieActorId,
                maxChips: 1,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  var filteredList = movieActorsFilter.length != 0
                      ? widget.movieOptions
                          .where((r) => !movieActorsFilter.contains(r.movieId))
                          .toList()
                      : widget.movieOptions;
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();

                    return filteredList.where((item) {
                      return item.title
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return filteredList;
                },
                onChanged: (data) {
                  if (data.length != 0) {
                    setState(() {
                      widget.movieActor.movieId = data[0].movieId;
                      widget.movieActor.movieTitle = data[0].title;
                      showError = widget.movieActor.movieId != null &&
                              widget.movieActor.role != null &&
                              widget.movieActor.role.length != 0
                          ? false
                          : true;

                      movieActorId = [data[0]];
                      if (!movieActorsFilter.contains(data[0].movieId)) {
                        movieActorsFilter.add(data[0].movieId);
                      }
                    });
                  } else {
                    setState(() {
                      widget.movieActor.movieId = null;
                      widget.movieActor.movieTitle = null;
                      showError = widget.movieActor.movieId != null &&
                              widget.movieActor.role != null &&
                              widget.movieActor.role.length != 0
                          ? false
                          : true;
                      widget.movieActor.saved =
                          widget.movieActor.movieId != null &&
                                  widget.movieActor.role != null &&
                                  widget.movieActor.role.length != 0 &&
                                  widget.movieActor.saved == true
                              ? true
                              : false;
                      movieActorId = [];
                    });
                  }
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c != null ? c.title : ""),
                    onDeleted: () => {
                      setState(() {
                        movieActorsFilter.remove(c.movieId);
                      }),
                      state.deleteChip(c),
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.title),
                    onTap: () => {
                      if (!movieActorsFilter.contains(c.movieId))
                        {
                          setState(() {
                            movieActorsFilter.add(c.movieId);
                          })
                        },
                      state.selectSuggestion(c)
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Container(
              color: Color.fromRGBO(240, 240, 240, 1),
              child: TestChipsInput(
                initialValue: widget.movieActor.role != null
                    ? widget.movieActor.role
                    : [],
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  setState(() {
                    temp = query;
                  });
                  return [];
                },
                submittedText: temp != null ? temp.trimLeft().trimRight() : "",
                onChanged: (data) {
                  List<String> tempList = [];
                  tempList = data.map((role) => role.toString()).toList();

                  setState(() {
                    widget.movieActor.role = tempList;
                    showError = widget.movieActor.movieId != null &&
                            widget.movieActor.role != null &&
                            widget.movieActor.role.length != 0
                        ? false
                        : true;
                    widget.movieActor.saved =
                        widget.movieActor.movieId != null &&
                                widget.movieActor.role != null &&
                                widget.movieActor.role.length != 0 &&
                                widget.movieActor.saved == true
                            ? true
                            : false;
                  });
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c),
                    onDeleted: () => state.deleteChip(c),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return null;
                },
              ),
            ),
            SizedBox(height: 5),
            Text("Pindutin ang 'ENTER' para i-save ang role."),
            SizedBox(height: 15),
            showError == true
                ? Text('Required ang mga field ng Aktor at Role.',
                    style: TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic))
                : SizedBox(),
            showError == true ? SizedBox(height: 15) : SizedBox(),
            Container(
              child: OutlineButton(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                color: Colors.white,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (widget.movieActor.movieId != null &&
                      widget.movieActor.role.length != 0) {
                    setState(() {
                      // save to actors and roles list
                      widget.open.value = false;
                      widget.movieActor.saved = true;
                    });
                  } else {
                    setState(() {
                      widget.movieActor.saved = false;
                      showError = true;
                    });
                  }
                },
                child: Text('Save'),
              ),
              alignment: Alignment.center,
            )
          ]))
        :
        // display this instead if widget.open == false
        Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              tileColor: Color.fromRGBO(240, 240, 240, 1),
              title: Text(
                  (widget.movieActor != null
                      ? (widget.movieActor.movieTitle)
                      : ""),
                  softWrap: true,
                  overflow: TextOverflow.clip),
              subtitle: Text(
                widget.movieActor.role != null
                    ? widget.movieActor.role.join(", ")
                    : "",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              trailing: GestureDetector(
                child: Icon(Icons.edit),
                onTap: () {
                  setState(() {
                    widget.open.value = true;
                  });
                },
              ),
            ),
          );
  }
}
