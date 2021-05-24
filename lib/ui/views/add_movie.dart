import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
// import 'package:mubidibi/ui/widgets/searchable_dropdown.dart';
// import 'package:flutter_chips_input/flutter_chips_input.dart'; -- working widget
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
// import 'package:mubidibi/ui/widgets/chips_input.dart'; // test -- for roles and possibly genres
import 'package:mubidibi/ui/widgets/input_chips.dart'; // test -- should be working
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
// import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter_document_picker/flutter_document_picker.dart';

// FOR DYNAMIC WIDGET ACTOR
List<ActorWidget> dynamicList = [];
List<int> actors = [];
List<List<String>> roles = [];
var size;
List<bool> opened = []; // state values of actors in listview

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

  // MOVIE FIELD CONTROLLERS
  DateTime _date;
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  final runtimeController = TextEditingController();
  final dateController = TextEditingController();
  final roleController = TextEditingController();

  // MOVIE FIELD FOCUSNODES
  final titleNode = FocusNode();
  final synopsisNode = FocusNode();
  final runtimeNode = FocusNode();
  final dateNode = FocusNode();
  final roleNode = FocusNode();
  final directorNode = FocusNode();
  final writerNode = FocusNode();
  final addActorNode = FocusNode();

  // MOVIE FORMKEYS
  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // OTHER VARIABLES
  File imageFile; // for uploading poster w/ image picker
  final picker = ImagePicker();
  var mimetype;
  String base64Image; // picked image in base64 format
  var screenshots = List(); // for uploading movie screenshots
  var imageURI = ''; // for movie edit

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

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Basic Details",
    "Poster and Screenshots",
    "Crew Member/s",
    "Genre/s",
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

  // Function: calls viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();

    crewList = await model.getAllCrew();
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

  // Function: (TO DO: MIGHT GET DEPRECATED) gets the id of the crew using the list of indices provided by the Director(s)/Writer(s) select fields.
  List<int> crewIds(List<int> indices) {
    List<int> crewIds = [];
    for (var i in indices) {
      for (var j = 0; j < crewList.length; j++) {
        if (i == crewList[j].crewId) {
          crewIds.add(crewList[j].crewId);
        }
      }
    }
    return crewIds;
  }

  // FUNCTION: (TO DO: IS THIS NEEDED???) the genre array passed from the detail view is in string and named form, not as indices of the genres itself so we have to convert it first
  List<int> genreIndices(List<dynamic> genresFromDetail) {
    List<int> genreIndices = [];
    for (var item in genresFromDetail) {
      for (var i = 0; i < movie.genre.length; i++) {
        if (item == movie.genre[i]) {
          genreIndices.add(i);
        }
      }
    }
    return genreIndices;
  }

  // Function: get image using image picker for movie poster
  Future getImage() async {
    // final pickedFile = await picker.getImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   imageFile = File(pickedFile.path);
    //   setState(() {
    //     imageFile = imageFile;
    //     mimetype = lookupMimeType(pickedFile.path);
    //   });
    // } else {
    //   print('No image selected.');
    // }

    // // File Picker ver. 2
    // FlutterDocumentPickerParams params = FlutterDocumentPickerParams(
    //   allowedFileExtensions: ['jpg', 'jpeg', 'png'],
    // );

    // final path = await FlutterDocumentPicker.openDocument(params: params);
    // if (path != null) {
    //   imageFile = File(path);
    //   setState(() {
    //     imageFile = imageFile;
    //     mimetype = lookupMimeType(path);
    //   });
    // } else {
    //   print('No image selected.');
    // }

    // File Picker ver. 3
    FilePickerResult result = await FilePicker.platform.pickFiles();

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
  Future getScreenshot() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      var image = File(pickedFile.path);
      setState(() {
        screenshots.add(image);
      });
    } else {
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

  // Function: adds ActorWidget in the ListView builder
  addActor() {
    setState(() {
      size = dynamicList.length; // pass the index of the widget to the class

      // insert empty data to roles list
      roles.add([]);

      // add actor wdiget to list
      dynamicList.add(ActorWidget(
          key: ObjectKey(size),
          crewItems: crewItems,
          crewList: crewList,
          size: size));
      opened.add(
          true); // when an actor widget is added, it defaults to an open/editable widget
    });
  }

  @override
  void initState() {
    fetchCrew();
    fetchGenres();
    actors = [];
    directors = [];
    writers = [];
    roles = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;

    final _scaffoldKey = GlobalKey<ScaffoldState>();
    // TO DO: add crew (redirect to add crew form) and then go back to add movie form
    // TO DO: check if poster and screenshots are actually saved in cloudinary
    // TO DO: add awards in stepper
    // TO DO: Check the &&  and || conditions if they're correct
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
                _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Magdagdag ng Pelikula",
            style: TextStyle(color: Colors.black),
          ),
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
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        MyStepper(
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
                            if (currentStep != 0) setState(() => --currentStep)
                          }, // else do nothing
                          onStepContinue: () async {
                            if (currentStep + 1 != stepperTitle.length) {
                              // do not allow user to continue to next step if inputs aren't filled out yet
                              switch (currentStep) {
                                case 0: // title, release date, running time, and synopsis
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

                                case 1: // poster
                                  setState(() {
                                    currentStep++;
                                  });
                                  break;
                                case 2: // crew members
                                  setState(() {
                                    directorNode.unfocus();
                                    writerNode.unfocus();
                                    // TO DO: unfocus keyboard when an actor/role textfield is currently active
                                    currentStep++;
                                  });
                                  break;
                                case 3: // genre
                                  // TO DO: unfocus keyboard when a genre textfield is currently active
                                  setState(() => currentStep++);
                                  break;
                              }
                            } else {
                              // last step
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

                                final response = await model.addMovie(
                                    title: titleController.text,
                                    synopsis: synopsisController.text,
                                    releaseDate: _date != null
                                        ? _date.toIso8601String()
                                        : '',
                                    runtime: runtimeController.text,
                                    poster: imageFile,
                                    imageURI: imageURI,
                                    screenshots: screenshots,
                                    mimetype: mimetype,
                                    genre: filmGenres,
                                    directors: directors,
                                    writers: writers,
                                    actors: actors,
                                    roles: roles,
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MovieView(
                                            movieId: movie.movieId.toString()),
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
      case 0:
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
                  maxLines: null, // 5
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
            ],
          ),
        );
      case 1:
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
              SizedBox(
                height: 15,
              ),
              Text('Mga Screenshot',
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
            ],
          ),
        );
      case 2:
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
              // Container(
              //   decoration: BoxDecoration(
              //     color: Color.fromRGBO(240, 240, 240, 1),
              //     borderRadius: BorderRadius.circular(5),
              //   ),
              //   child: Column(
              //     children: <Widget>[
              //       CSearchableDropdown.multiple(
              //         selectedValueWidgetFn: (item) => Container(
              //           margin: EdgeInsets.only(right: 5),
              //           child: InputChip(
              //             label: Text(
              //               item,
              //               style: TextStyle(
              //                 fontSize: 12,
              //               ),
              //             ),
              //             backgroundColor: Color.fromRGBO(220, 220, 220, 1),
              //             deleteIconColor: Colors.black,
              //             onPressed: () {},
              //             onDeleted: () {
              //               setState(() {
              //                 var index = crewItems.indexWhere(
              //                     (director) => director.value == item);
              //                 directors.removeWhere((item) => item == index);
              //               });
              //             },
              //           ),
              //         ),
              //         key: UniqueKey(),
              //         style: TextStyle(
              //           color: Colors.black,
              //         ),
              //         underline: Container(),
              //         items: crewItems,
              //         selectedItems: directors,
              //         hint: Padding(
              //           padding: const EdgeInsets.all(12.0),
              //           child: Text("Pumili ng direktor",
              //               style: TextStyle(
              //                   color: Colors.black54,
              //                   fontSize: 16,
              //                   fontFamily: 'Poppins')),
              //         ),
              //         searchHint: Text("Search Any",
              //             style: TextStyle(color: Colors.white)),
              //         onChanged: (value) {
              //           setState(() {
              //             directors = value;
              //           });
              //         },
              //         closeButton: (directors) {
              //           return (directors.isNotEmpty
              //               ? "Save ${directors.length == 1 ? '"' + crewItems[directors.first].value.toString() + '"' : '(' + directors.length.toString() + ')'}"
              //               : "Save without selection");
              //         },
              //         isExpanded: true,
              //       ),
              //     ],
              //   ),
              // ),

              // TO DO: (Note: When this widget is used instead of CSearchableDropdown, there is no need to convert the ids. CrewItems is also not necessary)
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
                        // return item.firstName
                        //         .toLowerCase()
                        //         .contains(query.toLowerCase()) ||
                        //     item.lastName
                        //         .toLowerCase()
                        //         .contains(query.toLowerCase());
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
              // Container(
              //   decoration: BoxDecoration(
              //     color: Color.fromRGBO(240, 240, 240, 1),
              //     borderRadius: BorderRadius.circular(5),
              //   ),
              //   child: Column(
              //     children: <Widget>[
              //       CSearchableDropdown.multiple(
              //         selectedValueWidgetFn: (item) => Container(
              //           margin: EdgeInsets.only(right: 5),
              //           child: InputChip(
              //             label: Text(
              //               item,
              //               style: TextStyle(
              //                 fontSize: 12,
              //               ),
              //             ),
              //             backgroundColor: Color.fromRGBO(220, 220, 220, 1),
              //             deleteIconColor: Colors.black,
              //             padding: EdgeInsets.all(0),
              //             onPressed: () {},
              //             onDeleted: () {
              //               setState(() {
              //                 var index = crewItems
              //                     .indexWhere((writer) => writer.value == item);
              //                 writers.removeWhere((item) => item == index);
              //               });
              //             },
              //           ),
              //         ),
              //         key: UniqueKey(),
              //         style: TextStyle(
              //           color: Colors.black,
              //         ),
              //         underline: Container(),
              //         items: crewItems,
              //         selectedItems: writers,
              //         hint: Padding(
              //           padding: const EdgeInsets.all(12.0),
              //           child: Text("Pumili ng manunulat",
              //               style: TextStyle(
              //                   color: Colors.black54,
              //                   fontSize: 16,
              //                   fontFamily: 'Poppins')),
              //         ),
              //         searchHint: Text("Search Any",
              //             style: TextStyle(color: Colors.white)),
              //         onChanged: (value) {
              //           setState(() {
              //             writers = value;
              //           });
              //         },
              //         closeButton: (writers) {
              //           return (writers.isNotEmpty
              //               ? "Save ${writers.length == 1 ? '"' + crewItems[writers.first].value.toString() + '"' : '(' + writers.length.toString() + ')'}"
              //               : "Save without selection");
              //         },
              //         isExpanded: true,
              //       ),
              //     ],
              //   ),
              // ),

              // TO DO: (Note: When this widget is used instead of CSearchableDropdown, there is no need to convert the ids. CrewItems is also not necessary)
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
              Container(
                width: 140,
                child: dynamicList.isEmpty
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
              Column(
                children: [
                  ListView(
                    shrinkWrap: true,
                    children: dynamicList
                        .map((item) => Column(
                              key: ObjectKey(item),
                              children: [
                                item,
                                Container(
                                  alignment: Alignment.centerRight,
                                  child: FlatButton(
                                    color: Color.fromRGBO(240, 240, 240, 1),
                                    child: Text("Remove"),
                                    onPressed: () {
                                      setState(() {
                                        // remove from actors and roles lists
                                        actors.removeAt(
                                            dynamicList.indexOf(item));
                                        roles.removeAt(
                                            dynamicList.indexOf(item));
                                        dynamicList.removeAt(
                                            dynamicList.indexOf(item));
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Divider(height: 1, thickness: 2),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ),

              SizedBox(
                height: 10,
              ),
              Container(
                width: 140,
                child: dynamicList.isNotEmpty
                    ? FlatButton(
                        focusNode: addActorNode,
                        color: Color.fromRGBO(192, 192, 192, 1),
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
              Divider(height: 1, thickness: 2),
            ],
          ),
        );
      case 3:
        return Container(
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
                                  .compareTo(
                                      b.toLowerCase().indexOf(lowercaseQuery)));
                          }
                          return genres;
                        },
                        submittedText:
                            test != null ? test.trimLeft().trimRight() : "",
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
              Text("Pindutin ang 'ENTER' para magdagdag ng genre."),
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
                  imageFile != null ? SizedBox(height: 10) : SizedBox(),
                  imageFile != null
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Text("Poster/s: ",
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
                              children: [
                                new Icon(Icons.fiber_manual_record, size: 16),
                                SizedBox(
                                  width: 5,
                                ),
                                new Text(
                                  direk.firstName +
                                      (direk.middleName != null
                                          ? " " + direk.middleName
                                          : "") +
                                      (direk.lastName != null
                                          ? " " + direk.lastName
                                          : "") +
                                      (direk.suffix != null
                                          ? " " + direk.suffix
                                          : ""),
                                  style: TextStyle(fontSize: 16),
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
                              children: [
                                new Icon(Icons.fiber_manual_record, size: 16),
                                SizedBox(
                                  width: 5,
                                ),
                                new Text(
                                  writer.firstName +
                                      (writer.middleName != null
                                          ? " " + writer.middleName
                                          : "") +
                                      (writer.lastName != null
                                          ? " " + writer.lastName
                                          : "") +
                                      (writer.suffix != null
                                          ? " " + writer.suffix
                                          : ""),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          }).toList()),
                        )
                      : SizedBox(),
                  actors.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                  // TO DO: Display actors
                  actors.isNotEmpty
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
                  actors.isNotEmpty
                      ? Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                            children: actors.map((id) {
                              var item =
                                  crewList.firstWhere((p) => p.crewId == id);
                              return new Wrap(
                                children: [
                                  new Icon(Icons.fiber_manual_record, size: 16),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  new Text(
                                      item.firstName +
                                          (item.middleName != null
                                              ? " " + item.middleName
                                              : "") +
                                          (item.lastName != null
                                              ? " " + item.lastName
                                              : "") +
                                          (item.suffix != null
                                              ? " " + item.suffix
                                              : ""),
                                      style: TextStyle(fontSize: 16),
                                      softWrap: true,
                                      overflow: TextOverflow.fade),
                                  roles[actors.indexOf(id)].length != 0
                                      ? Text(
                                          " - " +
                                              roles[actors.indexOf(id)]
                                                  .join(" / "),
                                          style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 16),
                                          softWrap: true,
                                          overflow: TextOverflow.fade)
                                      : SizedBox(),
                                ],
                              );
                            }).toList(),
                          ),
                        )
                      : SizedBox(),
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
                ],
              ),
            ),
          ),
        );
    }
    return null;
  }
}

