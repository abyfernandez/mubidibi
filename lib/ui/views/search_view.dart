// SEARCH VIEW
// BASIC SEARCH BAR RETURNS A LIST OF MOVIES THAT FIT THE SEARCH QUERY

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/globals.dart' as Config;

class SearchView extends StatefulWidget {
  SearchView({Key key}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final NavigationService _navigationService = locator<NavigationService>();
  final searchController = TextEditingController();

  List<Movie> movieQueryResult = [];
  List<Crew> crewQueryResult = [];
  List<Movie> movies = [];
  List<Crew> crew = [];
  bool noResult = false;
  String _searchBy = 'Pelikula';

  void fetchMovies() async {
    var model = MovieViewModel();
    movies = await model.getAllMovies();
  }

  void fetchCrew() async {
    var model = CrewViewModel();
    crew = await model.getAllCrew();
  }

  @override
  void initState() {
    fetchMovies();
    fetchCrew();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            // TO DO: REDUCE SIZE OF TEXTFORMFIELD
                            margin: EdgeInsets.all(10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Color.fromRGBO(240, 240, 240, 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(width: 15),
                                Icon(Icons.search_outlined, size: 20),
                                SizedBox(width: 5),
                                Expanded(
                                  child: TextFormField(
                                    controller: searchController,
                                    keyboardType: TextInputType.text,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 5),
                                      hintText: 'Maghanap',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor:
                                          Color.fromRGBO(240, 240, 240, 1),
                                    ),
                                    onChanged: (query) {
                                      // Search for the movie/s that fit/s the query string
                                      List<String> parsedQuery = [];
                                      parsedQuery = query.split(' ');

                                      // TO DO: MORE ACCURATE SEARCHES

                                      if (_searchBy == "Pelikula") {
                                        searchController.text.trim() != ""
                                            ? setState(() {
                                                movieQueryResult =
                                                    movies.where((movie) {
                                                  return movie.title.contains(
                                                    new RegExp(
                                                        query.trimRight(),
                                                        caseSensitive: false),
                                                  );
                                                }).toList();
                                                movieQueryResult.isEmpty
                                                    ? noResult = true
                                                    : noResult = false;
                                              })
                                            : setState(() {
                                                movieQueryResult = [];
                                              });
                                      } else {
                                        // search by Crew name
                                        searchController.text.trim() != ""
                                            ? setState(() {
                                                crewQueryResult =
                                                    crew.where((c) {
                                                  var name = c.firstName +
                                                      " " +
                                                      (c.middleName != null
                                                          ? c.middleName
                                                          : "") +
                                                      c.lastName +
                                                      (c.suffix != null
                                                          ? " " + c.suffix
                                                          : "");
                                                  return (name.contains(
                                                    new RegExp(
                                                        query.trimRight(),
                                                        caseSensitive: false),
                                                  ));
                                                }).toList();
                                                crewQueryResult.isEmpty
                                                    ? noResult = true
                                                    : noResult = false;
                                              })
                                            : setState(() {
                                                crewQueryResult = [];
                                              });
                                      }
                                    },
                                    onFieldSubmitted: (query) {
                                      if (_searchBy == "Pelikula" &&
                                          movieQueryResult.isEmpty) {
                                        setState(() {
                                          noResult = true;
                                        });
                                      } else if (_searchBy == "Personalidad" &&
                                          crewQueryResult.isEmpty) {
                                        setState(() {
                                          noResult = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                    height: 25,
                                    child: VerticalDivider(
                                        color: Colors.grey[850])),
                                DropdownButton(
                                  value: _searchBy,
                                  underline: Container(),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Pelikula',
                                      child: Text('Pelikula'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Personalidad',
                                      child: Text('Personalidad'),
                                    ),
                                  ],
                                  onChanged: (choice) {
                                    setState(() {
                                      _searchBy = choice;

                                      if (searchController.text.trim() != "" &&
                                          _searchBy == "Pelikula") {
                                        movieQueryResult =
                                            movies.where((movie) {
                                          return movie.title.contains(
                                            new RegExp(
                                                searchController.text
                                                    .trimRight(),
                                                caseSensitive: false),
                                          );
                                        }).toList();
                                        movieQueryResult.isEmpty
                                            ? noResult = true
                                            : noResult = false;
                                      } else if (searchController.text.trim() !=
                                              "" &&
                                          _searchBy == "Personalidad") {
                                        crewQueryResult = crew.where((c) {
                                          return c.firstName.contains(
                                            new RegExp(
                                                searchController.text
                                                    .trimRight(),
                                                caseSensitive: false),
                                          );
                                        }).toList();
                                        crewQueryResult.isEmpty
                                            ? noResult = true
                                            : noResult = false;
                                      } else {
                                        movieQueryResult = [];
                                        crewQueryResult = [];
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        searchController.text.trim() != ""
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    searchController.text = "";
                                    movieQueryResult = [];
                                    crewQueryResult = [];
                                    noResult = false;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: Text('Cancel',
                                      style: TextStyle(fontSize: 15)),
                                ),
                              )
                            : Container(),
                        // SizedBox(width: 15),
                      ],
                    ),
                    // TO DO: Include name for crew, and change display for crew (maybe listview??)
                    Wrap(
                        children: _searchBy == "Pelikula"
                            ? movieQueryResult.length != 0
                                ? movieQueryResult
                                    .map(
                                      (movie) => GestureDetector(
                                        child: Container(
                                          height: 210.0,
                                          child: Stack(
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                height: 200.0,
                                                width: 120.0,
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black54,
                                                      offset: Offset(0.0, 0.0),
                                                      blurRadius: 2.0,
                                                    ),
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  movie.title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                height: 200.0,
                                                width: 120.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                      movie.poster != null
                                                          ? movie.poster
                                                          : Config.imgNotFound,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 9,
                                                left: 9,
                                                right: 9,
                                                child: Container(
                                                  padding: EdgeInsets.all(5),
                                                  alignment:
                                                      Alignment.bottomLeft,
                                                  child: Text(
                                                    movie.title,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: Colors.black54,
                                                          offset:
                                                              Offset(0.0, 0.0),
                                                          blurRadius:
                                                              0.0), // 4                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MovieView(
                                                    movieId: movie.movieId
                                                        .toString()),
                                              ));
                                        },
                                      ),
                                    )
                                    .toList()
                                : [
                                    Container(
                                      child: Center(
                                          child: noResult == true
                                              ? Text('Walang resulta.',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18))
                                              : Text(
                                                  _searchBy == "Pelikula"
                                                      ? 'Maghanap ng pelikula'
                                                      : 'Maghanap ng personalidad',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18))),
                                      height: (screenSize.height / 3) * 2.5,
                                    )
                                  ]
                            : crewQueryResult.length != 0
                                ? crewQueryResult
                                    .map(
                                      (c) => GestureDetector(
                                        child: Container(
                                          height: 210.0,
                                          child: Stack(
                                            children: [
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0),
                                                height: 200.0,
                                                width: 120.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  image: DecorationImage(
                                                    alignment: Alignment.center,
                                                    image:
                                                        CachedNetworkImageProvider(
                                                      c.displayPic != null
                                                          ? c.displayPic
                                                          : Config.userNotFound,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 9,
                                                left: 9,
                                                right: 9,
                                                child: Container(
                                                  padding: EdgeInsets.all(5),
                                                  alignment:
                                                      Alignment.bottomLeft,
                                                  child: Text(
                                                    c.firstName +
                                                        " " +
                                                        (c.middleName != null
                                                            ? " " + c.middleName
                                                            : "") +
                                                        " " +
                                                        c.lastName +
                                                        (c.suffix != null
                                                            ? " " + c.suffix
                                                            : ""),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: Colors.black54,
                                                          offset:
                                                              Offset(0.0, 0.0),
                                                          blurRadius:
                                                              0.0), // 4                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CrewView(
                                                  crewId: c.crewId.toString(),
                                                ),
                                              ));
                                        },
                                      ),
                                    )
                                    .toList()
                                : [
                                    Container(
                                      child: Center(
                                          child: noResult == true
                                              ? Text('No results found.',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18))
                                              : Text(
                                                  _searchBy == "Pelikula"
                                                      ? 'Maghanap ng pelikula'
                                                      : 'Maghanap ng personalidad',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18))),
                                      height: (screenSize.height / 3) * 2.5,
                                    )
                                  ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
