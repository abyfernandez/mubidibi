import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/ui/widgets/award_widget.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';

// For Dynamic Widgets
List<int> actorsFilter = []; // actors

class AddMovie extends StatefulWidget {
  final Movie movie;
  final List<List<Crew>> crewEdit;

  AddMovie({Key key, this.movie, this.crewEdit}) : super(key: key);

  @override
  _AddMovieState createState() => _AddMovieState(movie, crewEdit);
}

// ADD MOVIE FIRST PAGE
class _AddMovieState extends State<AddMovie> {
  final Movie movie;
  final List<List<Crew>> crewEdit;

  _AddMovieState(this.movie, this.crewEdit);

  // Local State Variable/s
  bool _saving = false;
  int movieId;
  List<dynamic> genres = [];
  List<DropdownMenuItem> genreItems = [];
  var selectedValue;
  String test;
  List<ActorWidget> actorList = [];
  List<AwardWidget> awardList = [];

  // MOVIE FIELD CONTROLLERS
  DateTime _date;
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  final runtimeController = TextEditingController();
  final dateController = TextEditingController();
  final roleController = TextEditingController();
  final linesController = TextEditingController();

  // MOVIE FIELD FOCUSNODES
  final titleNode = FocusNode();
  final synopsisNode = FocusNode();
  final runtimeNode = FocusNode();
  final dateNode = FocusNode();
  final roleNode = FocusNode();
  final directorNode = FocusNode();
  final writerNode = FocusNode();
  final addActorNode = FocusNode();
  final linesNode = FocusNode();

