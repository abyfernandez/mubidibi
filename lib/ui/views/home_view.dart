import 'package:flutter/material.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/widgets/custom_app_bar.dart';
import 'package:mubidibi/ui/views/my_drawer.dart';
import 'package:mubidibi/ui/widgets/content_header.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'dart:math';

class HomeView extends StatefulWidget {
  HomeView({Key key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final NavigationService _navigationService = locator<NavigationService>();

  int _selectedIndex = 0;
  List<dynamic?> movies = [];
  ScrollController _scrollController;

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
    print("MOVIES: $movies");
    final Size screenSize = MediaQuery.of(context).size;

    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: Size(screenSize.width, 200.0),
            child: CustomAppBar(scrollOffset: 0.0)),

        // AppBar(
        //   title: Text("mubidibi",
        //       style: TextStyle(color: Colors.red, letterSpacing: 1.5)),
        //   backgroundColor: Colors.black,
        //   iconTheme: IconThemeData(color: Colors.white),
        //   automaticallyImplyLeading: false,
        // ),
        floatingActionButton: MyFAB(),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: ContentHeader(featuredContent: movies[0]),
            ),
            // SliverPadding(
            //   padding: const EdgeInsets.only(top: 20.0),
            //   sliver: SliverToBoxAdapter(
            //     child: Previews(
            //       key: PageStorageKey('previews'),
            //       title: 'Previews',
            //       contentList: previews,
            //     ),
            //   ),
            // ),
            // SliverToBoxAdapter(
            //   child: ContentList(
            //     key: PageStorageKey('myList'),
            //     title: 'My List',
            //     contentList: myList,
            //   ),
            // ),
            // SliverToBoxAdapter(
            //   child: ContentList(
            //     key: PageStorageKey('originals'),
            //     title: 'Netflix Originals',
            //     contentList: originals,
            //     isOriginals: true,
            //   ),
            // ),
            // SliverPadding(
            //   padding: const EdgeInsets.only(bottom: 20.0),
            //   sliver: SliverToBoxAdapter(
            //     child: ContentList(
            //       key: PageStorageKey('trending'),
            //       title: 'Trending',
            //       contentList: trending,
            //     ),
            //   ),
            // )
          ],
        ),
        backgroundColor: Colors.black,
        endDrawer: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.black, //desired color
          ),
          child: MyDrawer(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color.fromRGBO(5, 5, 5, 1),
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
          selectedItemColor: Colors.white,
          unselectedItemColor: Color.fromRGBO(169, 169, 169, 1),
          onTap: _onItemTapped,
          selectedFontSize: 14,
        ),
      ),
    );
  }
}

class MyFAB extends StatelessWidget {
  final NavigationService _navigationService = locator<NavigationService>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add, color: Colors.black, size: 30),
      backgroundColor: Colors.red,
      onPressed: () async {
        await _navigationService.navigateTo(AddMovieRoute);
      },
    );
  }
}
