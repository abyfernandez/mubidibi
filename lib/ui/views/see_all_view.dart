// See All Page

import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class SeeAllView extends StatefulWidget {
  final List<Movie> movies;
  final List<Movie> favorites;
  final List<Crew> crew;
  final String type;
  final String filter;
  final bool showFilter;
  final String title;

  SeeAllView({
    Key key,
    this.movies,
    this.favorites,
    this.crew,
    this.type,
    this.filter,
    this.showFilter = false,
    this.title,
  }) : super(key: key);

  @override
  _SeeAllViewState createState() => _SeeAllViewState(
      movies, crew, favorites, type, filter, showFilter, title);
}

class _SeeAllViewState extends State<SeeAllView> {
  final List<Movie> movies;
  final List<Movie> favorites;
  final List<Crew> crew;
  final String type;
  final String
      filter; // variable for when user came from the genre dropdown in the homepage. this will later be added to the list of filters
  final bool showFilter;
  final String title;

  final NavigationService _navigationService = locator<NavigationService>();

  List<Movie> films = [];
  List<Crew> personalidad = [];
  List<String> filters = []; // list of filters to apply
  List<String> genres = []; // String versions of genre straight from api
  FocusNode filterNode;
  List<String> roles = ['Direktor', 'Manunulat', 'Aktor'];
  List filtered = []; // filtered films
  bool isBusy =
      true; // to show circular progress indicator while data is loading

  _SeeAllViewState(this.movies, this.crew, this.favorites, this.type,
      this.filter, this.showFilter, this.title);

  @override
  void initState() {
    super.initState();
    filters = [];
    if (filter != null && filter != "") filters.add(filter);
    if (type == "movies")
      fetchMovies();
    else if (type == "favorites")
      fetchFavorites();
    else if (type == "crew") fetchCrew();
  }

