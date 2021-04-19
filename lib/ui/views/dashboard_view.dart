import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/views/my_drawer.dart';
import 'package:mubidibi/ui/widgets/content_header.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/ui/views/content_list.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';

class DashboardView extends StatefulWidget {
  DashboardView({Key key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  final NavigationService _navigationService = locator<NavigationService>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<List<Movie>> movies;
  ScrollController _scrollController;
  var index;
  Animation<double> _animation;
  AnimationController _animationController;
  IconData fabIcon = Icons.add;

  List<DropdownMenuItem> _categories = [
    DropdownMenuItem<String>(
      value: "Romance",
      child: Text("Romance"),
    ),
    DropdownMenuItem<String>(
      value: "Comedy",
      child: Text("Comedy"),
    ),
    DropdownMenuItem<String>(
      value: "Horror",
      child: Text("Horror"),
    )
  ];

  // function for calling viewmodel's getAllCrew method
  Future<List<Movie>> fetchMovies() async {
    var model = MovieViewModel();
    return model.getAllMovies();
  }

  @override
  void initState() {
    movies = fetchMovies();
    movies.then((m) {
      var rand = new Random();
      index = rand.nextInt(m.length);
    });

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
    final Size screenSize = MediaQuery.of(context).size;
    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("mubidibi",
              style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors
              .black, // can be changed to transparent but decreases visibility
          iconTheme: IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false,
          actions: [
            Container(
              margin: EdgeInsets.only(left: 10, right: 10, top: 5),
              child: DropdownButton<dynamic>(
                hint: Text(
                  "Categories",
                  style: TextStyle(color: Colors.white),
                ),
                items: _categories,
                onChanged: (_) {},
                underline: Container(),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10, right: 10),
              child: GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState.openEndDrawer();
                },
                child: Icon(Icons.menu),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionBubble(
          // Menu items
          items: <Bubble>[
            // Floating action menu item
            Bubble(
              title: "Pelikula",
              iconColor: Colors.white,
              bubbleColor: Colors.lightBlue,
              icon: Icons.add,
              titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              onPress: () async {
                await _navigationService.navigateTo(AddMovieRoute);
                _animationController.reverse();
              },
            ),
            //Floating action menu item
            Bubble(
              title: "Crew",
              iconColor: Colors.white,
              bubbleColor: Colors.lightBlue,
              icon: Icons.add,
              titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              onPress: () async {
                _animationController.reverse();
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
            setState(() {
              fabIcon = fabIcon == Icons.add ? Icons.close : Icons.add;
            })
          },

          // Floating Action button Icon color
          iconColor: Colors.white,

          // Floating Action button Icon
          iconData: fabIcon,
          backGroundColor: Colors.lightBlue,
        ),
        body: FutureBuilder(
          future: movies,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: ContentHeader(featuredContent: snapshot.data[index]),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 10),
                  ),
                  SliverToBoxAdapter(
                    child: ContentList(
                      key: PageStorageKey('myFavorites'),
                      title: 'Mga Favorite',
                      contentList: snapshot.data,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ContentList(
                      key: PageStorageKey('movies'),
                      title: 'Mga Pelikula',
                      contentList: snapshot.data,
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        backgroundColor: Colors.white,
        endDrawer: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, //desired color
          ),
          child: MyDrawer(),
        ),
      ),
    );
  }
}
