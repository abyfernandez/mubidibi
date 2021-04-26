import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/my_drawer.dart';
import 'package:mubidibi/ui/views/search_view.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';

class HomeView extends StatefulWidget {
  HomeView({Key key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DialogService _dialogService = locator<DialogService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pageIndex = 0;

  // Initialize Pages
  final SearchView _searchView = SearchView();
  final DashboardView _dashboardView = DashboardView();

  Widget _showPage = DashboardView();

  Widget _pageChooser(int page) {
    switch (page) {
      case 0:
        return DashboardView();
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

  // TO DO: When drawer is open and home button is clicked, the page must return to the dashboard

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      key: _scaffoldKey,
      body: Center(child: _showPage),
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
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
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
