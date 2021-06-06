// MediaWidget class -- dynamic widget for adding photos/videos in crew and movie

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
// import 'package:chewie/chewie.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:mubidibi/globals.dart' as Config;

class MediaWidget extends StatefulWidget {
  final MediaFile item;
  final open;
  final category; // movie or crew

  const MediaWidget({Key key, this.item, this.open, this.category})
      : super(key: key);

  @override
  MediaWidgetState createState() => MediaWidgetState();
}

class MediaWidgetState extends State<MediaWidget> {
  bool showError = true;
  // FocusNodes
  final descriptionNode = FocusNode();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    widget.item.saved = widget.item.saved == null ? false : widget.item.saved;
    super.initState();
  }

  bool fileIsNull() {
    return widget.item.file == null ? true : false;
  }

  // Function: get image using image picker for movie poster
  void getCrewMedia() async {
    // single file
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.media);

    if (result != null) {
      // remove first the image that is currently in the widget.item.file from the gallery
      if (widget.item.file != null) {
        setState(() {
          gallery.removeWhere((f) => widget.item.file.path == f.path);
        });
      }

      List imagePaths =
          gallery.isNotEmpty ? gallery.map((img) => img.path).toList() : [];

      // check first if the image you're adding already exists in the list
      if (imagePaths.contains(result.files.single.path) == false) {
        setState(() {
          gallery.add(File(result.files.single.path));
          widget.item.file = File(result.files.single.path);
        });
      } else {
        print('File already exists.'); // TO DO: FlutterToast or SnackBar
      }
      return null;
    } else {
      // User canceled the picker
      print('No media selected.'); // TO DO: FlutterToast or SnackBar
    }
  }

  // Function: get image using image picker for movie gallery
  void getMovieMedia() async {
    if (widget.item.type == "gallery") {
      // single file
      FilePickerResult result =
          await FilePicker.platform.pickFiles(type: FileType.media);

      if (result != null) {
        // remove first the image that is currently in the widget.item.file from the gallery
        if (widget.item.file != null) {
          setState(() {
            movieGallery.removeWhere((f) => widget.item.file.path == f.path);
          });
        }

        List imagePaths = movieGallery.isNotEmpty
            ? movieGallery.map((img) => img.path).toList()
            : [];

        // check first if the image you're adding already exists in the list
        if (imagePaths.contains(result.files.single.path) == false) {
          setState(() {
            movieGallery.add(File(result.files.single.path));
            widget.item.file = File(result.files.single.path);
          });
        } else {
          print('File already exists.'); // TO DO: FlutterToast or SnackBar
        }
        return null;
      } else {
        // User canceled the picker
        print('No media selected.'); // TO DO: FlutterToast or SnackBar
      }
    } else if (widget.item.type == "poster") {
      // single file
      FilePickerResult result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        // remove first the image that is currently in the widget.item.file from the gallery
        if (widget.item.file != null) {
          setState(() {
            posters.removeWhere((f) => widget.item.file.path == f.path);
          });
        }

        List imagePaths =
            posters.isNotEmpty ? posters.map((img) => img.path).toList() : [];

        // check first if the image you're adding already exists in the list
        if (imagePaths.contains(result.files.single.path) == false) {
          setState(() {
            posters.add(File(result.files.single.path));
            widget.item.file = File(result.files.single.path);
          });
        } else {
          print('File already exists.'); // TO DO: FlutterToast or SnackBar
        }
        return null;
      } else {
        // User canceled the picker
        print('No media selected.'); // TO DO: FlutterToast or SnackBar
      }
    }
  }

  // Function: get trailers
  void getMovieTrailers() async {
    // single file
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      // remove first the image that is currently in the widget.item.file from the gallery
      if (widget.item.file != null) {
        setState(() {
          trailers.removeWhere((f) => widget.item.file.path == f.path);
        });
      }

      List imagePaths =
          trailers.isNotEmpty ? trailers.map((img) => img.path).toList() : [];

      // check first if the image you're adding already exists in the list
      if (imagePaths.contains(result.files.single.path) == false) {
        setState(() {
          trailers.add(File(result.files.single.path));
          widget.item.file = File(result.files.single.path);
        });
      } else {
        print('File already exists.'); // TO DO: FlutterToast or SnackBar
      }
      return null;
    } else {
      // User canceled the picker
      print('No file selected.'); // TO DO: FlutterToast or SnackBar
    }
  }

  // Function: get trailers
  void getMovieAudios() async {
    // single file
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      // remove first the image that is currently in the widget.item.file from the gallery
      if (widget.item.file != null) {
        setState(() {
          audios.removeWhere((f) => widget.item.file.path == f.path);
        });
      }

      List imagePaths =
          audios.isNotEmpty ? audios.map((img) => img.path).toList() : [];

      // check first if the image you're adding already exists in the list
      if (imagePaths.contains(result.files.single.path) == false) {
        setState(() {
          audios.add(File(result.files.single.path));
          widget.item.file = File(result.files.single.path);
        });
      } else {
        print('File already exists.'); // TO DO: FlutterToast or SnackBar
      }
      return null;
    } else {
      // User canceled the picker
      print('No media selected.'); // TO DO: FlutterToast or SnackBar
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.open.value == true
        ? Column(
            children: [
              SizedBox(
                height: 15,
              ),

              // Clickable field for trailers and audios
              (widget.item.type == "trailer" || widget.item.type == "audio")
                  ?
                  // if item != null, display
                  Column(
                      children: [
                        Stack(
                          children: [
                            widget.item.file == null
                                ? GestureDetector(
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      color: Color.fromRGBO(240, 240, 240, 1),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.attach_file_outlined),
                                          Text('Mag-upload ng file',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic)),
                                        ],
                                      ),
                                    ),
                                    onTap: widget.item.type == "trailer"
                                        ? getMovieTrailers
                                        : getMovieAudios)
                                : Container(
                                    padding: EdgeInsets.all(10),
                                    color: Color.fromRGBO(240, 240, 240, 1),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.item.file.path
                                                .split('/')
                                                .last,
                                            style:
                                                TextStyle(color: Colors.blue),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ),
                                        GestureDetector(
                                          child: Icon(Icons.close,
                                              color: Colors.black),
                                          onTap: () {
                                            if (widget.item.type == "audio") {
                                              List imagePaths = audios
                                                      .isNotEmpty
                                                  ? audios
                                                      .map((img) => img.path)
                                                      .toList()
                                                  : [];

                                              setState(() {
                                                if (imagePaths.contains(widget
                                                        .item.file.path) ==
                                                    true) {
                                                  audios.removeWhere((f) =>
                                                      widget.item.file.path ==
                                                      f.path);
                                                }
                                                // imageURI = '';
                                                widget.item.file = null;
                                                widget.item.saved =
                                                    widget.item.file != null &&
                                                            widget.item.saved ==
                                                                true
                                                        ? true
                                                        : false;
                                              });
                                            } else if (widget.item.type ==
                                                "trailer") {
                                              List imagePaths = trailers
                                                      .isNotEmpty
                                                  ? trailers
                                                      .map((img) => img.path)
                                                      .toList()
                                                  : [];

                                              setState(() {
                                                if (imagePaths.contains(widget
                                                        .item.file.path) ==
                                                    true) {
                                                  trailers.removeWhere((f) =>
                                                      widget.item.file.path ==
                                                      f.path);
                                                }

                                                // imageURI = '';
                                                widget.item.file = null;
                                                widget.item.saved =
                                                    widget.item.file != null &&
                                                            widget.item.saved ==
                                                                true
                                                        ? true
                                                        : false;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                          ],
                        ),
                        SizedBox(height: 10),
                        // textfield for description
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            enabled: !fileIsNull(),
                            focusNode: descriptionNode,
                            initialValue: widget.item.description,
                            textCapitalization: TextCapitalization.sentences,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            style: TextStyle(
                              color: fileIsNull() == false
                                  ? Colors.black
                                  : Colors.black38,
                            ),
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: "Description",
                              contentPadding: EdgeInsets.all(10),
                              filled: true,
                              fillColor: Color.fromRGBO(240, 240, 240, 1),
                            ),
                            onChanged: (val) {
                              setState(() {
                                widget.item.description =
                                    val.trim() != "" ? val : null;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  :
                  // For Gallery type -- display of videos
                  widget.item.type == "gallery" &&
                          widget.item.file != null &&
                          (lookupMimeType(widget.item.file.path)
                                  .startsWith('video/') ==
                              true)
                      // For Gallery type with Video Formats
                      ? Container(
                          padding: EdgeInsets.all(10),
                          color: Color.fromRGBO(240, 240, 240, 1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.file.path.split('/').last,
                                  style: TextStyle(color: Colors.blue),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                              GestureDetector(
                                child: Icon(Icons.close, color: Colors.black),
                                onTap: () {
                                  if (widget.category == "crew") {
                                    List imagePaths = gallery.isNotEmpty
                                        ? gallery
                                            .map((img) => img.path)
                                            .toList()
                                        : [];

                                    setState(() {
                                      if (imagePaths.contains(
                                              widget.item.file.path) ==
                                          true) {
                                        gallery.removeWhere((f) =>
                                            widget.item.file.path == f.path);
                                      }
                                      // imageURI = '';
                                      widget.item.file = null;
                                      widget.item.saved =
                                          widget.item.file != null &&
                                                  widget.item.saved == true
                                              ? true
                                              : false;
                                    });
                                  } else if (widget.category == "movie") {
                                    List imagePaths = movieGallery.isNotEmpty
                                        ? movieGallery.map((img) {
                                            return img.path;
                                          }).toList()
                                        : [];

                                    setState(() {
                                      if (imagePaths.contains(
                                              widget.item.file.path) ==
                                          true) {
                                        movieGallery.removeWhere((f) =>
                                            widget.item.file.path == f.path);
                                      }
                                      // imageURI = '';
                                      widget.item.file = null;
                                      widget.item.saved =
                                          widget.item.file != null &&
                                                  widget.item.saved == true
                                              ? true
                                              : false;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        )

                      // For Gallery Type of image formats // posters
                      : (widget.item.type == "gallery" ||
                              widget.item.type == "poster")
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // if file != null
                                (widget.item.file != null &&
                                            lookupMimeType(
                                                        widget.item.file.path)
                                                    .startsWith('image/') ==
                                                true) ||
                                        widget.item.file == null
                                    ? Container(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: widget.category == "crew"
                                                  ? getCrewMedia
                                                  : getMovieMedia,
                                              child: Container(
                                                // margin: EdgeInsets.only(left: 20),
                                                height: 100, // 200
                                                width: 80, // 150
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: widget.item.file != null
                                                    ? Container(
                                                        height: 100,
                                                        width: 80,
                                                        child: Image.file(
                                                          widget.item.file,
                                                          width: 80,
                                                          height: 100,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Container(
                                                        height: 100,
                                                        width: 80,
                                                        child: Icon(
                                                          Icons.camera_alt,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Color.fromRGBO(
                                                              240, 240, 240, 1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            widget.item.file != null
                                                // widget.item.file != null || imageURI.trim() != ''
                                                ? Container(
                                                    // margin: EdgeInsets.only(left: 25, top: 5),
                                                    width: 25,
                                                    alignment: Alignment.center,
                                                    child: GestureDetector(
                                                      child: Icon(Icons.close),
                                                      onTap: () {
                                                        if (widget.category ==
                                                            "crew") {
                                                          List imagePaths = gallery
                                                                  .isNotEmpty
                                                              ? gallery
                                                                  .map((img) =>
                                                                      img.path)
                                                                  .toList()
                                                              : [];

                                                          setState(() {
                                                            if (imagePaths.contains(
                                                                    widget
                                                                        .item
                                                                        .file
                                                                        .path) ==
                                                                true) {
                                                              gallery.removeWhere(
                                                                  (f) =>
                                                                      widget
                                                                          .item
                                                                          .file
                                                                          .path ==
                                                                      f.path);
                                                            }
                                                            // imageURI = '';
                                                            widget.item.file =
                                                                null;
                                                            widget.item
                                                                .saved = widget
                                                                            .item
                                                                            .file !=
                                                                        null &&
                                                                    widget.item
                                                                            .saved ==
                                                                        true
                                                                ? true
                                                                : false;
                                                          });
                                                        } else if (widget
                                                                .category ==
                                                            "movie") {
                                                          if (widget
                                                                  .item.type ==
                                                              "gallery") {
                                                            List imagePaths = movieGallery
                                                                    .isNotEmpty
                                                                ? movieGallery
                                                                    .map((img) =>
                                                                        img.path)
                                                                    .toList()
                                                                : [];

                                                            setState(() {
                                                              if (imagePaths.contains(
                                                                      widget
                                                                          .item
                                                                          .file
                                                                          .path) ==
                                                                  true) {
                                                                movieGallery
                                                                    .removeWhere((f) =>
                                                                        widget
                                                                            .item
                                                                            .file
                                                                            .path ==
                                                                        f.path);
                                                              }
                                                              // imageURI = '';
                                                              widget.item.file =
                                                                  null;
                                                              widget.item
                                                                  .saved = widget
                                                                              .item
                                                                              .file !=
                                                                          null &&
                                                                      widget.item
                                                                              .saved ==
                                                                          true
                                                                  ? true
                                                                  : false;
                                                            });
                                                          } else if (widget
                                                                  .item.type ==
                                                              "poster") {
                                                            List imagePaths = posters
                                                                    .isNotEmpty
                                                                ? posters
                                                                    .map((img) =>
                                                                        img.path)
                                                                    .toList()
                                                                : [];

                                                            setState(() {
                                                              if (imagePaths.contains(
                                                                      widget
                                                                          .item
                                                                          .file
                                                                          .path) ==
                                                                  true) {
                                                                posters.removeWhere((f) =>
                                                                    widget
                                                                        .item
                                                                        .file
                                                                        .path ==
                                                                    f.path);
                                                              }
                                                              // imageURI = '';
                                                              widget.item.file =
                                                                  null;
                                                              widget.item
                                                                  .saved = widget
                                                                              .item
                                                                              .file !=
                                                                          null &&
                                                                      widget.item
                                                                              .saved ==
                                                                          true
                                                                  ? true
                                                                  : false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.white,
                                                          offset:
                                                              Offset(0.0, 0.0),
                                                          blurRadius: 0.0,
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : SizedBox(),
                                          ],
                                        ),
                                      )
                                    : SizedBox(),
                                // (widget.item.file != null &&
                                //             lookupMimeType(
                                //                         widget.item.file.path)
                                //                     .startsWith('image/') ==
                                //                 true) ||
                                //         (widget.item.file == null &&
                                //             (widget.item.type == "poster" ||
                                //                 widget.item.type == "gallery"))
                                //     ? SizedBox(width: 15)
                                //     : SizedBox(),
                                SizedBox(width: 15),
                                // textfield for description
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: TextFormField(
                                      enabled: !fileIsNull(),
                                      focusNode: descriptionNode,
                                      initialValue: widget.item.description,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: TextStyle(
                                        color: fileIsNull() == false
                                            ? Colors.black
                                            : Colors.black38,
                                      ),
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        labelText: "Description",
                                        contentPadding: EdgeInsets.all(10),
                                        filled: true,
                                        fillColor:
                                            Color.fromRGBO(240, 240, 240, 1),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          widget.item.description =
                                              val.trim() != "" ? val : null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(),

              SizedBox(
                height: 15,
              ),
              Container(
                child: OutlineButton(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  color: Colors.white,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (widget.item.file != null) {
                      setState(() {
                        widget.open.value = false;
                        widget.item.saved = true;
                      });
                    } else {
                      setState(() {
                        widget.item.saved = false;
                        showError = true;
                      });
                    }
                  },
                  child: Text('Save'),
                ),
                alignment: Alignment.center,
              ),
            ],
          )
        : Container(
            color: Color.fromRGBO(240, 240, 240, 1),
            padding: widget.item.file != null &&
                    (lookupMimeType(widget.item.file.path)
                                .startsWith('video/') ==
                            true ||
                        lookupMimeType(widget.item.file.path)
                                .startsWith('audio/') ==
                            true)
                ? EdgeInsets.zero
                : EdgeInsets.all(10),
            margin: EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                widget.item.file != null &&
                        (lookupMimeType(widget.item.file.path)
                                    .startsWith('video/') ==
                                true ||
                            lookupMimeType(widget.item.file.path)
                                    .startsWith('audio/') ==
                                true)
                    ? Container(
                        margin: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.file.path.split('/').last,
                                style: TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                            Container(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                child: Icon(Icons.edit_outlined),
                                onTap: () {
                                  setState(() {
                                    widget.open.value = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    (widget.item.file != null &&
                                lookupMimeType(widget.item.file.path)
                                        .startsWith('image/') ==
                                    true) ||
                            widget.item.file == null
                        ? Container(
                            alignment: Alignment.centerLeft,
                            height: 100,
                            width: 80,
                            child: Image.file(
                              widget.item.file,
                              width: 80,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : SizedBox(),
                    (widget.item.file != null &&
                                lookupMimeType(widget.item.file.path)
                                        .startsWith('image/') ==
                                    true) ||
                            widget.item.file == null
                        ? SizedBox(width: 15)
                        : SizedBox(),
                    Expanded(
                      child: (widget.item.file != null &&
                                  lookupMimeType(widget.item.file.path)
                                          .startsWith('image/') ==
                                      true) ||
                              widget.item.file == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                      widget.item.description ??
                                          "Walang description",
                                      style: TextStyle(
                                          color: widget.item.description == null
                                              ? Colors.black38
                                              : Colors.black,
                                          fontStyle:
                                              widget.item.description == null
                                                  ? FontStyle.italic
                                                  : FontStyle.normal)),
                                ),
                                Container(
                                  alignment: Alignment.topRight,
                                  child: GestureDetector(
                                    child: Icon(Icons.edit_outlined),
                                    onTap: () {
                                      setState(() {
                                        widget.open.value = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              margin: EdgeInsets.all(10),
                              child: Text(
                                  widget.item.description ??
                                      "Walang description",
                                  style: TextStyle(
                                      color: widget.item.description == null
                                          ? Colors.black38
                                          : Colors.black,
                                      fontStyle: widget.item.description == null
                                          ? FontStyle.italic
                                          : FontStyle.normal)),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}
