import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/ui/widgets/vertical_icon_button.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:ui';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import '../../locator.dart';

ValueNotifier<bool> headerFavorite = ValueNotifier<bool>(false);

class ContentHeader extends StatefulWidget {
  final Movie featuredContent;

  ContentHeader({
    Key key,
    @required this.featuredContent,
  }) : super(key: key);

  @override
  _ContentHeaderState createState() => _ContentHeaderState(featuredContent);
}

class _ContentHeaderState extends State<ContentHeader> {
  final Movie featuredContent;

  // bool favorite;

  _ContentHeaderState(this.featuredContent);

  bool isFavorite() {
    return headerFavorite.value;
  }

  @override
  void initState() {
    // favorite =
    //     featuredContent.favoriteId != null && featuredContent.favoriteId != 0
    //         ? true
    //         : false;
    headerFavorite.value =
        featuredContent.favoriteId != null && featuredContent.favoriteId != 0
            ? true
            : false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService _navigationService = locator<NavigationService>();
    final AuthenticationService _authenticationService =
        locator<AuthenticationService>();
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    var currentUser = _authenticationService.currentUser;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          height: (queryData.size.height / 2) + 100,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0.0, 0.0),
                blurRadius: 0.0,
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(5),
            child: Text(
              featuredContent.title +
                  (featuredContent.releaseDate != "" &&
                          featuredContent.releaseDate != null
                      ? (" (" +
                          DateFormat('y').format(
                              DateTime.parse(featuredContent.releaseDate)) +
                          ") ")
                      : ""),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          height: (queryData.size.height / 2) + 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(featuredContent.posters != null &&
                      featuredContent.posters.length != 0
                  ? featuredContent.posters[0].url
                  : Config.imgNotFound),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        GestureDetector(
          child: Container(
            height: (queryData.size.height / 2) + 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.black, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullPhotoT(
                    url: featuredContent.posters != null &&
                            featuredContent.posters.length != 0
                        ? featuredContent.posters[0].url
                        : Config.imgNotFound,
                    description: featuredContent.posters[0].description,
                    type: 'network'),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 40.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              VerticalIconButton(
                  icon: isFavorite() ? Icons.check : Icons.add,
                  title: 'My Favorites',
                  onTap: () {
                    if (currentUser == null) {
                      _navigationService.navigateTo(SignInCategoryViewRoute);
                    } else {
                      // add to favorites
                      var model = MovieViewModel();
                      model
                          .updateFavorites(
                              movieId: featuredContent.movieId,
                              type: isFavorite() ? 'delete' : 'add')
                          .then((val) => setState(() {
                                headerFavorite.value = val != 0
                                    ? !headerFavorite.value
                                    : headerFavorite.value;
                                rebuild.value = true;
                              }));
                    }
                  }),
              VerticalIconButton(
                icon: Icons.info_outline,
                title: 'Info',
                // Show Movie Details
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MovieView(movieId: featuredContent.movieId),
                    ),
                  ).then((data) {
                    print(data);
                    if (data[0] == true) {
                      rebuild.value = true;
                      setState(() {
                        headerFavorite.value = data[1];
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
