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

class HomeView extends StatefulWidget {
  HomeView({Key key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final NavigationService _navigationService = locator<NavigationService>();

  int _selectedIndex = 0;
  Future<List<Movie>> movies;
  ScrollController _scrollController;
  var index;
  Animation<double> _animation;
  AnimationController _animationController;
  IconData FABIcon = Icons.add;

  void _onItemTapped(int index) async {
    if (_selectedIndex == 0 && index == 0) {
      print("Home");
    } else if (_selectedIndex != 0 && index == 0) {
      await _navigationService.navigateTo(HomeViewRoute);
    } else if (_selectedIndex == 1 && index == 1) {
      print("Search");
    } else if (_selectedIndex != 1 && index == 1) {
      print("Search");
    } else if (_selectedIndex == 2 && index == 2) {
      print("View Profile");
    } else if (_selectedIndex != 2 && index == 2) {
      print("View Profile");
    }
    setState(() {
      _selectedIndex = index;
    });
  }

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("mubidibi",
              style: TextStyle(color: Colors.lightBlue, letterSpacing: 1.5)),
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionBubble(
          // Menu items
          items: <Bubble>[
            // Floating action menu item
            Bubble(
              title: "Movie",
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
              FABIcon = FABIcon == Icons.add ? Icons.close : Icons.add;
            })
          },

          // Floating Action button Icon color
          iconColor: Colors.white,

          // Flaoting Action button Icon
          iconData: FABIcon,
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
                      title: 'Favorites',
                      contentList: snapshot.data,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ContentList(
                      key: PageStorageKey('movies'),
                      title: 'Movies',
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
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          onTap: _onItemTapped,
          selectedFontSize: 14,
        ),
      ),
    );
  }
}

// Floating Action Button
// class MyFAB extends StatelessWidget {
//   final NavigationService _navigationService = locator<NavigationService>();

//   @override
//   Widget build(BuildContext context) {
//     return FloatingActionButton(
//       child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 35),
//       backgroundColor: Colors.blue,
//       onPressed: () async {
//         await _navigationService.navigateTo(AddMovieRoute);
//       },
//     );
//   }
// }