  // MOVIE FORMKEYS
  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // OTHER VARIABLES
  var imageFiles =
      List(); // for uploading poster w/ image picker (multiple file)
  final picker = ImagePicker();
  String base64Image; // picked image in base64 format
  var screenshots = List(); // for uploading movie screenshots
  var imageURI = ''; // for movie edit
  List<Award> awardOptions;
  var currentUser;

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // LISTS
  List<String> filmGenres = []; // Genre(s) -- saved as strings
  List<int> directors = []; // Director(s)
  List<int> writers = []; // Writer(s)
  List<DropdownMenuItem> crewItems = [];
  List<Crew> crewList = [];
  List<ActorWidget> filteredActors = []; // dynamic list with only saved values
  List<AwardWidget> filteredAwards = []; // dynamic list with only saved values

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Mga Basic na Detalye",
    "Mga Poster, Screenshot, at Ibang Media",
    "Mga Personalidad",
    "Mga Award",
    "Mga Sikat na Linya",
    "Review"
  ];

  // Function: FETCH GENRES
  List<String> genreFromJson(String str) =>
      List<String>.from(json.decode(str).map((x) => x['genre']));

  // fetch genre from API
  void fetchGenres() async {
    final response = await http.get(Config.api + 'genres/');

    if (response.statusCode == 200) {
      // map json to Genre type
      genres = genreFromJson(response.body);
    }
    genreItems = genres.map<DropdownMenuItem<String>>((dynamic value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
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
        actorsFilter = []; // clears list para pag binalikan sya empty na ulit
      });
      await _navigationService.pop();
    }
    return Future.value(false);
  }

  // Function: calls viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();

    crewList = await model.getAllCrew(mode: "form");
    // converts from List<Crew> to List<DropdownMenuItem>
    crewItems = crewList.map<DropdownMenuItem<dynamic>>((Crew value) {
      String name = value.firstName +
          (value.middleName != null ? " " + value.middleName : "") +
          (value.lastName != null ? " " + value.lastName : "") +
          (value.suffix != null ? " " + value.suffix : "");
      return DropdownMenuItem<dynamic>(
        key: ValueKey(value.crewId),
        value: name,
        child: Text(name),
      );
    }).toList();
  }

  // Function: Shows datepicker and update value of Date
  Future<Null> _selectDate(BuildContext context) async {
    DateTime _datePicker = await showDatePicker(
        context: context,
        initialDate: _date == null ? DateTime.now() : _date,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return child;
        });

    if (_datePicker != null && _datePicker != _date) {
      setState(() {
        _date = _datePicker;
        dateController.text = DateFormat("MMM. d, y").format(_date) ?? '';
      });
    }
  }

  // Function: get image using image picker for movie poster
  Future getImage() async {
    // File Picker ver. 3 (multiple files)
    FilePickerResult result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png']);

    if (result != null) {
      List imagePaths = imageFiles.isNotEmpty
          ? imageFiles.map((img) => img.path).toList()
          : [];

      List toUpload = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        }
      }).toList();

      if (toUpload.isNotEmpty) {
        setState(() {
          for (var i = 0; i < toUpload.length; i++) {
            if (toUpload[i] != null) {
              imageFiles.add(toUpload[i]);
            }
          }
        });
      }
    } else {
      // User canceled the picker
      print('No image selected.');
    }
  }

  // Function: get images using image picker for movie screenshots
  Future getScreenshot() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png']);

    if (result != null) {
      List imagePaths = screenshots.isNotEmpty
          ? screenshots.map((img) => img.path).toList()
          : [];

      List toUpload = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        }
      }).toList();

      if (toUpload.isNotEmpty) {
        setState(() {
          for (var i = 0; i < toUpload.length; i++) {
            if (toUpload[i] != null) {
              screenshots.add(toUpload[i]);
            }
          }
        });
      }
    } else {
      // User canceled the picker
      print('No image selected.');
    }
  }

  // Function: display screenshots in a scrollable horizontal view
  Widget displayScreenshots(String mode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: screenshots
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
                              screenshots.remove(pic);
                            });
                          },
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(0.0, 0.0),
                              blurRadius: 0.0,
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

  // Function: display posters in a scrollable horizontal view
  Widget displayPosters(String mode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageFiles
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
                              imageFiles.remove(pic);
                            });
                          },
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white,
                              offset: Offset(0.0, 0.0),
                              blurRadius: 0.0,
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

  // Function: Display Actors in the Review Step
  Widget displayActors() {
    filteredActors =
        actorList.where((actor) => actor.crew.saved == true).toList();

    return Column(
      children: [
        filteredActors.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredActors.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Aktor: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        // TO DO: fix overflow issue when text is too long
        filteredActors.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredActors.map((actor) {
                    if (actor.crew.saved == true) {
                      var item = crewList
                          .firstWhere((p) => p.crewId == actor.crew.crewId);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          new Icon(Icons.fiber_manual_record, size: 16),
                          SizedBox(
                            width: 5,
                          ),
                          new Flexible(
                            child: Text(item.name,
                                // item.firstName +
                                //     (item.middleName != null
                                //         ? " " + item.middleName
                                //         : "") +
                                //     (item.lastName != null
                                //         ? " " + item.lastName
                                //         : "") +
                                //     (item.suffix != null
                                //         ? " " + item.suffix
                                //         : ""),
                                style: TextStyle(fontSize: 16),
                                softWrap: true,
                                overflow: TextOverflow.clip),
                          ),
                          actor.crew.role.length != 0
                              ? Text(" - " + actor.crew.role.join(" / "),
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

  // Function: adds ActorWidget in the ListView builder
  addActor() {
    FocusScope.of(context).unfocus();
    setState(() {
      // add actor widget to list
      actorList.add(ActorWidget(
        crew: new Crew(),
        crewList: crewList,
        open: ValueNotifier<bool>(true),
      ));
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

  // Function: adds AwardWidget in the ListView builder
  addAward() {
    setState(() {
      awardList.add(AwardWidget(
        awardOptions: awardOptions,
        item: new Award(),
        open: ValueNotifier<bool>(true),
      ));
    });
  }

  void fetchAwards() async {
    var model = AwardViewModel();
    awardOptions = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'movie');
  }

  @override
  void initState() {
    currentUser = _authenticationService.currentUser;
    fetchCrew();
    fetchAwards();
    fetchGenres();
    directors = [];
    writers = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;

    final _scaffoldKey = GlobalKey<ScaffoldState>();
    // TO DO: add awards in stepper
    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      onModelReady: (model) async {
        movieId = movie?.movieId ?? 0;

        // update controller's text field
        titleController.text = movie?.title ?? '';
        _date = movie?.releaseDate != null
            ? DateTime.parse(movie?.releaseDate)
            : null;
        synopsisController.text = movie?.synopsis ?? '';
        runtimeController.text = movie?.runtime?.toString() ?? '';

        // TO DO: IMAGE EDIT
        imageURI = movie?.poster ?? '';

        // CREW
        directors = crewEdit != null
            ? crewEdit.isNotEmpty
                ? crewEdit[0].map((d) => d.crewId).toList()
                : []
            : [];
        writers = crewEdit != null
            ? crewEdit.isNotEmpty
                ? crewEdit[1].map((e) => e.crewId).toList()
                : []
            : [];
        // TO DO: ACTORS FIELD
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
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
                  actorsFilter = [];
                });
                await _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Magdagdag ng Pelikula",
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
                          children: [
                            SizedBox(height: 20),
                            MyStepper(
                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons
                                    .image, // Mga Poster, Screenshot, at iba pang Media
                                Icons.recent_actors, // Mga Personalidad
                                Icons.emoji_events_outlined, // Mga Award
                                Icons
                                    .format_quote_outlined, // Mga Sikat na Linya
                                Icons.grading // Review
                              ],
                              type: MyStepperType.vertical,
                              currentStep: currentStep,
                              onStepTapped: (step) async {
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
                              onStepCancel: () => {
                                if (currentStep != 0)
                                  setState(() => --currentStep)
                              }, // else do nothing
                              onStepContinue: () async {
                                if (currentStep + 1 != stepperTitle.length) {
                                  // do not allow user to continue to next step if inputs aren't filled out yet
                                  switch (currentStep) {
                                    case 0: // Mga Basic na Detalye
                                      setState(() {
                                        if (_formKeys[currentStep]
                                            .currentState
                                            .validate()) {
                                          titleNode.unfocus();
                                          dateNode.unfocus();
                                          runtimeNode.unfocus();
                                          synopsisNode.unfocus();

                                          currentStep++;
                                        }
                                      });
                                      break;

                                    case 1: // Mga Poster, Screenshot at iba pang Media
                                      setState(() {
                                        currentStep++;
                                      });
                                      break;
                                    case 2: // Mga Personalidad
                                      setState(() {
                                        directorNode.unfocus();
                                        writerNode.unfocus();
                                        // TO DO: unfocus keyboard when an actor/role textfield is currently active
                                        currentStep++;
                                      });
                                      break;
                                    case 3: // Mga Award
                                      // TO DO: unfocus keyboard when a genre textfield is currently active
                                      setState(() => currentStep++);
                                      break;
                                    case 4: // Mga Sikat na Linya
                                      // TO DO: unfocus keyboard when a genre textfield is currently active
                                      setState(() => currentStep++);
                                      break;
                                  }
                                } else {
                                  // Review
                                  // last step
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

                                    // loop through the awards and actors widgets to

                                    // actors
                                    List<Crew> actorsToSave = [];
                                    if (filteredActors.isNotEmpty) {
                                      actorsToSave = filteredActors
                                          .map((a) => a.crew)
                                          .toList();
                                    }

                                    // awards
                                    List<Award> awardsToSave = [];
                                    if (filteredAwards.isNotEmpty) {
                                      awardsToSave = filteredAwards
                                          .map((a) => a.item)
                                          .toList();
                                    }

                                    final response = await model.addMovie(
                                        title: titleController.text,
                                        synopsis: synopsisController.text,
                                        releaseDate: _date != null
                                            ? _date.toIso8601String()
                                            : '',
                                        runtime: runtimeController.text,
                                        posters: imageFiles,
                                        // imageURI: imageURI, // poster edit???
                                        screenshots: screenshots,
                                        genre: filmGenres,
                                        directors: directors,
                                        writers: writers,
                                        // TO DO: add actors, roles, awards, and famous lines here
                                        actors: actorsToSave,
                                        awards: awardsToSave,
                                        addedBy: currentUser.userId,
                                        movieId: movieId);

                                    // when response is returned, stop showing circular progress indicator
                                    if (response != 0) {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show success snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Movie added successfully.',
                                              Colors.green));

                                      _saving =
                                          true; // set saving to true to trigger circular progress indicator

                                      // get movie using id redirect to detail view using response
                                      var movie = await model.getOneMovie(
                                          movieId: response.toString());

                                      if (movie != null) {
                                        _saving =
                                            false; // set saving to false to trigger circular progress indicator
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MovieView(
                                                  movieId:
                                                      movie.movieId.toString()),
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
      case 0: // Mga Basic na Detalye
        return Container(
          child: Column(
            children: [
              SizedBox(height: 15),
              // MOVIE TITLE
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  autofocus: true,
                  focusNode: titleNode,
                  textCapitalization: TextCapitalization.words,
                  controller: titleController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    dateNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Pamagat *",
                    contentPadding: EdgeInsets.all(10),
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
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: Stack(
                  children: [
                    TextFormField(
                      readOnly: true,
                      focusNode: dateNode,
                      controller: dateController,
                      keyboardType: TextInputType.datetime,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onTap: () {
                        _selectDate(context);
                      },
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Petsa ng Paglabas",
                        contentPadding: EdgeInsets.all(10),
                      ),
                      onFieldSubmitted: (val) {
                        runtimeNode.requestFocus();
                      },
                    ),
                    _date != null
                        ? PositionedDirectional(
                            top: 10,
                            end: 10,
                            bottom: 10,
                            child: GestureDetector(
                              child: Icon(Icons.close_outlined,
                                  color: Color.fromRGBO(150, 150, 150, 1)),
                              onTap: () {
                                setState(() {
                                  _date = null;
                                  dateController.text = "";
                                });
                              },
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // RUNTIME
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: TextFormField(
                    focusNode: runtimeNode,
                    controller: runtimeController,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: "Runtime (minuto)",
                      contentPadding: EdgeInsets.all(10),
                    ),
                    onFieldSubmitted: (val) {
                      synopsisNode.requestFocus();
                    }),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: synopsisNode,
                  controller: synopsisController,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Buod *",
                    contentPadding: EdgeInsets.all(10),
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
              Container(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(240, 240, 240, 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TestChipsInput(
                              textCapitalization: TextCapitalization.words,
                              enabled: true,
                              textStyle: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: 'Pumili ng genre',
                                contentPadding: EdgeInsets.all(10),
                              ),
                              findSuggestions: (String query) {
                                setState(() {
                                  test = query;
                                });
                                if (query.isNotEmpty) {
                                  var lowercaseQuery = query.toLowerCase();
                                  return genres.where((item) {
                                    return item
                                        .toLowerCase()
                                        .contains(query.toLowerCase());
                                  }).toList(growable: false)
                                    ..sort((a, b) => a
                                        .toLowerCase()
                                        .indexOf(lowercaseQuery)
                                        .compareTo(b
                                            .toLowerCase()
                                            .indexOf(lowercaseQuery)));
                                }
                                return genres;
                              },
                              submittedText: test != null
                                  ? test.trimLeft().trimRight()
                                  : "",
                              onChanged: (data) {
                                List<String> categories = data.length != 0
                                    ? data
                                        .map((item) => item.toString().trim())
                                        .toList()
                                    : [];
                                setState(() {
                                  filmGenres = categories;
                                });
                              },
                              chipBuilder: (context, state, c) {
                                return InputChip(
                                  key: ObjectKey(c),
                                  label: Text(c),
                                  onDeleted: () => state.deleteChip(c),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              },
                              suggestionBuilder: (context, state, c) {
                                return ListTile(
                                  key: ObjectKey(c),
                                  title: Text(c),
                                  onTap: () => state.selectSuggestion(c),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                        "Pindutin ang 'ENTER' para magdagdag ng genre na wala sa listahan."),
                  ],
                ),
              ),
            ],
          ),
        );
      case 1: // Mga Poster, Screenshot, at iba pang Media
        return Container(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text('Mga Poster',
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
                              child: Icon(Icons.camera_alt),
                              onTap: getImage,
                            ),
                            width: 70,
                            height: 70,
                            color: Color.fromRGBO(240, 240, 240, 1)),
                        imageFiles.length != 0
                            ? displayPosters("edit")
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Text('Mga Screenshot',
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
                              onTap: getScreenshot,
                            ),
                            width: 70,
                            height: 70,
                            color: Color.fromRGBO(240, 240, 240, 1)),
                        screenshots.length != 0
                            ? displayScreenshots("edit")
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 2: // Mga Personalidad
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text('Mga Direktor:',
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
                  initialValue: directors,
                  focusNode: directorNode,
                  nextFocusNode: writerNode,
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Pumili ng direktor',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  findSuggestions: (String query) {
                    if (query.isNotEmpty) {
                      var lowercaseQuery = query.toLowerCase();
                      return crewList.where((item) {
                        var fullName = item.firstName +
                            (item.middleName != null
                                ? " " + item.middleName
                                : "") +
                            (item.lastName != null ? " " + item.lastName : "") +
                            (item.suffix != null ? " " + item.suffix : "");
                        return fullName
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.firstName
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(b.firstName
                                .toLowerCase()
                                .indexOf(lowercaseQuery)));
                    }
                    return crewList;
                  },
                  onChanged: (data) {
                    List<int> ids = [];
                    for (var c in data) {
                      ids.add(c.crewId);
                    }
                    directors = ids;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.firstName +
                          (c.middleName != null ? " " + c.middleName : "") +
                          (c.lastName != null ? " " + c.lastName : "") +
                          (c.suffix != null ? " " + c.suffix : "")),
                      onDeleted: () => state.deleteChip(c),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.firstName +
                          (c.middleName != null ? " " + c.middleName : "") +
                          (c.lastName != null ? " " + c.lastName : "") +
                          (c.suffix != null ? " " + c.suffix : "")),
                      onTap: () => state.selectSuggestion(c),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Text('Mga Manunulat:',
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
                  initialValue: writers,
                  focusNode: writerNode,
                  nextFocusNode: addActorNode,
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Pumili ng manunulat',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  findSuggestions: (String query) {
                    if (query.isNotEmpty) {
                      var lowercaseQuery = query.toLowerCase();
                      return crewList.where((item) {
                        var fullName = item.firstName +
                            (item.middleName != null
                                ? " " + item.middleName
                                : "") +
                            (item.lastName != null ? " " + item.lastName : "") +
                            (item.suffix != null ? " " + item.suffix : "");
                        return fullName
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.firstName
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(b.firstName
                                .toLowerCase()
                                .indexOf(lowercaseQuery)));
                    }
                    return crewList;
                  },
                  onChanged: (data) {
                    List<int> ids = [];
                    for (var c in data) {
                      ids.add(c.crewId);
                    }
                    writers = ids;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.firstName +
                          (c.middleName != null ? " " + c.middleName : "") +
                          (c.lastName != null ? " " + c.lastName : "") +
                          (c.suffix != null ? " " + c.suffix : "")),
                      onDeleted: () => state.deleteChip(c),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.firstName +
                          (c.middleName != null ? " " + c.middleName : "") +
                          (c.lastName != null ? " " + c.lastName : "") +
                          (c.suffix != null ? " " + c.suffix : "")),
                      onTap: () => state.selectSuggestion(c),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mga Aktor:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: 140,
                child: actorList.isEmpty
                    ? FlatButton(
                        focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addActor,
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
                  itemCount: actorList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: actorList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              actorList[i],
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
                                              if (actorList[i].crew.crewId !=
                                                  null) {
                                                actorsFilter.remove(
                                                    actorList[i].crew.crewId);
                                              }
                                              actorList.removeAt(i);
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
                child: actorList.isNotEmpty
                    ? FlatButton(
                        focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addActor,
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
            ],
          ),
        );
      case 3: // Mga Award
        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SizedBox(height: 10),
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
            ],
          ),
        );
      case 4: // Mga Sikat na Linya
        // TO DO: dynamic widget ???
        return Container(
            child: Column(
          children: [
            SizedBox(
              height: 15,
            ),
            Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: TextFormField(
                focusNode: linesNode,
                controller: linesController,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Colors.black,
                ),
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Mga Sikat na Linya",
                  contentPadding: EdgeInsets.all(10),
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),
          ],
        ));
      case 5: // Review
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
                    child: Text("Pamagat: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      titleController.text,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.clip,
                      softWrap: true,
                    ),
                  ),
                  _date != null ? SizedBox(height: 10) : SizedBox(),
                  _date != null
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Petsa ng Paglabas: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  _date != null
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            _date == null
                                ? ''
                                : DateFormat("MMM. d, y").format(_date),
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        )
                      : SizedBox(),
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Buod: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      synopsisController.text,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  imageFiles.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                  imageFiles.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Mga Poster: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  imageFiles.isNotEmpty
                      ? displayPosters("display")
                      : SizedBox(),
                  screenshots.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                  screenshots.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Mga Screenshot: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  screenshots.isNotEmpty
                      ? displayScreenshots("display")
                      : SizedBox(),
                  directors.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                  directors.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Mga Direktor: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  directors.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                              children: directors.map<Widget>((id) {
                            var direk = crewList
                                .firstWhere((item) => item.crewId == id);
                            return new Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                new Icon(Icons.fiber_manual_record, size: 16),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    direk.name,
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
                  writers.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                  writers.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Mga Manunulat: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  writers.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                              children: writers.map<Widget>((id) {
                            var writer = crewList
                                .firstWhere((item) => item.crewId == id);
                            return new Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                new Icon(Icons.fiber_manual_record, size: 16),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    writer.name,
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
                  displayActors(),
                  filmGenres.length != 0 ? SizedBox(height: 10) : SizedBox(),
                  filmGenres.length != 0
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Mga Genre: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        )
                      : SizedBox(),
                  filmGenres.length != 0
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                              children: filmGenres
                                  .map<Widget>((str) => Container(
                                        margin: EdgeInsets.only(right: 3),
                                        child: Chip(
                                          label: Text(str),
                                          backgroundColor: Colors.blue[100],
                                        ),
                                      ))
                                  .toList()),
                        )
                      : SizedBox(),
                  displayAwards(),
                ],
              ),
            ),
          ),
        );
    }
    return null;
  }
}

// Dynamic ActorWidget (Adding Actors and their respective roles)

class ActorWidget extends StatefulWidget {
  final List<Crew> crewList;
  final Crew crew;
  final open;

  const ActorWidget({
    Key key,
    this.crew,
    this.crewList,
    this.open,
  }) : super(key: key);

  @override
  ActorWidgetState createState() => ActorWidgetState();
}

class ActorWidgetState extends State<ActorWidget> {
  var temp;
  Crew tempActor;
  List<String> tempRoles;
  bool showError = true;
  List<Crew> actorId = [];

  @override
  void initState() {
    widget.crew.saved = widget.crew.saved == null ? false : widget.crew.saved;
    if (widget.crew.crewId != null) {
      var actor =
          widget.crewList.singleWhere((a) => a.crewId == widget.crew.crewId);

      if (actor != null) actorId = [actor];
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
                initialValue: actorId,
                maxChips: 1,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng aktor',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  var filteredList = actorsFilter.length != 0
                      ? widget.crewList
                          .where((r) => !actorsFilter.contains(r.crewId))
                          .toList()
                      : widget.crewList;
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();

                    return filteredList.where((item) {
                      return item.name
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.name
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.name.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return filteredList;
                  // return widget.crewList;
                },
                onChanged: (data) {
                  if (data.length != 0) {
                    setState(() {
                      widget.crew.crewId = data[0].crewId;
                      widget.crew.firstName = data[0].firstName;
                      widget.crew.middleName = data[0].middleName;
                      widget.crew.lastName = data[0].lastName;
                      widget.crew.suffix = data[0].suffix;
                      showError = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0
                          ? false
                          : true;
                      actorId = [data[0]];
                      if (!actorsFilter.contains(data[0].crewId)) {
                        actorsFilter.add(data[0].crewId);
                      }
                    });
                  } else {
                    setState(() {
                      widget.crew.crewId = null;
                      widget.crew.firstName = null;
                      widget.crew.middleName = null;
                      widget.crew.lastName = null;
                      widget.crew.suffix = null;
                      showError = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0
                          ? false
                          : true;
                      widget.crew.saved = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0 &&
                              widget.crew.saved == true
                          ? true
                          : false;
                      actorId = [];
                    });
                  }
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c != null ? c.name : ""),
                    onDeleted: () => {
                      setState(() {
                        actorsFilter.remove(c.crewId);
                      }),
                      state.deleteChip(c),
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.name),
                    onTap: () => {
                      if (!actorsFilter.contains(c.crewId))
                        {
                          setState(() {
                            actorsFilter.add(c.crewId);
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
                initialValue: widget.crew.role != null ? widget.crew.role : [],
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
                    widget.crew.role = tempList;
                    showError = widget.crew.crewId != null &&
                            widget.crew.role != null &&
                            widget.crew.role.length != 0
                        ? false
                        : true;
                    widget.crew.saved = widget.crew.crewId != null &&
                            widget.crew.role != null &&
                            widget.crew.role.length != 0 &&
                            widget.crew.saved == true
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
                  if (widget.crew.crewId != null && widget.crew.role != null) {
                    setState(() {
                      // save to actors and roles list
                      widget.open.value = false;
                      widget.crew.saved = true;
                    });
                  } else {
                    setState(() {
                      widget.crew.saved = false;
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
                  (widget.crew != null
                      ? (widget.crew.firstName +
                          (widget.crew.middleName != null
                              ? " " + widget.crew.middleName
                              : "") +
                          (widget.crew.lastName != null
                              ? " " + widget.crew.lastName
                              : "") +
                          (widget.crew.suffix != null
                              ? " " + widget.crew.suffix
                              : ""))
                      : ""),
                  softWrap: true,
                  overflow: TextOverflow.clip),
              subtitle: Text(
                widget.crew.role != null ? widget.crew.role.join(", ") : "",
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
