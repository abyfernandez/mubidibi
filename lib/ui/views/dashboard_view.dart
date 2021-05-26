import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/views/my_drawer.dart';
import 'package:mubidibi/ui/widgets/content_header.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/ui/views/content_list.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';

class DashboardView extends StatefulWidget {
  final String filter;

  DashboardView({Key key, this.filter}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState(filter);
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  final String filter;

  _DashboardViewState(this.filter);

  final NavigationService _navigationService = locator<NavigationService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Movie> movies;
  List<Crew> crew;
  ScrollController _movieScrollController;
  ScrollController _crewScrollController;
  var index;
  Animation<double> _animation;
  AnimationController _animationController;
  IconData fabIcon;
  var currentUser;
  bool test = false;

  // function for calling viewmodel's getAllCrew method
  void fetchMovies() async {
    var model = MovieViewModel();
    movies = await model.getAllMovies();

    if (movies != null && movies.length != 0) {
      var rand = new Random();
      index = rand.nextInt(movies.length);
    } else {
      index = 0;
    }

    setState(() {
      movies = movies;
      index = index;
    });
  }

  // function for calling viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();
    crew = await model.getAllCrew();

    setState(() {
      crew = crew;
    });
  }

  Widget crewView(BuildContext context, AsyncSnapshot snapshot) {
    var values = snapshot.data;
    if (snapshot.connectionState == ConnectionState.done) {
      return CustomScrollView(
        controller: _crewScrollController,
        slivers: [
          SliverToBoxAdapter(
            child: ContentList(
                key: PageStorageKey('crew'),
                title: 'Mga Personalidad',
                seeAll: 'Tingnan Lahat',
                type: 'crew',
                filter: filter,
                showFilter: true),
          ),
        ],
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  @override
  void initState() {
    currentUser = _authenticationService.currentUser;
    fetchMovies();
    fetchCrew();
    fabIcon = Icons.admin_panel_settings;

    print(filter);

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
    if (movies == null || crew == null || index == null) {
      return CircularProgressIndicator();
    }

    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Visibility(
          visible: currentUser != null ? currentUser.isAdmin : false,
          child: FloatingActionBubble(
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
                  _animationController.reverse();
                  await _navigationService.navigateTo(AddMovieRoute);
                  setState(() {
                    fabIcon = fabIcon == Icons.admin_panel_settings
                        ? Icons.close
                        : Icons.admin_panel_settings;
                  });
                },
              ),
              //Floating action menu item
              Bubble(
                title: "Personalidad",
                iconColor: Colors.white,
                bubbleColor: Colors.lightBlue,
                icon: Icons.add,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                onPress: () async {
                  _animationController.reverse();
                  await _navigationService.navigateTo(AddCrewRoute);
                  setState(() {
                    fabIcon = fabIcon == Icons.admin_panel_settings
                        ? Icons.close
                        : Icons.admin_panel_settings;
                  });
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
                fabIcon = fabIcon == Icons.admin_panel_settings
                    ? Icons.close
                    : Icons.admin_panel_settings;
              })
            },

            // Floating Action button Icon color
            iconColor: Colors.white,

            // Floating Action button Icon
            iconData: fabIcon,

            backGroundColor: Colors.lightBlue,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Flexible(
                flex: 4,
                child: CustomScrollView(
                  controller: _movieScrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ContentHeader(featuredContent: movies[index]),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 10),
                    ),
                    currentUser != null
                        ? SliverToBoxAdapter(
                            child: ContentList(
                              key: PageStorageKey('myFavorites'),
                              title: 'Mga Favorite',
                              seeAll: 'Tingnan Lahat',
                              movies: movies,
                              type: 'favorites',
                              filter: filter,
                              showFilter: true,
                            ),
                          )
                        : SliverToBoxAdapter(),
                    SliverToBoxAdapter(
                      child: ContentList(
                        key: PageStorageKey('movies'),
                        title: 'Mga Pelikula',
                        seeAll: 'Tingnan Lahat',
                        movies: movies,
                        type: 'movies',
                        filter: filter,
                        showFilter: true,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ContentList(
                        key: PageStorageKey('crew'),
                        title: 'Mga Personalidad',
                        seeAll: 'Tingnan Lahat',
                        crew: crew,
                        type: 'crew',
                        filter: filter,
                        showFilter: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
