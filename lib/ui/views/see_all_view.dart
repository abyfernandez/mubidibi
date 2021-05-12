// See All Page

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';

class SeeAllView extends StatelessWidget {
  final List<Movie> movies;
  final List<Crew> crew;
  final List<String> photos;
  final List<String> screenshots;
  final String type;
  // TO DO: photos and crew

  const SeeAllView(
      {Key key,
      this.movies,
      this.crew,
      this.photos,
      this.screenshots,
      this.type})
      : super(key: key);

  Widget showTitle() {
    switch (type) {
      case "movies":
        return Text("Mga Pelikula");
        break;
      case "crew":
        return Text('Mga Personalidad');
        break;
      case "photos":
        return Text("Mga Litrato");
        break;
      case "screenshots":
        return Text("Mga Screenshot");
        break;
    }
    return null;
  }

  Widget showContent(context) {
    print(type);
    switch (type) {
      case "movies":
        return SingleChildScrollView(
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
                                    builder: (_) => MovieView(
                                        movieId: movie.movieId.toString()),
                                  ));
                            },
                          ),
                        )
                        .toList()
                    : Center(
                        child: Text("No content found."),
                      ),
              ),
            ],
          ),
        );
        break;
      case "crew":
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              Wrap(
                children: crew.length != 0
                    ? crew
                        .map(
                          (crew) => GestureDetector(
                            child: Container(
                              height: 210.0,
                              child: Stack(
                                children: [
                                  // Container(
                                  //   alignment: Alignment.center,
                                  //   margin: const EdgeInsets.symmetric(
                                  //       horizontal: 8.0),
                                  //   height: 200.0,
                                  //   width: 120.0,
                                  //   decoration: BoxDecoration(
                                  //     boxShadow: [
                                  //       BoxShadow(
                                  //         color: Colors.black54,
                                  //         offset: Offset(0.0, 0.0),
                                  //         blurRadius: 2.0,
                                  //       ),
                                  //     ],
                                  //     borderRadius: BorderRadius.circular(5),
                                  //   ),
                                  //   child: Text(
                                  //     crew.firstName +
                                  //         (crew.middleName != null
                                  //             ? " " + crew.middleName
                                  //             : "") +
                                  //         " " +
                                  //         crew.lastName +
                                  //         (crew.suffix != null
                                  //             ? " " + crew.suffix
                                  //             : ""),
                                  //     textAlign: TextAlign.center,
                                  //     style: TextStyle(
                                  //       color: Colors.white,
                                  //       fontSize: 14,
                                  //       fontWeight: FontWeight.bold,
                                  //     ),
                                  //   ),
                                  // ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    height: 200.0,
                                    width: 120.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          crew.displayPic != null
                                              ? crew.displayPic
                                              : Config.userNotFound,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 9,
                                    left: 9,
                                    right: 9,
                                    child: Container(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        crew.firstName +
                                            " " +
                                            (crew.middleName != null
                                                ? " " + crew.middleName
                                                : "") +
                                            " " +
                                            crew.lastName +
                                            (crew.suffix != null
                                                ? " " + crew.suffix
                                                : ""),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black54,
                                            offset: Offset(0.0, 0.0),
                                            blurRadius: 4.0, // 6
                                          ),
                                        ],
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
                                    builder: (_) => CrewView(
                                        crewId: crew.crewId.toString()),
                                  ));
                            },
                          ),
                        )
                        .toList()
                    : Center(
                        child: Text("No content found."),
                      ),
              ),
            ],
          ),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          title: showTitle(),
        ),
        body: showContent(context));
  }
}
