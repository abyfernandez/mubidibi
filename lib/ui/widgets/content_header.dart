import 'package:flutter/material.dart';

// import 'package:mubidibi/models/models.dart';
// import 'package:mubidibi/ui/widgets/widgets.dart';
// import 'package:video_player/video_player.dart';
import 'package:mubidibi/ui/widgets/responsive.dart';
import 'package:mubidibi/ui/widgets/vertical_icon_button.dart';
import 'package:mubidibi/models/movie.dart';

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
        // DecorationImage(
        //   image: AssetImage(featuredContent.poster),
        //   fit: BoxFit.cover,
        // ),
        Container(
          height: 500.0,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 110.0,
          child: SizedBox(
            width: 250.0,
            // child: Image.asset(featuredContent.poster),
          ),
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
                title: 'List',
                onTap: () => print('My List'),
              ),
              _PlayButton(),
              VerticalIconButton(
                icon: Icons.info_outline,
                title: 'Info',
                onTap: () => print('Info'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      padding: EdgeInsets.fromLTRB(15.0, 5.0, 20.0, 5.0),
      onPressed: () => print('Play'),
      color: Colors.white,
      icon: const Icon(Icons.play_arrow, size: 30.0),
      label: const Text(
        'Play',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
