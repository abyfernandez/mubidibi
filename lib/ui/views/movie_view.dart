import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/ui/widgets/content_scroll.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import '../../locator.dart';
import 'full_photo.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';

import 'home_view.dart';

class MovieView extends StatefulWidget {
  final Movie movie;

  MovieView({this.movie});

  @override
  _MovieViewState createState() => _MovieViewState(movie);
}

class _MovieViewState extends State<MovieView>
    with SingleTickerProviderStateMixin {
  final Movie movie;

  _MovieViewState(this.movie);

  Future<List<List<Crew>>> crew;
  ScrollController _scrollController;
  Animation<double> _animation;
  AnimationController _animationController;

  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // function for calling viewmodel's getCrewForDetails method
  Future<List<List<Crew>>> fetchCrew(String movieId) async {
    var model = CrewViewModel();
    var crew = await model.getCrewForDetails(movieId: movieId);
    return crew;
  }

  @override
  void initState() {
    crew = fetchCrew(movie.movieId.toString());

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionBubble(
        // Menu items
        items: <Bubble>[
          // Floating action menu item
          Bubble(
            title: "Edit",
            iconColor: Colors.white,
            bubbleColor: Colors.lightBlue,
            icon: Icons.edit_outlined,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMovie(movie: movie),
                ),
              );
              _animationController.reverse();
            },
          ),
          //Floating action menu item
          Bubble(
            title: "Delete",
            iconColor: Colors.white,
            bubbleColor: Colors.lightBlue,
            icon: Icons.delete,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () async {
              _animationController.reverse();

              var response = await _dialogService.showConfirmationDialog(
                  title: "Confirm Deletion",
                  cancelTitle: "No",
                  confirmationTitle: "Yes",
                  description:
                      "Are you sure that you want to delete this movie?");
              if (response.confirmed == true) {
                // _navigationService.pop();
                var model = MovieViewModel();
                var deleteRes =
                    await model.deleteMovie(id: movie.movieId.toString());
                if (deleteRes.statusCode == 200) {
                  // show success snackbar
                  _scaffoldKey.currentState.showSnackBar(mySnackBar(
                      context, 'Movie deleted successfully.', Colors.green));
                  // redirect to homepage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeView(),
                    ),
                  );
                } else {
                  _scaffoldKey.currentState.showSnackBar(mySnackBar(
                      context, 'Something went wrong. Try again.', Colors.red));
                }
              }
            },
          ),
        ],

        // animation controller
        animation: _animation,

        // On pressed change animation state
        onPress: () => {
          _animationController.isCompleted
              ? _animationController.reverse()
              : _animationController.forward(),
        },

        // Floating Action button Icon color
        iconColor: Colors.white,

        // Flaoting Action button Icon
        iconData: Icons.settings,
        backGroundColor: Colors.lightBlue,
      ),
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 400,
                decoration: new BoxDecoration(
                  image: new DecorationImage(
                    image: new NetworkImage(widget.movie.poster),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    new BackdropFilter(
                      filter: new ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                      child: new Container(
                        decoration: new BoxDecoration(
                            color: Colors.black.withOpacity(0.3)),
                      ),
                    ),
                    GestureDetector(
                      child: Center(
                        child: Image.network(
                          widget.movie.poster,
                          height: 350,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullPhoto(url: widget.movie.poster),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    padding: EdgeInsets.only(left: 30.0),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    iconSize: 30.0,
                    color: Colors.white,
                  ),
                  IconButton(
                    padding: EdgeInsets.only(right: 20.0),
                    onPressed: () => print('Add to Favorites'),
                    icon: Icon(Icons.add),
                    iconSize: 30.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    widget.movie.title.toUpperCase(),
                    style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    widget.movie.genre
                        .reduce((curr, next) => curr + ", " + next),
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ]),
                Text(
                  '⭐ ⭐ ⭐ ⭐',
                  style: TextStyle(fontSize: 20.0),
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          'Date Released',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          DateFormat("MMM. d, y").format(
                            DateTime.parse(widget.movie.releaseDate),
                          ),
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Running Time',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          '125 mins.',
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Synopsis',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              widget.movie.synopsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.0,
              ),
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Directors",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: FutureBuilder(
                future: crew,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data[0].isEmpty)
                      return Column(
                        children: [
                          Text(
                            "No records found.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    else {
                      return Column(
                          children: snapshot.data[0]
                              .map<Widget>(
                                (director) => new Row(
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    new Text(
                                      director.firstName +
                                          " " +
                                          director.lastName,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                              .toList());
                    }
                  } else {
                    return Container();
                  }
                }),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Writers",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: FutureBuilder(
                future: crew,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data[1].isEmpty)
                      return Column(
                        children: [
                          Text(
                            "No records found.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    else {
                      return Column(
                          children: snapshot.data[1]
                              .map<Widget>(
                                (writer) => new Row(
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    new Text(
                                      writer.firstName + " " + writer.lastName,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                              .toList());
                    }
                  } else {
                    return Container();
                  }
                }),
          ),
          SizedBox(height: 15),
          ContentScroll(
            // images are hardcoded for now.
            // TO DO: create a function that returns a List<String> of all the photos of the crew
            images: [
              'assets/test/1.jpg',
              'assets/test/2.jpg',
              'assets/test/3.jpg',
              'assets/test/4.jpg',
              'assets/test/5.jpeg',
              'assets/test/6.jpg'
            ],
            title: 'Actors',
            imageHeight: 150.0,
            imageWidth: 100.0,
          ),
        ],
      ),
    );
  }
}
