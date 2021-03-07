import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';

final AuthenticationService _authenticationService =
    locator<AuthenticationService>();
final NavigationService _navigationService = locator<NavigationService>();
final DialogService _dialogService = locator<DialogService>();

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              accountName: Text(currentUser.displayName ?? ' ',
                  style: TextStyle(color: Colors.white)),
              accountEmail: Text(currentUser.email ?? ' ',
                  style: TextStyle(color: Colors.white)),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(
                  currentUser.photoUrl ??
                      'https://lh3.googleusercontent.com/-cXXaVVq8nMM/AAAAAAAAAAI/AAAAAAAAAKI/_Y1WfBiSnRI/photo.jpg?sz=50',
                ),
                radius: 60,
                backgroundColor: Colors.transparent,
              )),
          ListTile(
            title: Text("Profile"),
            leading: Icon(FontAwesomeIcons.user),
            onTap: () async {
              // await _authenticationService.syncUserProfile(currentUser.uid);
              // await _navigationService.navigateTo(ProfileViewRoute,
              // arguments: currentUser);
              // if (currentUser.rating < 3)
              // await _dialogService.showDialog(
              // title: "Please mind your rating",
              // description:
              // "Once you reached an average rate of less than two, the system will automatically ban you from using the application.");
            },
            trailing: Icon(FontAwesomeIcons.caretRight),
          ),
          ListTile(
            title: Text("Blacklist"),
            leading: Icon(FontAwesomeIcons.ban),
            onTap: () {
              // _navigationService.navigateTo(BlacklistViewRoute);
            },
            trailing: Icon(FontAwesomeIcons.caretRight),
          ),
          ListTile(
            title: Text("Dark mode"),
            leading: Icon(FontAwesomeIcons.moon),
            onTap: () {
              _dialogService.showDialog(
                  title: "Dark Mode",
                  description:
                      "Enabling dark mode on your device will automatically switch the app to dark theme.");
            },
            trailing: Icon(FontAwesomeIcons.caretRight),
          ),
          ListTile(
            title: Text("Sign out"),
            leading: Icon(FontAwesomeIcons.signOutAlt),
            onTap: () async {
              await _authenticationService.signOut();
              await _navigationService.navigateTo(LoginViewRoute);
            },
            trailing: Icon(FontAwesomeIcons.caretRight),
          ),
        ],
      ),
    );
  }
}
