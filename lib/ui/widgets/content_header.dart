import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/ui/widgets/vertical_icon_button.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:ui';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import '../../locator.dart';
import 'package:fluttertoast/fluttertoast.dart';

ValueNotifier<bool> favoriteFlag = ValueNotifier<bool>(false);
int headerId = 0;

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

  _ContentHeaderState(this.featuredContent);

  bool favChecker(bool value) {
    print(value);
    return value;
  }

  @override
  void initState() {
    super.initState();
    headerId = featuredContent.movieId;
    favoriteFlag.value =
        featuredContent.favoriteId != null && featuredContent.favoriteId != 0
            ? true
            : false;
  }

  @override
  Widget build(BuildContext context) {
    final NavigationService _navigationService = locator<NavigationService>();
    final AuthenticationService _authenticationService =
        locator<AuthenticationService>();
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    var currentUser = _authenticationService.currentUser;

    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      onModelReady: (model) async {},
      builder: (context, model, child) => Stack(
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
                // image: NetworkImage(featuredContent.posters != null &&
                //         featuredContent.posters.length != 0
                //     ? featuredContent.posters[0].url
                //     : Config.imgNotFound),
                image: CachedNetworkImageProvider(
                    featuredContent.posters != null &&
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
                ValueListenableBuilder(
                  valueListenable: favoriteFlag,
                  builder: (context, fav, widget) {
                    return VerticalIconButton(
                        icon: fav ? Icons.check : Icons.add,
                        title: 'My Favorites',
                        onTap: () {
                          if (currentUser == null) {
                            _navigationService
                                .navigateTo(SignInCategoryViewRoute);
                          } else {
                            // add to favorites
                            model
                                .updateFavorites(
                                    movieId: featuredContent.movieId,
                                    type: fav ? 'delete' : 'add')
                                .then((val) {
                              print('VAL: $val');
                              favoriteFlag.value = val != 0 ? true : false;
                              rebuild.value = true;
                              Fluttertoast.showToast(
                                  msg: (fav ? 'Removed from' : 'Added to') +
                                      ' favorites.');
                            });
                          }
                        });
                  },
                ),
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
                      );
                    })
              ],
            ),
          ),
        ],
      ),
    );
  }
}
