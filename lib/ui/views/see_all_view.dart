// See All Page

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/movie_view.dart';

class SeeAllView extends StatelessWidget {
  final List<Movie> movies;
  // TO DO: photos and crew

  const SeeAllView({Key key, this.movies}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        title: Text("See All"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            Wrap(
              children: movies.length != 0
                  ? movies
                      .map(
                        (movie) => GestureDetector(
                          child: Container(
                            height: 210.0,
                            child: Stack(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  height: 200.0,
                                  width: 120.0,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black54,
                                        offset: Offset(0.0, 0.0),
                                        blurRadius: 2.0,
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    movie.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  height: 200.0,
                                  width: 120.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        movie.poster != null
                                            ? movie.poster
                                            : Config.imgNotFound,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieView(movie: movie),
                                ));
                          },
                        ),
                      )
                      .toList()
                  : Center(
                      child: Text("No movies found."),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
