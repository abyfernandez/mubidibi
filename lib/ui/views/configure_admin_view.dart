// ADD AND REMOVE ADMINS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mubidibi/models/user.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/viewmodels/user_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

class ConfigureAdminView extends StatefulWidget {
  ConfigureAdminView({Key key}) : super(key: key);

  @override
  _ConfigureAdminViewState createState() => _ConfigureAdminViewState();
}

class _ConfigureAdminViewState extends State<ConfigureAdminView> {
  var currentUser;
  bool _saving = false;
  List<User> users = [];
  List<int> changed =
      []; // records ids of users whose isAdmin status has been modified by the admin

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  void fetchUsers() async {
    var model = UserViewModel();
    users = await model.getUsers(userId: currentUser.userId);
    setState(() {
      changed = [];
      users = users;
    });
  }

  @override
  void initState() {
    currentUser = _authenticationService.currentUser;
    fetchUsers();
    initializeDateFormatting();
    tz.initializeTimeZones();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (users.length == 0) return Center(child: CircularProgressIndicator());

    return ViewModelProvider<UserViewModel>.withConsumer(
      viewModel: UserViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Mga Admin'),
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        body: ModalProgressHUD(
            inAsyncCall: _saving,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          child: Text(
                              'Lagyan ng check ang mga nais mong maging admin.',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey)),
                        ),
                        ListView.builder(
                          physics: BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (context, i) {
                            return Container(
                              color: Colors.white,
                              margin: EdgeInsets.only(bottom: 5),
                              child: ExpansionTile(
                                tilePadding:
                                    EdgeInsets.symmetric(horizontal: 10),
                                expandedAlignment: Alignment.centerLeft,
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                title: CheckboxListTile(
                                    activeColor: Colors.lightBlue,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    value: users[i].isAdmin,
                                    onChanged: (bool newVal) {
                                      setState(() {
                                        users[i].isAdmin = newVal;
                                        // save index of modified tile
                                        if (changed.contains(i) == false) {
                                          changed.add(i);
                                        }
                                      });
                                    },
                                    title: Text(users[i].firstName +
                                        (users[i].middleName != null
                                            ? " " + users[i].middleName
                                            : "") +
                                        (users[i].lastName != null
                                            ? " " + users[i].lastName
                                            : "") +
                                        (users[i].suffix != null
                                            ? " " + users[i].suffix
                                            : ""))),
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        top: 0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.cake_outlined),
                                            SizedBox(width: 10),
                                            Text(
                                              users[i].birthday != null &&
                                                      users[i]
                                                              .birthday
                                                              .trim() !=
                                                          ''
                                                  ? DateFormat(
                                                          "MMM. d, y", "fil")
                                                      .format(TZDateTime.from(
                                                          DateTime.parse(
                                                              users[i]
                                                                  .birthday),
                                                          tz.getLocation(
                                                              'Asia/Manila')))
                                                  : '-',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined),
                                            SizedBox(width: 10),
                                            Text(users[i].email),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                childrenPadding:
                                    EdgeInsets.only(left: 55, right: 10),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        Container(
                            padding: EdgeInsets.only(right: 10),
                            alignment: Alignment.centerRight,
                            child: FlatButton(
                                color: Colors.lightBlue,
                                onPressed: () async {
                                  // save values
                                  // will send the list of users as well as the list of indexes to be updated
                                  _saving =
                                      true; // set saving to true to trigger circular progress indicator

                                  var res = await model.updateAdmins(
                                      users: users, changed: changed);

                                  if (res == true) {
                                    _saving =
                                        false; // set saving to false to trigger circular progress indicator

                                    _scaffoldKey.currentState.showSnackBar(
                                        mySnackBar(
                                            context,
                                            'Users updated successfully.',
                                            Colors.green));

                                    Timer(const Duration(milliseconds: 2000),
                                        () {
                                      fetchUsers();

                                      // Navigator.pushReplacement(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) =>
                                      //         ConfigureAdminView(),
                                      //   ),
                                      // );
                                    });
                                  } else {
                                    _saving =
                                        false; // set saving to false to trigger circular progress indicator
                                    _scaffoldKey.currentState.showSnackBar(
                                        mySnackBar(
                                            context,
                                            'Error updating users.',
                                            Colors.red));

                                    Timer(const Duration(milliseconds: 2000),
                                        () {
                                      fetchUsers();
                                      // Navigator.pushReplacement(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) =>
                                      //         ConfigureAdminView(),
                                      //   ),
                                      // );
                                    });
                                  }
                                },
                                child: Text('Save',
                                    style: TextStyle(color: Colors.white))))
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}
