import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/my_drawer.dart';
import 'package:mubidibi/ui/views/search_view.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/see_all_view.dart';

class HomeView extends StatefulWidget {
  HomeView({Key key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DialogService _dialogService = locator<DialogService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pageIndex = 0;
  List<DropdownMenuItem> genreItems = [];
  List<dynamic> genres = [];
  String sortBy = "";
  Widget _showPage;
  ValueNotifier<String> filterBy = ValueNotifier<String>(null);

  // Initialize Pages
  final SearchView _searchView = SearchView();

  Widget _pageChooser(int page) {
    switch (page) {
      case 0:
        return new DashboardView(
            filter: filterBy.value == null || filterBy.value == ""
                ? null
                : filterBy.value);
        break;
      case 1:
        return _searchView;
        break;
      case 2:
        return Container();
        break;
      default:
        return Container(
          child: Center(
            child: Text('No page found.'),
          ),
        );
    }
  }

  // Function: FETCH GENRES
  List<String> genreFromJson(String str) =>
      List<String>.from(json.decode(str).map((x) => x['genre']));

  // fetch genre from API
  void fetchGenres() async {
    final response = await http.get(Config.api + 'genres/');

    if (response.statusCode == 200) {
      // map json to Genre type
      genres = genreFromJson(response.body);

      genreItems = genres.map<DropdownMenuItem<String>>((dynamic value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList();

      setState(() {});
    }
  }

  @override
  void initState() {
    fetchGenres();
    _showPage = DashboardView(
        filter: filterBy.value == null || filterBy.value == ""
            ? null
            : filterBy.value);

    super.initState();
  }

  // TO DO: When drawer is open and home button is clicked, the page must return to the dashboard

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    if (genreItems == null) return CircularProgressIndicator();
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      body: Center(child: _showPage),
      extendBodyBehindAppBar: pageIndex == 0 ? true : false,
      // TO DO: Show dialog box on back press
      // WillPopScope(
      //   onWillPop: pageIndex == 0 && !isDrawerOpen
      //       ? onBackPress
      //       : () => Future.value(false),
      //   child: Container(
      //     color: Colors.white,
      //     child: Center(
      //       child: _showPage,
      //     ),
      //   ),
      // ),
      appBar: pageIndex == 0
          ? AppBar(
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
                    icon: null,
                    iconEnabledColor: Colors.white,
                    // TO DO: see if may mas ok na solution for this, also check if walang overflow sa ibang device
                    hint: Text(
                      "               Categories",
                      style: TextStyle(color: Colors.white),
                    ),
                    items: genreItems,
                    onChanged: (val) {
                      filterBy.value = val;
                      setState(() {
                        sortBy = val;
                        _showPage = _pageChooser(pageIndex);
                      });

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => SeeAllView(
                                  movies: null,
                                  type: "movies",
                                  title: filterBy.value,
                                  filter: filterBy.value)));
                    },
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
            )
          : null,
      backgroundColor: Colors.white,
      endDrawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white, //desired color
        ),
        child: MyDrawer(),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            label: 'Search',
          ),
        ],
        currentIndex: pageIndex,
        selectedItemColor: Colors.lightBlue,
        onTap: (index) {
          setState(() {
            pageIndex = index;
            _showPage = _pageChooser(index);
          });
        },
        selectedFontSize: 14,
      ),
    );
  }

  Future<bool> onBackPress() async {
    var dialogResponse = await _dialogService.showConfirmationDialog(
        title: "Exit App",
        description: "Are you sure you want to exit the app?",
        confirmationTitle: 'Yes',
        cancelTitle: 'No');
    if (dialogResponse.confirmed) {
      exit(0);
    }
    return Future.value(false);
  }
}
