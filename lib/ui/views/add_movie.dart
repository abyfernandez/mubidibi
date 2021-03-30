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

// TO DO: FIX UI (e.g. INPUT FORM FIELDS)

class AddMovie extends StatefulWidget {
  final Movie movie;
  // final List<List<Crew>> crew;

  AddMovie({Key key, this.movie}) : super(key: key);

  @override
  _AddMovieState createState() => _AddMovieState(movie);
}

// ADD MOVIE FIRST PAGE
class _AddMovieState extends State<AddMovie> {
  final Movie movie;
  // final List<List<Crew>> crew;

  _AddMovieState(this.movie);

  DateTime _date;
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  File imageFile; // for uploading poster w/ image picker
  final picker = ImagePicker();
  var mimetype;
  String base64Image; // picked image in base64 format
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  List<int> filmGenres = []; // Genre(s)
  List<int> directors = []; // Director(s)
  List<int> writers = []; // Writer(s)
  int currentStep = 0;
  List<String> stepperTitle = [
    "Title, Release Date, and Synopsis",
    "Poster",
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

  List<DropdownMenuItem> crewItems = []; // declare a class variable
  List<Crew> crewList = []; // declare a class variable

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

  // // function for calling viewmodel's getCrewForDetails method (EDIT MOVIE)
  // Future<List<List<Crew>>> fetchMovieCrew(String movieId) async {
  //   if (movieId != null) {
  //     var model = CrewViewModel();
  //     var crew = await model.getCrewForDetails(movieId: movieId);
  //     return crew;
  //   } else {
  //     return [];
  //   }
  // }

  // get image using image picker
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

  final _formKey = GlobalKey<FormState>();

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
        // update controller's text field
        titleController.text = movie?.title ?? '';
        _date = movie?.releaseDate != null
            ? DateTime.parse(movie?.releaseDate)
            : null;
        synopsisController.text = movie?.synopsis ?? '';
        // TO DO: IMAGE EDIT
        filmGenres = genreIndices(movie?.genre ?? []);
        // crew here
        // crew != null ? directors = crew[0] : []
        // directors = // TO DO: crew initial value in fields
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          MyStepper(
                            type: MyStepperType.vertical,
                            currentStep: currentStep,
                            onStepTapped: (step) async {
                              // only allow tapping of steps for those already completed
                              if (step <= currentStep) {
                                // do not allow tapping of future steps
                                setState(() => currentStep = step);
                              } else if (step == currentStep + 1) {
                                // allow tapping of immediate future step once the fields are all filled out
                                switch (currentStep) {
                                  case 0: // title, release date, and synopsis
                                    if (titleController.text.trim() == "" ||
                                        _date == null ||
                                        synopsisController.text.trim() == "") {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'All fields are required.',
                                              Colors.red));
                                    } else {
                                      setState(() => currentStep = step);
                                    }
                                    break;
                                  case 1: // poster
                                    if (imageFile == null) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Poster is required.',
                                              Colors.red));
                                    } else {
                                      setState(() => currentStep = step);
                                    }
                                    break;
                                  case 2: // crew members
                                    if (directors.length == 0 ||
                                        writers.length == 0) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'All fields are required.',
                                              Colors.red));
                                    } else {
                                      setState(() => currentStep = step);
                                    }
                                    break;
                                  case 3: // genre
                                    if (filmGenres.length == 0) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Genre is required.',
                                              Colors.red));
                                    } else {
                                      setState(() => currentStep = step);
                                    }
                                    break;
                                }
                              } else if (step >= currentStep + 2) {
                                // check first if steps before the clicked step are all filled out before allowing or not
                                bool checker = true;
                                for (var i = currentStep; i < step; i++) {
                                  switch (i) {
                                    case 0: // title, release date, and synopsis
                                      if (titleController.text.trim() == "" ||
                                          _date == null ||
                                          synopsisController.text.trim() ==
                                              "") {
                                        checker = false;
                                      }
                                      break;
                                    case 1: // poster
                                      if (imageFile == null) {
                                        checker = false;
                                      }
                                      break;
                                    case 2: // crew members
                                      if (directors.length == 0 ||
                                          writers.length == 0) {
                                        checker = false;
                                      }
                                      break;
                                    case 3: // genre
                                      if (filmGenres.length == 0) {
                                        checker = false;
                                      }
                                      break;
                                  }
                                }
                                if (checker == false) {
                                  // show error snackbar
                                  _scaffoldKey.currentState.showSnackBar(
                                      mySnackBar(
                                          context,
                                          'Skipping of steps is not allowed.',
                                          Colors.red));
                                } else {
                                  setState(() => currentStep = step);
                                }
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
                                  case 0: // title, release date, and synopsis
                                    if (titleController.text.trim() == "" ||
                                        _date == null ||
                                        synopsisController.text.trim() == "") {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'All fields are required.',
                                              Colors.red));
                                    } else {
                                      setState(() => ++currentStep);
                                    }
                                    break;
                                  case 1: // poster
                                    if (imageFile == null) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Poster is required.',
                                              Colors.red));
                                    } else {
                                      setState(() => ++currentStep);
                                    }
                                    break;
                                  case 2: // crew members
                                    if (directors.length == 0 ||
                                        writers.length == 0) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'All fields are required.',
                                              Colors.red));
                                    } else {
                                      setState(() => ++currentStep);
                                    }
                                    break;
                                  case 3: // genre
                                    if (filmGenres.length == 0) {
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Genre is required.',
                                              Colors.red));
                                    } else {
                                      setState(() => ++currentStep);
                                    }
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
                                  final response = await model.addMovie(
                                      title: titleController.text,
                                      synopsis: synopsisController.text,
                                      releaseDate: _date.toIso8601String(),
                                      poster: imageFile,
                                      mimetype: mimetype,
                                      genre: filmGenres,
                                      directors: crewIds(directors),
                                      writers: crewIds(writers),
                                      addedBy: currentUser.userId);

                                  // while response is not yet returned, show circular progress indicator

                                  if (response != null) {
                                    // show success snackbar
                                    _scaffoldKey.currentState.showSnackBar(
                                        mySnackBar(
                                            context,
                                            'Movie added successfully.',
                                            Colors.green));

                                    // redirect to detail view using response
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MovieView(movie: response),
                                      ),
                                    );
                                  } else {
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
                                    child: getContent(i),
                                  ),
                                ),
                            ],
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
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value.isEmpty) {
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
                      : "Release Date *",
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
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: synopsisController,
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
                ),
                validator: (value) {
                  if (value.isEmpty) {
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
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              // Material(
              //   child: Container(
              //     child: IconButton(
              //       tooltip: 'Send Image',
              //       icon: Icon(Icons.image, size: 50),
              //       onPressed: getImage,
              //       color: Theme.of(context).accentColor,
              //     ),
              //   ),
              // ),
              GestureDetector(
                onTap: getImage,
                child: Container(
                  height: 200,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: imageFile != null
                      ? Container(
                          height: 200,
                          width: 150,
                          child: Image.file(
                            imageFile,
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        )
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
              )
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
