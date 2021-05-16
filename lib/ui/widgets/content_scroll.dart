import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/see_all_view.dart';

class ContentScroll extends StatelessWidget {
  final List<List<Crew>> crewEdit;
  final List<Crew> crew;
  final String title;
  final double imageHeight;
  final double imageWidth;

  ContentScroll({
    this.crewEdit,
    this.crew,
    this.title,
    this.imageHeight,
    this.imageWidth,
  });

  String displayRoles(crew) {
    var role = '';
    for (var i = 0; i < crew.role.length; i++) {
      role = role + crew.role[i];
      if (i != crew.role.length - 1) {
        role = role + ', ';
      }
      if (i == (crew.role.length - 2)) {
        role = role + 'at ';
      }
    }
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            crew.length >= 4
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeeAllView(crew: crew, type: "crew"),
                        ),
                      );
                    },
                    child: Text(
                      "Tingnan Lahat",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        crew.length != 0
            ? Container(
                height: imageHeight,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: crew.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      // Show Crew Details
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CrewView(crewId: crew[index].crewId.toString()),
                          ),
                        ),
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 5.0,
                        ),
                        width: imageWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5.0),
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 1,
                                    width: 1,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).accentColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Material(
                                  child: Image.network(
                                    Config.userNotFound,
                                    width: imageWidth,
                                    height: imageHeight,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                                imageUrl: crew[index].displayPic ??
                                    Config.userNotFound,
                                width: imageWidth,
                                height: imageHeight,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            Positioned(
                              bottom: 0, // 1
                              left: 1,
                              right: 1,
                              child: Container(
                                padding: EdgeInsets.all(5),
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  crew[index].firstName +
                                      " " +
                                      (crew[index].middleName != null
                                          ? " " + crew[index].middleName
                                          : "") +
                                      " " +
                                      crew[index].lastName +
                                      (crew[index].suffix != null
                                          ? " " + crew[index].suffix
                                          : "") +
                                      " " +
                                      (title == "Mga Aktor"
                                          ? "(" +
                                              displayRoles(crew[index]) +
                                              ")"
                                          : ""),
                                  // (title == "Mga Aktor"
                                  //     ? "bilang " + displayRoles(crew[index])
                                  //     : ""),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                                      blurRadius: 0.0, // 4
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            : Column(
                children: [
                  Text(
                    "Walang record.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ],
    );
  }
}
