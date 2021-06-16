import 'package:flutter/material.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/login_view.dart';

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
        shadowColor: Colors.transparent,
        leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () {
              FocusScope.of(context).unfocus();
              _navigationService.pop();
            }),
      ),
      body: WillPopScope(
        onWillPop: () {
          _navigationService.pop();
          return Future.value(false);
        },
        child: Container(
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
                        accountName: Text(
                          currentUser.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        accountEmail: Text(
                          currentUser.email,
                          style: TextStyle(
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
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                StartUpViewRoute,
                                (Route<dynamic> route) => false);
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
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      LoginView()));
                        },
                      ),
                Divider(color: Color.fromRGBO(20, 20, 20, 1), height: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
