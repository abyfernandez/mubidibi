import 'package:flutter/material.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';

class HomeView extends StatefulWidget {
  HomeView({Key key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  int _selectedIndex = 0;

  void _onItemTapped(int index) async {
    if (_selectedIndex == 0 && index == 0) {
      // await _navigationService.navigateTo(HomeViewRoute);
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

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text("Mubidibi",
            style: TextStyle(color: Colors.white, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text("Movies Dashboard here.")),
      backgroundColor: Colors.black,
      endDrawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black, //desired color
        ),
        child: Container(
          color: Colors.black,
          height: double.infinity,
          width: double.infinity,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                SizedBox(height: 35),
                IconButton(
                  color: Colors.white,
                  alignment: Alignment(-1, -1),
                  padding: EdgeInsets.only(left: 20),
                  iconSize: 20,
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    _navigationService.pop();
                  },
                ),
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    // color: Theme.of(context).primaryColor,
                    color: Color.fromRGBO(20, 20, 20, 1),
                  ),
                  margin: EdgeInsets.only(bottom: 0),
                  accountName: GestureDetector(
                    child: Text(
                        (currentUser.firstName + " " + currentUser.lastName) ??
                            ' ',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    onTap: () {
                      print("View Profile");
                    },
                  ),
                  // Text(
                  //     (currentUser.firstName + " " + currentUser.lastName) ??
                  //         ' ',
                  //     style: TextStyle(color: Colors.white, fontSize: 18)),
                  accountEmail: Text(currentUser.email,
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/-cXXaVVq8nMM/AAAAAAAAAAI/AAAAAAAAAKI/_Y1WfBiSnRI/photo.jpg?sz=50',
                    ),
                    radius: 60,
                    backgroundColor: Color.fromRGBO(20, 20, 20, 1),
                  ),
                ),
                // ListTile(
                //   tileColor: Color.fromRGBO(20, 20, 20, 1),
                //   leading: Icon(
                //     Icons.account_circle_outlined,
                //     color: Colors.white,
                //     size: 25,
                //   ),
                //   title: Text(
                //     "View Profile",
                //     style: TextStyle(
                //         color: Colors.white,
                //         letterSpacing: 1.5,
                //         fontWeight: FontWeight.w300,
                //         fontSize: 18),
                //   ),
                //   onTap: () {
                //     // TO DO: create landing page for user profile
                //     // TO DO: make larger space for profile. add the user photo and name too
                //   },
                // ),
                // Divider(color: Colors.white, height: 1),
                SizedBox(
                  height: 50,
                ),
                ListTile(
                  tileColor: Color.fromRGBO(20, 20, 20, 1),
                  leading: Icon(
                    Icons.favorite_border_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                  title: Text(
                    "My Favorites",
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                        fontSize: 18),
                  ),
                  onTap: () {
                    // TO DO: create landing page for user's favorites
                  },
                ),
                Divider(color: Colors.white, height: 1),
                ListTile(
                  tileColor: Color.fromRGBO(20, 20, 20, 1),
                  leading: Icon(
                    Icons.toggle_off_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                  title: Text(
                    "// Switch app theme here //",
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                        fontSize: 18),
                  ),
                  onTap: () {
                    // TO DO: Switch app theme
                  },
                ),
                Divider(color: Colors.white, height: 1),
                ListTile(
                  tileColor: Color.fromRGBO(20, 20, 20, 1),
                  leading: Icon(
                    Icons.info_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                  title: Text(
                    "About Mubidibi",
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                        fontSize: 18),
                  ),
                  onTap: () {
                    // TO DO: Create page for App Info
                  },
                ),
                Divider(color: Colors.white, height: 1),
                ListTile(
                  tileColor: Color.fromRGBO(20, 20, 20, 1),
                  leading: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 25,
                  ),
                  title: Text(
                    "Sign Out",
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                        fontSize: 18),
                  ),
                  onTap: () async {
                    var response = await _dialogService.showConfirmationDialog(
                        title: "Sign Out",
                        cancelTitle: "No",
                        confirmationTitle: "Yes",
                        description: "Are you sure that you want to sign out?");
                    if (response.confirmed == true) {
                      await _authenticationService.signOut();
                      await _navigationService.navigateTo(StartUpViewRoute);
                    }
                  },
                ),
                // Container(
                //     child: Align(
                //   alignment: FractionalOffset.bottomCenter,
                //   child: Row(),
                // )),
              ],
            ),
          ),
        ),
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
    );
  }
}
