import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';

class VideoFile extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool looping;
  final bool autoplay;
  final String type; // simple, detailed
  final String description;

  bool isVisible = true;

  VideoFile({
    @required this.videoPlayerController,
    this.looping,
    this.autoplay,
    this.type,
    this.description,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoFileState();
  }
}

class VideoFileState extends State<VideoFile> {
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      aspectRatio: 16 / 9,
      autoInitialize: true,
      autoPlay: widget.autoplay,
      looping: widget.looping,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red),
              SizedBox(width: 5),
              Text(
                'Error loading file',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == 'simple'
        ? Chewie(
            controller: _chewieController,
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.transparent,
            ),
            body: GestureDetector(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          height: 200,
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  child: Chewie(
                                    controller: _chewieController,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Visibility(
                          maintainInteractivity: true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          visible: widget.isVisible,
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(0.0, 0.0),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: EdgeInsets.all(5),
                              child: Text(
                                widget.description ?? 'No description',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: widget.description != ''
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                                overflow: TextOverflow.clip,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  setState(() {
                    widget.isVisible = !widget.isVisible;
                  });
                }),
          );
  }
}
