import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/ui/shared/list_items.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';

// TO DO: FIX UI (e.g. INPUT FORM FIELDS)

class AddMovie extends StatefulWidget {
  AddMovie({Key key}) : super(key: key);
  _AddMovieState createState() => _AddMovieState();
}

const MaterialColor _buttonTextColor = MaterialColor(0xFFC41A3B, <int, Color>{
  50: Color(0xFFC41A3B),
  100: Color(0xFFC41A3B),
  200: Color(0xFFC41A3B),
  300: Color(0xFFC41A3B),
  400: Color(0xFFC41A3B),
  500: Color(0xFFC41A3B),
  600: Color(0xFFC41A3B),
  700: Color(0xFFC41A3B),
  800: Color(0xFFC41A3B),
  900: Color(0xFFC41A3B),
});

// ADD MOVIE FIRST PAGE
class _AddMovieState extends State<AddMovie> {
  DateTime _date = DateTime.now();
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  final posterController = TextEditingController();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  List<int> filmGenres = []; // Genre(s)
  List<int> directors = []; // Director(s)
  List<int> writers = []; // Writer(s)

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
        initialDate: _date,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData(
              primarySwatch: _buttonTextColor,
              primaryColor: Color(0xFFC41A3B),
              accentColor: Color(0xFFC41A3B),
            ),
            child: child,
          );
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
        if (i == j) {
          crewIds.add(crewList[i].crewId);
        }
      }
    }
    return crewIds;
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    fetchCrew();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var currentUser = _authenticationService.currentUser;

    final _scaffoldKey = GlobalKey<ScaffoldState>();

    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color.fromRGBO(20, 20, 20, 1),
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          backgroundColor: Color.fromRGBO(20, 20, 20, 1),
          title: Text(
            "Add Movie",
            style: TextStyle(color: Colors.white),
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
                        children: <Widget>[
                          SizedBox(height: 20),
                          // DIVIDER
                          Column(children: <Widget>[
                            Row(children: <Widget>[
                              Expanded(
                                child: new Container(
                                    margin: const EdgeInsets.only(
                                        left: 10.0, right: 20.0),
                                    child: Divider(
                                      color: Colors.red,
                                      thickness: 1,
                                      height: 20,
                                    )),
                              ),
                              Text("FILM INFO",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  )),
                              Expanded(
                                child: new Container(
                                    margin: const EdgeInsets.only(
                                        left: 20.0, right: 10.0),
                                    child: Divider(
                                      color: Colors.red,
                                      thickness: 1,
                                      height: 20,
                                    )),
                              ),
                            ]),
                          ]),
                          SizedBox(height: 20),
                          // MOVIE TITLE
                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.white,
                            ),
                            child: TextFormField(
                              controller: titleController,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: "Title",
                                labelStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
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
                                if (value.isEmpty) {
                                  return 'Movie title is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),

                          // SYNOPSIS
                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.white,
                            ),
                            child: TextFormField(
                              controller: synopsisController,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: "Synopsis",
                                labelStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
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
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // Release Date
                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.white,
                            ),
                            child: TextFormField(
                              readOnly: true,
                              onTap: () {
                                _selectDate(context);
                              },
                              decoration: InputDecoration(
                                labelText: "Release Date",
                                labelStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                hintText: DateFormat("MMM. d, y").format(_date),
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // POSTER URL
                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.white,
                            ),
                            child: TextFormField(
                              controller: posterController,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Poster URL",
                                labelStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Poster URL is required.';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // GENRE
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Genre(s)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.black,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                children: <Widget>[
                                  SearchableDropdown.multiple(
                                    key: UniqueKey(),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    menuBackgroundColor: Colors.white,
                                    underline: Container(),
                                    items: genreItems,
                                    selectedItems: filmGenres,
                                    hint: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text("Select any",
                                          style:
                                              TextStyle(color: Colors.white)),
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
                          ),
                          SizedBox(height: 20),
                          // DIVIDER
                          Column(children: <Widget>[
                            Row(children: <Widget>[
                              Expanded(
                                child: new Container(
                                    margin: const EdgeInsets.only(
                                        left: 10.0, right: 20.0),
                                    child: Divider(
                                      color: Colors.red,
                                      thickness: 1,
                                      height: 20,
                                    )),
                              ),
                              Text("CAST AND CREW",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  )),
                              Expanded(
                                child: new Container(
                                    margin: const EdgeInsets.only(
                                        left: 20.0, right: 10.0),
                                    child: Divider(
                                      color: Colors.red,
                                      thickness: 1,
                                      height: 20,
                                    )),
                              ),
                            ]),
                          ]),
                          SizedBox(height: 20),
                          // DIRECTOR(S)
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Director(s)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.black,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                children: <Widget>[
                                  SearchableDropdown.multiple(
                                    key: UniqueKey(),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    menuBackgroundColor: Colors.white,
                                    underline: Container(),
                                    items: crewItems,
                                    selectedItems: directors,
                                    hint: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text("Select any",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    searchHint: Text("Select any",
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
                          ),
                          SizedBox(height: 20),
                          // WRITER(S)
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Writer(s)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Theme(
                            data: theme.copyWith(
                              primaryColor: Colors.black,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                children: <Widget>[
                                  SearchableDropdown.multiple(
                                    key: UniqueKey(),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    menuBackgroundColor: Colors.white,
                                    underline: Container(),
                                    items: crewItems,
                                    selectedItems: writers,
                                    hint: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text("Select any",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    searchHint: Text("Select any",
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
                            ),
                          ),
                          Container(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Color.fromRGBO(220, 20, 60, 1)),
                                onPressed: () {
                                  // Validate returns true if the form is valid, or false
                                  // otherwise.
                                  if (_formKey.currentState.validate()) {
                                    // If the form is valid, save the data
                                    final response = model.addMovie(
                                        title: titleController.text,
                                        synopsis: synopsisController.text,
                                        releaseDate: _date.toIso8601String(),
                                        poster: posterController.text,
                                        genre: filmGenres,
                                        directors: crewIds(directors),
                                        writers: crewIds(writers),
                                        addedBy: currentUser.uid);

                                    response.then((res) => {
                                          if (res.statusCode == 200)
                                            {
                                              _scaffoldKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Movie added successfully.',
                                                      Colors.green))
                                            }
                                          else
                                            {
                                              _scaffoldKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Something went wrong. Try again.',
                                                      Colors.red))
                                            }
                                        });
                                  }
                                },
                                child: Text('Submit'),
                              ),
                            ),
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

// // ADD MOVIE SECOND PAGE
// class SecondPage extends StatefulWidget {
//   final List<String> previousFields;

//   SecondPage(this.previousFields);

//   @override
//   _SecondPageState createState() => _SecondPageState();
// }

// class _SecondPageState extends State<SignUpSecondPage> {
//   // Controllers
//   final directorController = TextEditingController();
//   final lastNameController = TextEditingController();
//   final birthdayController = TextEditingController();

//   final NavigationService _navigationService = locator<NavigationService>();

//   List<String> newUser = [];
