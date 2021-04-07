import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/ui/shared/list_items.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

// TO DO: FIX UI (e.g. INPUT FORM FIELDS)

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

  // MOVIE FIELD VARIABLES
  DateTime _date;
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  final runtimeController = TextEditingController();
  final dateController = TextEditingController();

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

  List<int> filmGenres = []; // Genre(s)
  List<int> directors = []; // Director(s)
  List<int> writers = []; // Writer(s)
  List<DropdownMenuItem> crewItems = [];
  List<Crew> crewList = [];

  int currentStep = 0;
  List<String> stepperTitle = [
    "Title, Release Date, Running Time, and Synopsis",
    "Poster and Screenshots",
    "Crew Member/s",
    "Genre/s",
    "Review"
  ];

  final List<DropdownMenuItem> genreItems =
      genres.map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList();

  // function for calling viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();

    crewList = await model.getAllCrew();
    // converts from List<Crew> to List<DropdownMenuItem>
    crewItems = crewList.map<DropdownMenuItem<dynamic>>((Crew value) {
      String name = value.firstName + " " + value.lastName;
      return DropdownMenuItem<dynamic>(
        key: Key(value.crewId.toString()),
        value: name,
        child: Text(name),
      );
    }).toList();
  }

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
        dateController.text = DateFormat("MMM. d, y").format(_date);
      });
    }
  }

  // gets the id of the crew using the list of indices provided by the Director(s)/Writer(s) select fields.
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

  // the genre array passed from the detail view is in string and named form, not as indices of the genres itself so we have to convert it first
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

  // get image using image picker for movie poster
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

  // get images using image picker for movie screenshots
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

  Widget displayScreenshots() {
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
                Container(
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
                    borderRadius: BorderRadius.circular(5.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        offset: Offset(0.0, 1.0),
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  @override
  void initState() {
    fetchCrew();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;

    final _scaffoldKey = GlobalKey<ScaffoldState>();

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
        runtimeController.text = movie.runningTime.toString() ?? '';

        // TO DO: IMAGE EDIT
        imageURI = movie?.poster ?? '';

        // GENRES
        filmGenres = genreIndices(movie?.genre ?? []);
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
            "Add Movie",
            style: TextStyle(color: Colors.black),
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
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          MyStepper(
                            type: MyStepperType.vertical,
                            currentStep: currentStep,
                            onStepTapped: (step) async {
                              if (step == 0) {
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
                                  case 0: // title, release date, running time, and synopsis
                                    setState(() {
                                      if (_formKeys[currentStep]
                                          .currentState
                                          .validate()) {
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
                                    setState(() => ++currentStep);
                                    break;
                                  case 3: // genre
                                    setState(() => ++currentStep);
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
                                      releaseDate: _date.toIso8601String(),
                                      runningTime: runtimeController.text,
                                      poster: imageFile,
                                      imageURI: imageURI,
                                      screenshots: screenshots,
                                      mimetype: mimetype,
                                      genre: filmGenres,
                                      directors: crewIds(directors),
                                      writers: crewIds(writers),
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
                                          builder: (context) =>
                                              MovieView(movie: movie),
                                        ),
                                      );
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
    );
  }

  Widget getContent(int index) {
    switch (index) {
      case 0:
        return Container(
          child: Column(
            children: [
              SizedBox(height: 10),
              // MOVIE TITLE
              TextFormField(
                controller: titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Title *",
                  hintStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value.isEmpty || value == null) {
                    return 'Movie title is required';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                readOnly: true,
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
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                  hintText: _date != null
                      ? DateFormat("MMM. d, y").format(_date)
                      : "Release Date",
                  hintStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              // RUNNING TIME
              TextFormField(
                controller: runtimeController,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Running Time (in minutes)",
                  hintStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: synopsisController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Colors.black,
                ),
                maxLines: 5,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                  hintText: "Synopsis *",
                  hintStyle: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value.isEmpty || value == null) {
                    return 'Synopsis is required';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 10,
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
              Text('Poster',
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
              Text('Screenshots',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              // multiple files for screenshots
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
                            ? displayScreenshots()
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
            children: [
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: <Widget>[
                    SearchableDropdown.multiple(
                      selectedValueWidgetFn: (item) => InputChip(
                        label: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: Color.fromRGBO(220, 220, 220, 1),
                        deleteIconColor: Color.fromRGBO(150, 150, 150, 1),
                        padding: EdgeInsets.all(7),
                        onPressed: () {},
                        onDeleted: () {
                          setState(() {
                            var index = crewItems.indexWhere(
                                (director) => director.value == item);
                            directors.removeWhere((item) => item == index);
                          });
                        },
                      ),
                      key: UniqueKey(),
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      underline: Container(),
                      items: crewItems,
                      selectedItems: directors,
                      hint: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text("Director *",
                            style:
                                TextStyle(color: Colors.black, fontSize: 16)),
                      ),
                      searchHint: Text("Search Any",
                          style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          directors = value;
                        });
                      },
                      closeButton: (directors) {
                        return (directors.isNotEmpty
                            ? "Save ${directors.length == 1 ? '"' + crewItems[directors.first].value.toString() + '"' : '(' + directors.length.toString() + ')'}"
                            : "Save without selection");
                      },
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: <Widget>[
                    SearchableDropdown.multiple(
                      selectedValueWidgetFn: (item) => InputChip(
                        label: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: Color.fromRGBO(220, 220, 220, 1),
                        deleteIconColor: Color.fromRGBO(150, 150, 150, 1),
                        padding: EdgeInsets.all(7),
                        onPressed: () {},
                        onDeleted: () {
                          setState(() {
                            var index = crewItems
                                .indexWhere((writer) => writer.value == item);
                            writers.removeWhere((item) => item == index);
                          });
                        },
                      ),
                      key: UniqueKey(),
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      menuBackgroundColor: Colors.white,
                      underline: Container(),
                      items: crewItems,
                      selectedItems: writers,
                      hint: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text("Writer *",
                            style:
                                TextStyle(color: Colors.black, fontSize: 16)),
                      ),
                      searchHint: Text("Search Any",
                          style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          writers = value;
                        });
                      },
                      closeButton: (writers) {
                        return (writers.isNotEmpty
                            ? "Save ${writers.length == 1 ? '"' + crewItems[writers.first].value.toString() + '"' : '(' + writers.length.toString() + ')'}"
                            : "Save without selection");
                      },
                      isExpanded: true,
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      case 3:
        return Container(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: <Widget>[
                    SearchableDropdown.multiple(
                      selectedValueWidgetFn: (item) => InputChip(
                        label: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        backgroundColor: Color.fromRGBO(220, 220, 220, 1),
                        deleteIconColor: Color.fromRGBO(150, 150, 150, 1),
                        padding: EdgeInsets.all(7),
                        onPressed: () {},
                        onDeleted: () {
                          setState(() {
                            var index = genreItems
                                .indexWhere((genre) => genre.value == item);
                            filmGenres.removeWhere((item) => item == index);
                          });
                        },
                      ),
                      key: UniqueKey(),
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      underline: Container(),
                      items: genreItems,
                      selectedItems: filmGenres,
                      hint: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text("Genre *",
                            style:
                                TextStyle(color: Colors.black, fontSize: 16)),
                      ),
                      searchHint: Text("Select any",
                          style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          filmGenres = value;
                        });
                      },
                      closeButton: (filmGenres) {
                        return (filmGenres.isNotEmpty
                            ? "Save ${filmGenres.length == 1 ? '"' + genreItems[filmGenres.first].value.toString() + '"' : '(' + filmGenres.length.toString() + ')'}"
                            : "Save without selection");
                      },
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
        return Container(
          height: 400,
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
                    child: Text("Title: ",
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
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Release Date: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _date == null
                          ? ''
                          : DateFormat("MMM. d, y").format(_date),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Synopsis: ",
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
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Poster: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
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
                  ),
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Director/s: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Column(
                        children: crewIds(directors)
                            .map<Widget>(
                              (index) => new Row(
                                children: [
                                  new Icon(Icons.fiber_manual_record, size: 16),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  new Text(
                                    crewItems[index].value,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                            .toList()),
                  ),
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Writer/s: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Column(
                        children: crewIds(writers)
                            .map<Widget>(
                              (index) => new Row(
                                children: [
                                  new Icon(Icons.fiber_manual_record, size: 16),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  new Text(
                                    crewItems[index].value,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                            .toList()),
                  ),
                  SizedBox(height: 10),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Text("Genre/s: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  Container(
                    alignment: Alignment.topLeft,
                    child: Column(
                        children: filmGenres
                            .map<Widget>(
                              (index) => new Row(
                                children: [
                                  new Icon(Icons.fiber_manual_record, size: 16),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  genreItems[index].child,
                                ],
                              ),
                            )
                            .toList()),
                  ),
                ],
              ),
            ),
          ),
        );
    }
    return null;
  }
}
