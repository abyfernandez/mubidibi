import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/services/navigation_service.dart';
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
  final NavigationService _navigationService = locator<NavigationService>();
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

  @override
  Widget build(BuildContext context) {
    if (genreItems == null) {
      // return CircularProgressIndicator();
      return Container(
          color: Colors.white,
          height: double.infinity,
          child: Center(child: Container(child: CircularProgressIndicator())));
    }
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      extendBodyBehindAppBar: pageIndex == 0 ? true : false,
      body: WillPopScope(
        onWillPop: onBackPress,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: Colors.white,
            child: Center(
              child: _showPage,
            ),
          ),
        ),
      ),
      appBar: pageIndex == 0
          ? AppBar(
              title: Container(
                child: Text("mubidibi",
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.clip,
                    softWrap: true),
              ),
              backgroundColor: Colors.transparent,
              shadowColor: Colors
                  .transparent, // can be changed to transparent but decreases visibility
              iconTheme: IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false,
              actions: [
                Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: DropdownButton<dynamic>(
                    icon: null,
                    iconEnabledColor: Colors.white,
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
                                  showFilter: true,
                                  // title: filterBy.value,
                                  title: 'Mga Pelikula',
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
      endDrawerEnableOpenDragGesture: false,
      drawerEdgeDragWidth: 0.0,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 3,
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
    if (!_scaffoldKey.currentState.isEndDrawerOpen) {
      var dialogResponse = await _dialogService.showConfirmationDialog(
          title: "Exit App",
          description: "Are you sure you want to exit the app?",
          confirmationTitle: 'Yes',
          cancelTitle: 'No');
      if (dialogResponse.confirmed) {
        exit(0);
      }
    } else {
      _navigationService.pop();
    }
    return Future.value(false);
  }
}
