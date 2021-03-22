import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/movie.dart';
import 'full_photo.dart';

class MovieView extends StatefulWidget {
  final Movie movie;

  MovieView({this.movie});

  @override
  _MovieViewState createState() => _MovieViewState();
}

class _MovieViewState extends State<MovieView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 400,
                decoration: new BoxDecoration(
                  image: new DecorationImage(
                    image: new NetworkImage(widget.movie.poster),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    new BackdropFilter(
                      filter: new ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                      child: new Container(
                        decoration: new BoxDecoration(
                            color: Colors.black.withOpacity(0.3)),
                      ),
                    ),
                    GestureDetector(
                      child: Center(
                        child: Image.network(
                          widget.movie.poster,
                          height: 350,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullPhoto(url: widget.movie.poster),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    padding: EdgeInsets.only(left: 30.0),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    iconSize: 30.0,
                    color: Colors.white,
                  ),
                  IconButton(
                    padding: EdgeInsets.only(right: 20.0),
                    onPressed: () => print('Add to Favorites'),
                    icon: Icon(Icons.add),
                    iconSize: 30.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    widget.movie.title.toUpperCase(),
                    style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '⭐ ⭐ ⭐ ⭐',
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Date Released", style: TextStyle(fontSize: 18)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Text(
                  DateFormat("MMMM d, y").format(
                    DateTime.parse(widget.movie.releaseDate),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Genre/s", style: TextStyle(fontSize: 18)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.movie.genre
                          .reduce((curr, next) => curr + ", " + next),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Running Time',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Text(
                  "125 mins.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Synopsis',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              widget.movie.synopsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.0,
              ),
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Actor/s", style: TextStyle(fontSize: 18)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.movie.genre
                          .reduce((curr, next) => curr + ", " + next),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Writer/s", style: TextStyle(fontSize: 18)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.movie.genre
                          .reduce((curr, next) => curr + ", " + next),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("Director/s", style: TextStyle(fontSize: 18)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 20),
                SizedBox(
                  width: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.movie.genre
                          .reduce((curr, next) => curr + ", " + next),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),

          // ContentScroll(
          //   images: widget.movie.screenshots,
          //   title: 'Screenshots',
          //   imageHeight: 200.0,
          //   imageWidth: 250.0,
          // ),
        ],
      ),
    );
  }
}
