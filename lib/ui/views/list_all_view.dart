// List All Page -- for Awards and Lines

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/widgets/content_header.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;

class ListAllView extends StatefulWidget {
  final List items;
  final String type;

  ListAllView({
    Key key,
    this.items,
    this.type,
  }) : super(key: key);

  @override
  _ListAllViewState createState() => _ListAllViewState(items, type);
}

class _ListAllViewState extends State<ListAllView> {
  final List items;
  final String type;

  _ListAllViewState(this.items, this.type);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        title: Text(type == "award" ? "Mga Award" : "Mga Sumikat na Linya"),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: double.infinity,
            // color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                type == "award"
                    ? items.length != 0
                        ? Container(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(10),
                            color: Colors.white,
                            alignment: Alignment.topLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items.map((award) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        new Icon(Icons.fiber_manual_record,
                                            size: 16),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text(
                                              award.name +
                                                  (award.year != null
                                                      ? " (" + award.year + ") "
                                                      : ""),
                                              style: TextStyle(fontSize: 16),
                                              softWrap: true,
                                              overflow: TextOverflow.clip),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: award.type != null
                                          ? Text(
                                              " - " +
                                                  (award.type == "nominated"
                                                      ? "Nominado"
                                                      : "Panalo"),
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 16),
                                              softWrap: true,
                                              overflow: TextOverflow.clip)
                                          : SizedBox(),
                                    ),
                                    SizedBox(height: 10)
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        : SizedBox()
                    : items.length != 0
                        ? Container(
                            margin: EdgeInsets.all(10),
                            padding: EdgeInsets.all(10),
                            color: Colors.white,
                            alignment: Alignment.topLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items.map((f) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        new Icon(Icons.fiber_manual_record,
                                            size: 16),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text('"' + f.line + '"',
                                              style: TextStyle(fontSize: 16),
                                              softWrap: true,
                                              overflow: TextOverflow.clip),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: f.role != null
                                          ? Text(" - " + f.role,
                                              style: TextStyle(
                                                  color: Colors.black45,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 16),
                                              softWrap: true,
                                              overflow: TextOverflow.clip)
                                          : SizedBox(),
                                    ),
                                    SizedBox(height: 10)
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
