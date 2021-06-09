import 'package:chewie_audio/chewie_audio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';

class AudioFile extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool looping;
  final bool autoplay;
  final String type; // simple, detailed
  final String description;

  bool isVisible = true;

  AudioFile({
    @required this.videoPlayerController,
    this.looping,
    this.autoplay,
    this.type,
    this.description,
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AudioFileState();
  }
}

class AudioFileState extends State<AudioFile> {
  ChewieAudioController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieAudioController(
      videoPlayerController: widget.videoPlayerController,
      // aspectRatio: 16 / 9,
      allowMuting: true,
      autoInitialize: true,
      autoPlay: widget.autoplay,
      looping: widget.looping,
      errorBuilder: (context, errorMessage) {
        return Text('An error occurred.');
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
    return widget.type == "simple"
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChewieAudio(
              controller: _chewieController,
            ),
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
                                  height: 200,
                                  color: Colors.white,
                                ),
                              ),
                              Center(
                                  child: Icon(Icons.music_note_sharp,
                                      size: 30, color: Colors.black87)),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: ChewieAudio(
                                  controller: _chewieController,
                                ),
                              ),
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
