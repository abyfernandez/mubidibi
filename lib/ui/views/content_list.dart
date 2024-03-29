import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/see_all_view.dart';

class ContentList extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final List<Crew> crew;
  final String seeAll;
  final String type;
  final String filter;
  final bool showFilter;

  const ContentList({
    Key key,
    this.title,
    this.movies,
    this.crew,
    this.seeAll,
    @required this.type,
    this.filter,
    this.showFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.clip,
                      softWrap: true,
                    ),
                  ),
                ),
                type == "movies" || type == "favorites"
                    ? movies.length >= 4
                        ? Flexible(
                            child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      type == "movies" || type == "favorites"
                                          ? SeeAllView(
                                              type: type,
                                              filter: filter,
                                              title: type == "movies"
                                                  ? 'Mga Pelikula'
                                                  : 'Mga Favorite',
                                              showFilter: true,
                                            )
                                          : SeeAllView(
                                              type: type,
                                              filter: filter,
                                              title: 'Mga Personalidad',
                                              showFilter: true),
                                ),
                              );
                            },
                            child: Container(
                              child: Text(
                                seeAll,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.blue,
                                ),
                                overflow: TextOverflow.clip,
                                softWrap: true,
                              ),
                            ),
                          ))
                        : SizedBox()
                    : crew.length >= 4
                        ? Flexible(
                            child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      type == "movies" || type == "favorites"
                                          ? SeeAllView(
                                              type: type,
                                              filter: filter,
                                              title: type == "movies"
                                                  ? 'Mga Pelikula'
                                                  : 'Mga Favorite',
                                              showFilter: true,
                                            )
                                          : SeeAllView(
                                              type: type,
                                              filter: filter,
                                              title: 'Mga Personalidad',
                                              showFilter: true,
                                            ),
                                ),
                              );
                            },
                            child: Container(
                              child: Text(
                                seeAll,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.blue,
                                ),
                                overflow: TextOverflow.clip,
                                softWrap: true,
                              ),
                            ),
                          ))
                        : SizedBox(),
              ],
            ),
          ),
          type == 'movies' || type == "favorites"
              ? Container(
                  height: 220.0,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: movies.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Movie content = movies[index];
                      return GestureDetector(
                        // Show Movie Details
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieView(movieId: movies[index].movieId),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              height: 200.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    offset: Offset(0.0, 0.0),
                                    blurRadius: 0.0, // 2
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  content.title +
                                      (content.releaseDate != "" &&
                                              content.releaseDate != null
                                          ? (" (" +
                                              DateFormat('y').format(
                                                  DateTime.parse(
                                                      content.releaseDate)) +
                                              ") ")
                                          : ""),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              height: 200.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    content.posters != null &&
                                            content.posters.length != 0
                                        ? content.posters[0].url
                                        : Config.imgNotFound,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  height: 220.0,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: crew.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Crew content = crew[index];
                      return GestureDetector(
                        // Show Crew Details
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CrewView(crewId: crew[index].crewId),
                            ),
                          )
                        },
                        child: Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              height: 200.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    offset: Offset(0.0, 0.0),
                                    blurRadius: 0.0, // 2
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                content.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              height: 200.0,
                              width: 130.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                image: DecorationImage(
                                  alignment: Alignment.topCenter,
                                  image: CachedNetworkImageProvider(
                                    content.displayPic != null
                                        ? content.displayPic.url
                                        : Config.userNotFound,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 9,
                              right: 9,
                              child: Container(
                                padding: EdgeInsets.all(5),
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  content.name,
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
                                      blurRadius: 0.0, // 6
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
