import 'package:flutter/material.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/full_photo.dart';
import 'package:mubidibi/ui/views/signin_category_view.dart';
import 'package:mubidibi/ui/widgets/responsive.dart';
import 'package:mubidibi/ui/widgets/vertical_icon_button.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:ui';
import 'package:mubidibi/globals.dart' as Config;

import '../../locator.dart';

class ContentHeader extends StatelessWidget {
  final Movie featuredContent;

  const ContentHeader({
    Key key,
    @required this.featuredContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _ContentHeaderMobile(featuredContent: featuredContent),
    );
  }
}

class _ContentHeaderMobile extends StatelessWidget {
  final Movie featuredContent;

  const _ContentHeaderMobile({
    Key key,
    @required this.featuredContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NavigationService _navigationService = locator<NavigationService>();
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          // height: 500.0,
          height: (queryData.size.height / 2) + 100,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0.0, 0.0),
                blurRadius: 2.0,
              ),
            ],
          ),
          child: Text(
            featuredContent.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          // height: 500.0,
          height: (queryData.size.height / 2) + 100,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(featuredContent.poster ?? Config.imgNotFound),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        GestureDetector(
          child: Container(
            // height: 500.0,
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
                builder: (context) => FullPhoto(
                    url: featuredContent.poster ?? Config.imgNotFound),
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
                icon: Icons.add,
                title: 'My Favorites',
                onTap: () =>
                    _navigationService.navigateTo(SignInCategoryViewRoute),
              ),
              VerticalIconButton(
                icon: Icons.info_outline,
                title: 'Info',
                // Show Movie Details
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieView(
                          movieId: featuredContent.movieId.toString()),
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
