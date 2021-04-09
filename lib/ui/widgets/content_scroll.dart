import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/crew.dart';

class ContentScroll extends StatelessWidget {
  final List<Crew> crew;
  final String title;
  final double imageHeight;
  final double imageWidth;

  ContentScroll({
    this.crew,
    this.title,
    this.imageHeight,
    this.imageWidth,
  });

  String dislayRoles(crew) {
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
            // TO DO: limit the display to only 5 or 6, and then write onPressed function to See All button
            crew.length > 4
                ? GestureDetector(
                    onTap: () => print('View $title'),
                    child: Text(
                      "See all",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(),
          ],
        ),
        // ),
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
                    return Container(
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
                                  'https://res.cloudinary.com/mubidibi-sp/image/upload/v1617686120/img_not_found/user-icon_zphbbd.png',
                                  width: imageWidth,
                                  height: imageHeight,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                              imageUrl: crew[index].displayPic ??
                                  'https://res.cloudinary.com/mubidibi-sp/image/upload/v1617686120/img_not_found/user-icon_zphbbd.png',
                              width: imageWidth,
                              height: imageHeight,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            left: 2,
                            right: 2,
                            child: Container(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                crew[index].firstName +
                                    " " +
                                    (crew[index].middleName != null
                                        ? crew[index].middleName +
                                            " " +
                                            crew[index].lastName
                                        : crew[index].lastName) +
                                    " " +
                                    (title == "Mga Aktor"
                                        ? "bilang " + dislayRoles(crew[index])
                                        : ""),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black54,
                                    offset: Offset(0.0, 4.0),
                                    blurRadius: 6.0,
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
