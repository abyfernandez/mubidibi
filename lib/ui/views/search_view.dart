// SEARCH VIEW
// BASIC SEARCH BAR RETURNS A LIST OF MOVIES THAT FIT THE SEARCH QUERY

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
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

  List<Movie> queryResult = [];
  List<Movie> movies = [];
  bool noResult = false;

  void fetchMovies() async {
    var model = MovieViewModel();
    movies = await model.getAllMovies();
  }

  @override
  void initState() {
    fetchMovies();
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
                                      hintText: 'Search',
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
                                      searchController.text.trim() != ""
                                          ? setState(() {
                                              queryResult =
                                                  movies.where((movie) {
                                                return movie.title.contains(
                                                  new RegExp(query.trimRight(),
                                                      caseSensitive: false),
                                                );
                                              }).toList();
                                              noResult = false;
                                            })
                                          : setState(() {
                                              queryResult = [];
                                            });
                                    },
                                    onFieldSubmitted: (query) {
                                      if (queryResult.isEmpty) {
                                        setState(() {
                                          noResult = true;
                                        });
                                      }
                                    },
                                  ),
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
                                    queryResult = [];
                                  });
                                },
                                child: Container(
                                  child: Text('Cancel',
                                      style: TextStyle(fontSize: 15)),
                                ),
                              )
                            : Container(),
                        SizedBox(width: 15),
                      ],
                    ),
                    Wrap(
                        children: queryResult.length != 0
                            ? queryResult
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
                                            margin: const EdgeInsets.symmetric(
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
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                MovieView(movie: movie),
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
                                          : Text('Search for a movie',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 18))),
                                  height: (screenSize.height / 3) * 2,
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
