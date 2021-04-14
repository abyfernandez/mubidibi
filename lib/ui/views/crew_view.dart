import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import 'package:mubidibi/globals.dart' as Config;

import 'full_photo.dart';

class CrewView extends StatefulWidget {
  final Crew crew;
  final List<List<Crew>> crewEdit;

  CrewView({this.crew, this.crewEdit});

  @override
  _CrewViewState createState() => _CrewViewState(crew, crewEdit);
}

class _CrewViewState extends State<CrewView>
    with SingleTickerProviderStateMixin {
  final Crew crew;
  final List<List<Crew>> crewEdit;

  _CrewViewState(this.crew, this.crewEdit);

  List<String> roles = [];

  @override
  void initState() {
    // TODO: implement initState
    for (var i = 0; i < crewEdit.length; i++) {
      for (var type in crewEdit[i]) {
        if (crew.crewId == type.crewId) {
          switch (i) {
            case 0:
              roles.add('Direktor');
              break;
            case 1:
              roles.add('Manunulat');
              break;
            case 2:
              roles.add('Aktor');
              break;
          }
        }
      }
    }
    super.initState();
  }

  Widget displayRoles() {
    return Wrap(
        children: roles.map((role) {
      return Container(
          margin: EdgeInsets.only(right: 5),
          child: Chip(
            labelPadding: EdgeInsets.only(left: 2, right: 2),
            label: Text(role, style: TextStyle(fontSize: 12)),
            backgroundColor: Color.fromRGBO(176, 224, 230, 1),
          ));
    }).toList());
  }

  Widget displayPhotos() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: crew.photos.map((pic) {
        return Container(
          height: 250,
          width: 230,
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(5), boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 7,
            )
          ]),
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FullPhoto(url: pic ?? Config.imgNotFound),
                  ),
                );
              },
              child: Image.network(
                pic,
                height: 250,
                width: 230,
                alignment: Alignment.topCenter,
                fit: BoxFit.cover,
              )),
        );
      }).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);

    return ViewModelProvider.withConsumer(
      viewModel: CrewViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          // centerTitle: true,
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          // title: Text(
          //   crew.firstName +
          //       ' ' +
          //       (crew.middleName != null
          //           ? (crew.middleName + ' ' + crew.lastName)
          //           : crew.lastName),
          //   style: TextStyle(
          //       fontSize: 20,
          //       fontFamily: 'Poppins',
          //       fontWeight: FontWeight.bold),
          // ),
        ),
        body: ListView(
          children: <Widget>[
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GestureDetector(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: Container(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Material(
                          child: Image.network(
                            Config.userNotFound,
                            height: 200,
                            width: 150,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        imageUrl: widget.crew.displayPic ?? Config.userNotFound,
                        width: 150,
                        height: 200,
                        alignment: Alignment.center,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullPhoto(
                              url: widget.crew.displayPic ??
                                  Config.userNotFound),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 200,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        crew.firstName +
                            ' ' +
                            (crew.middleName != null
                                ? (crew.middleName + ' ' + crew.lastName)
                                : crew.lastName) +
                            (crew.suffix != null ? ' ' + crew.suffix : ''),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 25,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      // display( roles (crew types)
                      displayRoles()
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                          "Birthdate:   " +
                              (crew.birthday != null
                                  ? DateFormat('MMMM d, y')
                                      .format(DateTime.parse(crew.birthday))
                                  : '-'),
                          style: TextStyle(fontSize: 16)),
                      Text(crew.isAlive == false ? ' (Pumanaw na)' : '',
                          style: TextStyle(
                              fontSize: 16, fontStyle: FontStyle.italic))
                    ],
                  ),
                  Text(
                      "Birthplace:   " +
                          (crew.birthplace != null ? crew.birthplace : '-'),
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  crew.description != null
                      ? Text(crew.description, style: TextStyle(fontSize: 16))
                      : Center(
                          child: Text(
                            'No decription found.',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Photos",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        child: Text('See All',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        onTap: () {},
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  displayPhotos()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
