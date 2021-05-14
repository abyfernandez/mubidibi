import 'package:flutter/material.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/home_view.dart';
import 'package:mubidibi/ui/views/startup_view.dart';

// TO DO: hide the bottom sheet when drawer is opened

class MyDrawer extends StatelessWidget {
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(
              // color: Colors.black, //change your color here
              ),
        ),
        body: Container(
          color: Colors.white,
          height: double.infinity,
          width: double.infinity,
          child: Drawer(
            elevation: 20,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                currentUser != null
                    ? UserAccountsDrawerHeader(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(240, 240, 240, 1),
                        ),
                        margin: EdgeInsets.only(bottom: 0),
                        accountName: GestureDetector(
                          child: Text(
                              currentUser.firstName +
                                  (currentUser.middleName != null
                                      ? " " + currentUser.middleName
                                      : "") +
                                  (currentUser.lastName != null
                                      ? " " + currentUser.lastName
                                      : "") +
                                  (currentUser.suffix != null
                                      ? " " + currentUser.suffix
                                      : ""),
                              style: TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.underline)),
                          onTap: () {
                            print("View Profile");
                          },
                        ),
                        accountEmail: Text(
                          currentUser.email,
                          style: TextStyle(
                            // color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: NetworkImage(Config.userNotFound),
                          radius: 60,
                        ),
                      )
                    : SizedBox(),
                Divider(color: Color.fromRGBO(20, 20, 20, 1), height: 1),
                ListTile(
                  leading: Icon(
                    Icons.info_outlined,
                    size: 20,
                  ),
                  title: Text(
                    "About Mubidibi",
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
                  ),
                  onTap: () {
                    // TO DO: Create page for App Info
                  },
                ),
                Divider(color: Color.fromRGBO(20, 20, 20, 1), height: 1),
                currentUser != null
                    ? ListTile(
                        leading: Icon(
                          Icons.logout,
                          size: 20,
                        ),
                        title: Text(
                          "Sign Out",
                          style: TextStyle(
                              fontWeight: FontWeight.w300, fontSize: 16),
                        ),
                        onTap: () async {
                          var response =
                              await _dialogService.showConfirmationDialog(
                                  title: "Sign Out",
                                  cancelTitle: "No",
                                  confirmationTitle: "Yes",
                                  description:
                                      "Are you sure that you want to sign out?");
                          if (response.confirmed == true) {
                            await _authenticationService.signOut();
                            await _navigationService
                                .navigateTo(StartUpViewRoute);
                          }
                        },
                      )
                    : ListTile(
                        leading: Icon(
                          currentUser != null ? Icons.logout : Icons.login,
                          size: 20,
                        ),
                        title: Text(
                          "Sign In",
                          style: TextStyle(
                              fontWeight: FontWeight.w300, fontSize: 16),
                        ),
                        onTap: () {
                          _navigationService.navigateTo(LoginViewRoute);
                        },
                      ),
                Divider(color: Color.fromRGBO(20, 20, 20, 1), height: 1),
              ],
            ),
          ),
        ));
  }
}