  @override
  Widget build(BuildContext context) {
    if ((filtered == null || filtered.length == 0) && isBusy == true)
      return Container(
          color: Colors.white,
          height: double.infinity,
          child: Center(child: Container(child: CircularProgressIndicator())));

    return Scaffold(
        // backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          title: Text('${title[0].toUpperCase()}${title.substring(1)}'),
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();
              _navigationService.pop();
            },
          ),
        ),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(child: showContent(context)))));
  }

  // function for calling viewmodel's getAllMovies method
  void fetchMovies() async {
    if (movies == null) {
      var model = MovieViewModel();
      films = await model.getAllMovies(mode: "list");

      // fetch genre from API
      final response = await http.get(Config.api + 'genres/');

      if (response.statusCode == 200) {
        genres = List<String>.from(
            json.decode(response.body).map((x) => x['genre']));
      }

      // if (mounted) {
      setState(() {
        filtered = films;
        applyFilter(filters);
      });
      // }
    } else {
      // if (mounted) {
      setState(() {
        films = movies;
        filtered = films;
        applyFilter(filters);
      });
      // }
    }
  }

  // function for calling viewmodel's getFavorites method
  void fetchFavorites() async {
    if (movies == null) {
      var model = MovieViewModel();
      films = await model.getFavorites(mode: "list");

      // fetch genre from API
      final response = await http.get(Config.api + 'genres/');

      if (response.statusCode == 200) {
        genres = List<String>.from(
            json.decode(response.body).map((x) => x['genre']));
      }

      setState(() {
        filtered = films;
        applyFilter(filters);
      });
    } else {
      setState(() {
        films = movies;
        filtered = films;
        applyFilter(filters);
      });
    }
  }

  // function for calling viewmodel's getAllCrew method
  void fetchCrew() async {
    if (crew == null) {
      var model = CrewViewModel();
      personalidad = await model.getAllCrew(mode: "list");

      setState(() {
        filtered = personalidad;
        applyFilter(filters);
      });
    } else {
      setState(() {
        personalidad = crew;
        filtered = personalidad;
        applyFilter(filters);
      });
    }
  }

  void applyFilter(List<String> groupBy) {
    if (type == 'movies' || type == "favorites") {
      filtered = films
          .where((item) =>
              item.genre != null && item.genre.toSet().containsAll(groupBy))
          .toList();
    } else if (type == 'crew') {
      filtered = personalidad
          .where((item) =>
              item.type != null && item.type.toSet().containsAll(groupBy))
          .toList();
    }
    // if (mounted) {
    setState(() {
      filtered = filtered;
      isBusy = false;
    });
    // }
  }

  Widget showContent(context) {
    switch (type) {
      case "movies":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              showFilter == true
                  ? Container(
                      margin: EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ChipsInput(
                        initialValue: filters,
                        focusNode: filterNode,
                        keyboardAppearance: Brightness.dark,
                        textCapitalization: TextCapitalization.words,
                        enabled: true,
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Filter by genre',
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          border: InputBorder.none,
                        ),
                        findSuggestions: (String query) {
                          if (query.isNotEmpty) {
                            var lowercaseQuery = query.toLowerCase();
                            return genres.where((item) {
                              return !filters
                                      .map((d) => d)
                                      .toList()
                                      .contains(item) &&
                                  item
                                      .toLowerCase()
                                      .contains(query.toLowerCase());
                            }).toList(growable: false)
                              ..sort((a, b) => a
                                  .toLowerCase()
                                  .indexOf(lowercaseQuery)
                                  .compareTo(
                                      b.toLowerCase().indexOf(lowercaseQuery)));
                          }
                          return [];
                        },
                        onChanged: (data) {
                          var newList = List<String>.from(data);
                          filters = newList;
                          applyFilter(filters);
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
                    )
                  : SizedBox(),
              showFilter == true ? SizedBox(height: 20) : SizedBox(),
              Wrap(
                  children: filtered.length != 0
                      ? filtered
                          .map(
                            (movie) => GestureDetector(
                              child: Container(
                                height: 210.0,
                                child: Stack(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      // height: 200.0,
                                      height:
                                          (MediaQuery.of(context).size.width /
                                                  3) *
                                              1.5,
                                      // width: 120.0,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  3) -
                                              16,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black54,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 0.0, // 2
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          movie.title +
                                              (movie.releaseDate != "" &&
                                                      movie.releaseDate != null
                                                  ? (" (" +
                                                      DateFormat('y').format(
                                                          DateTime.parse(movie
                                                              .releaseDate)) +
                                                      ") ")
                                                  : ""),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      // height: 200.0,
                                      height:
                                          (MediaQuery.of(context).size.width /
                                                  3) *
                                              1.5,
                                      // width: 120.0,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  3) -
                                              16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            movie.posters != null &&
                                                    movie.posters.length != 0
                                                ? movie.posters[0].url
                                                : Config.imgNotFound,
                                          ),
                                          fit: BoxFit.cover,
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
                                      builder: (_) =>
                                          MovieView(movieId: movie.movieId),
                                    ));
                              },
                            ),
                          )
                          .toList()
                      : [
                          Center(
                            child: Text("No content found.",
                                style: TextStyle(fontSize: 14)),
                          ),
                        ]),
              SizedBox(height: 10),
            ],
          ),
        );
        break;
      case "favorites":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              showFilter == true
                  ? Container(
                      margin: EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ChipsInput(
                        initialValue: filters,
                        focusNode: filterNode,
                        keyboardAppearance: Brightness.dark,
                        textCapitalization: TextCapitalization.words,
                        enabled: true,
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Filter by genre',
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          border: InputBorder.none,
                        ),
                        findSuggestions: (String query) {
                          if (query.isNotEmpty) {
                            var lowercaseQuery = query.toLowerCase();
                            return genres.where((item) {
                              return !filters
                                      .map((d) => d)
                                      .toList()
                                      .contains(item) &&
                                  item
                                      .toLowerCase()
                                      .contains(query.toLowerCase());
                            }).toList(growable: false)
                              ..sort((a, b) => a
                                  .toLowerCase()
                                  .indexOf(lowercaseQuery)
                                  .compareTo(
                                      b.toLowerCase().indexOf(lowercaseQuery)));
                          }
                          return [];
                        },
                        onChanged: (data) {
                          var newList = List<String>.from(data);
                          filters = newList;
                          applyFilter(filters);
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
                    )
                  : SizedBox(),
              showFilter == true ? SizedBox(height: 20) : SizedBox(),
              Wrap(
                  children: filtered.length != 0
                      ? filtered
                          .map(
                            (movie) => GestureDetector(
                              child: Container(
                                height: 210.0,
                                child: Stack(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      // height: 200.0,
                                      // width: 120.0,
                                      height:
                                          (MediaQuery.of(context).size.width /
                                                  3) *
                                              1.5,
                                      // width: 120.0,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  3) -
                                              16,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black54,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 0.0, // 2
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          movie.title +
                                              (movie.releaseDate != "" &&
                                                      movie.releaseDate != null
                                                  ? (" (" +
                                                      DateFormat('y').format(
                                                          DateTime.parse(movie
                                                              .releaseDate)) +
                                                      ") ")
                                                  : ""),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      // height: 200.0,
                                      // width: 120.0,
                                      height:
                                          (MediaQuery.of(context).size.width /
                                                  3) *
                                              1.5,
                                      // width: 120.0,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  3) -
                                              16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            movie.posters != null &&
                                                    movie.posters.length != 0
                                                ? movie.posters[0].url
                                                : Config.imgNotFound,
                                          ),
                                          fit: BoxFit.cover,
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
                                      builder: (_) =>
                                          MovieView(movieId: movie.movieId),
                                    ));
                              },
                            ),
                          )
                          .toList()
                      : [
                          Center(
                            child: Text("No content found.",
                                style: TextStyle(fontSize: 14)),
                          ),
                        ]),
            ],
          ),
        );
        break;
      case "crew":
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              showFilter == true
                  ? Container(
                      margin: EdgeInsets.only(left: 15, right: 15),
                      decoration: BoxDecoration(
                        // color: Colors.white,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ChipsInput(
                        initialValue: filters,
                        focusNode: filterNode,
                        keyboardAppearance: Brightness.dark,
                        textCapitalization: TextCapitalization.words,
                        enabled: true,
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Filter by type',
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          border: InputBorder.none,
                        ),
                        findSuggestions: (String query) {
                          if (query.isNotEmpty) {
                            var lowercaseQuery = query.toLowerCase();
                            return roles.where((item) {
                              return !filters
                                      .map((d) => d)
                                      .toList()
                                      .contains(item) &&
                                  item
                                      .toLowerCase()
                                      .contains(query.toLowerCase());
                            }).toList(growable: false)
                              ..sort((a, b) => a
                                  .toLowerCase()
                                  .indexOf(lowercaseQuery)
                                  .compareTo(
                                      b.toLowerCase().indexOf(lowercaseQuery)));
                          }
                          return [];
                        },
                        onChanged: (data) {
                          var newList = List<String>.from(data);
                          filters = newList;
                          applyFilter(filters);
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
                    )
                  : SizedBox(),
              showFilter == true ? SizedBox(height: 20) : SizedBox(),
              Wrap(
                children: filtered.length != 0
                    ? filtered
                        .map(
                          (crew) => GestureDetector(
                            child: Container(
                              height: 210.0,
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4),
                                    // height: 200.0,
                                    // width: 120.0,
                                    height: (MediaQuery.of(context).size.width /
                                            3) *
                                        1.5,
                                    // width: 120.0,
                                    width: (MediaQuery.of(context).size.width /
                                            3) -
                                        16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          crew.displayPic != null &&
                                                  crew.displayPic.url != null
                                              ? crew.displayPic.url
                                              : Config.userNotFound,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 3,
                                    left: 9,
                                    right: 9,
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        crew.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black54,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 0.0, // 4
                                          ),
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
                                    builder: (_) =>
                                        CrewView(crewId: crew.crewId),
                                  ));
                            },
                          ),
                        )
                        .toList()
                    : [
                        Center(
                          child: Text("No content found.",
                              style: TextStyle(fontSize: 14)),
                        )
                      ],
              ),
            ],
          ),
        );
        break;
    }

    return null;
  }
}
