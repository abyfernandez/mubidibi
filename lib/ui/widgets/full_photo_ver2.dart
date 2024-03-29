import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoT extends StatelessWidget {
  final String url;
  final String type; // path or network
  final File file;
  final String description;

  FullPhotoT({Key key, this.url, this.type, this.file, this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            title: Text('', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            elevation: 0),
        body: FullPhotoScreen(
          url: url,
          type: type,
          file: file,
          description: description,
        ));
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;
  final String type;
  final File file;
  final String description;

  FullPhotoScreen(
      {Key key, this.url, @required this.type, this.file, this.description})
      : super(key: key);

  @override
  State createState() => FullPhotoScreenState(
      url: url, type: type, file: file, description: description);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;
  final String type;
  final File file;
  final String description;

  bool isVisible = true;

  FullPhotoScreenState(
      {Key key, this.url, @required this.type, this.file, this.description});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
          child: Stack(children: [
            Container(
              child: PhotoView(
                imageProvider:
                    type == "network" ? NetworkImage(url) : FileImage(file),
                backgroundDecoration: BoxDecoration(color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
                maintainInteractivity: true,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: isVisible,
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0.0, 0.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.all(5),
                    child: Text(
                      widget.description ?? 'No description',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: widget.description != ''
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      overflow: TextOverflow.clip,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            ),
          ]),
          onTap: () {
            setState(() {
              isVisible = !isVisible;
            });
          }),
    );
  }
}
