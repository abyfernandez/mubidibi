import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:mubidibi/ui/views/full_photo.dart';
import 'package:mubidibi/ui/widgets/responsive.dart';
import 'package:mubidibi/ui/widgets/vertical_icon_button.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/models/movie.dart';
import 'dart:ui';

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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 500.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(featuredContent.poster),
              fit: BoxFit.cover,
            ),
          ),
        ),
        GestureDetector(
          child: Container(
            height: 500.0,
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
                builder: (context) => FullPhoto(url: featuredContent.poster),
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
                onTap: () => print('My Favorites'),
              ),
              VerticalIconButton(
                icon: Icons.info_outline,
                title: 'Info',
                // Show Movie Details
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieView(movie: featuredContent),
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
