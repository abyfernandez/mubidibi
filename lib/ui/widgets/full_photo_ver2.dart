import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoT extends StatelessWidget {
  final String url;
  final String type;
  final File file;

  FullPhotoT({Key key, this.url, this.type, this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            title: Text('', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            elevation: 0),
        body: FullPhotoScreen(url: url, type: type, file: file));
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;
  final String type;
  final File file;

  FullPhotoScreen({Key key, this.url, @required this.type, this.file})
      : super(key: key);

  @override
  State createState() => FullPhotoScreenState(url: url, type: type, file: file);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;
  final String type;
  final File file;

  FullPhotoScreenState({Key key, this.url, @required this.type, this.file});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
      imageProvider: type == "network" ? NetworkImage(url) : FileImage(file),
      backgroundDecoration: BoxDecoration(color: Colors.white),
    ));
  }
}
