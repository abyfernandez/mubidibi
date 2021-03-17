import 'package:flutter/material.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/ui/widgets/circular_clipper.dart';
import 'package:mubidibi/ui/widgets/content_scroll.dart';

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
      backgroundColor: Colors.black,
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                transform: Matrix4.translationValues(0.0, -50.0, 0.0),
                child: Hero(
                  tag: widget.movie.poster,
                  // child: ClipShadowPath(
                  //   clipper: CircularClipper(),
                  //   shadow: Shadow(blurRadius: 20.0),
                  child: Image(
                    height: 600.0,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    image: NetworkImage(widget.movie.poster),
                  ),
                  // ),
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
                  // Image(
                  //   image: NetworkImage(widget.movie.poster),
                  //   height: 60.0,
                  //   width: 150.0,
                  // ),
                  IconButton(
                    padding: EdgeInsets.only(left: 30.0),
                    onPressed: () => print('Add to Favorites'),
                    icon: Icon(Icons.favorite_border),
                    iconSize: 30.0,
                    color: Colors.white,
                  ),
                ],
              ),
              // Positioned.fill(
              //   bottom: 10.0,
              //   child: Align(
              //     alignment: Alignment.bottomCenter,
              //     child: RawMaterialButton(
              //       padding: EdgeInsets.all(10.0),
              //       elevation: 12.0,
              //       onPressed: () => print('Play Video'),
              //       shape: CircleBorder(),
              //       fillColor: Colors.white,
              //       child: Icon(
              //         Icons.play_arrow,
              //         size: 60.0,
              //         color: Colors.red,
              //       ),
              //     ),
              //   ),
              // ),
              Positioned(
                bottom: 0.0,
                left: 20.0,
                child: IconButton(
                  onPressed: () => print('Add to My List'),
                  icon: Icon(Icons.add),
                  iconSize: 40.0,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0.0,
                right: 25.0,
                child: IconButton(
                  onPressed: () => print('Share'),
                  icon: Icon(Icons.share),
                  iconSize: 35.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.movie.title.toUpperCase(),
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0),
                Text(
                  widget.movie.genre[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 12.0),
                Text(
                  '⭐ ⭐ ⭐ ⭐',
                  style: TextStyle(fontSize: 25.0),
                ),
                SizedBox(height: 15.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          'Year',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        // Text(
                        //   DateFormat("y").format(widget.movie.releaseDate),
                        //   style: TextStyle(
                        //     fontSize: 20.0,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Country',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        // Text(
                        //   widget.movie.country.toUpperCase(),
                        //   style: TextStyle(
                        //     fontSize: 20.0,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Length',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        // Text(
                        //   '${widget.movie.length} min',
                        //   style: TextStyle(
                        //     fontSize: 20.0,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 25.0),
                Container(
                  height: 120.0,
                  child: SingleChildScrollView(
                    child: Text(
                      widget.movie.synopsis,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
