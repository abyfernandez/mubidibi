// List All Page -- for Awards and Lines

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