// Dynamic Widget (Adding Actors and their respective roles)

class ActorWidget extends StatefulWidget {
  final List<DropdownMenuItem> crewItems;
  final List<Crew> crewList;
  final size;

  const ActorWidget({Key key, this.crewItems, this.crewList, this.size})
      : super(key: key);

  @override
  ActorWidgetState createState() => ActorWidgetState();
}

class ActorWidgetState extends State<ActorWidget> {
  var temp;
  var tempActor;
  List<String> tempRoles = [];
  bool closed = false;
  Crew actor;

  final testController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return closed == false
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
                // TO DO: make every widget collapsible to reduce space
                child: ChipsInput(
                  maxChips: 1,
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Pumili ng aktor',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  findSuggestions: (String query) {
                    if (query.isNotEmpty) {
                      var lowercaseQuery = query.toLowerCase();
                      return widget.crewList.where((item) {
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
                    return widget.crewList;
                  },
                  onChanged: (data) {
                    setState(() {
                      actor = data[0]; // set actor locally
                      if (dynamicList.length > actors.length) {
                        // actor is not yet added to list
                        actors.add(data[0].crewId);
                      } else {
                        actors[widget.size] = data[0]
                            .crewId; // replace the value in the list if it already exists.
                      }
                    });
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
              SizedBox(
                height: 15,
              ),
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: TestChipsInput(
                  key: ObjectKey(widget.size),
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
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
                  submittedText:
                      temp != null ? temp.trimLeft().trimRight() : "",
                  onChanged: (data) {
                    List<String> tempList =
                        data.map((role) => role.toString()).toList();

                    setState(() {
                      roles[widget.size] = tempList; // replace
                      tempRoles.addAll(tempList);
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
              Container(
                child: OutlineButton(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  color: Colors.white,
                  onPressed: () {
                    // FocusScope.of(context).unfocus();
                    setState(() {
                      closed = true;
                    });
                  },
                  child: Text('Save'),
                ),
                alignment: Alignment.center,
              ),
            ]),
          )
        :
        // display this instead if closed == true
        ListTile(
            contentPadding: EdgeInsets.all(10),
            tileColor: Color.fromRGBO(240, 240, 240, 1),
            title: Text(
                (actor != null
                    ? (actor.firstName +
                        (actor.middleName != null
                            ? " " + actor.middleName
                            : "") +
                        (actor.lastName != null ? " " + actor.lastName : "") +
                        (actor.suffix != null ? " " + actor.suffix : ""))
                    : ""),
                softWrap: true,
                overflow: TextOverflow.clip),
            subtitle: Text(
              tempRoles.join(", "),
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            trailing: GestureDetector(
              child: Icon(Icons.edit),
              onTap: () {
                setState(() {
                  closed = false;
                });
              },
            ),
          );
  }
}
