// MediaWidget class -- dynamic widget for adding photos/videos in crew and movie

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/globals.dart' as Config;

class MediaWidget extends StatefulWidget {
  final MediaFile item;
  final open;
  final category; // movie or crew
  final sKey; // scaffold key from parent widget

  const MediaWidget({Key key, this.item, this.open, this.category, this.sKey})
      : super(key: key);

  @override
  MediaWidgetState createState() => MediaWidgetState();
}

class MediaWidgetState extends State<MediaWidget> {
  // FocusNodes
  final descriptionNode = FocusNode();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    widget.item.saved = widget.item.saved == null &&
            (widget.item.file != null || widget.item.url != null)
        ? false
        : widget.item.saved;
    super.initState();
  }

  bool mediaIsNull() {
    // enables/disables description text field
    // return widget.item.file == null || (widget.item.url != null ? true : false);

    // edited version: allow user to edit the description for existing media
    return (widget.item.file == null && widget.item.url == null) ? true : false;
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
        Fluttertoast.showToast(msg: 'File already exists.');
      }
      return null;
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
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
          Fluttertoast.showToast(msg: 'File already exists.');
        }
        return null;
      } else {
        // User canceled the picker
        Fluttertoast.showToast(msg: 'No file selected.');
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
          Fluttertoast.showToast(msg: 'File already exists.');
        }
        return null;
      } else {
        // User canceled the picker
        Fluttertoast.showToast(msg: 'No file selected.');
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
        Fluttertoast.showToast(msg: 'File already exists.');
      }
      return null;
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
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
        Fluttertoast.showToast(msg: 'File already exists.');
      }
      return null;
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
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
                            widget.item.url == null
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
                                : SizedBox(),

                            // Container for the file/url -- only show when either exists
                            // Widget stacked on top of the GestureDetector for uploading video/audio files
                            widget.item.file != null || widget.item.url != null
                                ? Container(
                                    padding: EdgeInsets.all(10),
                                    color: Color.fromRGBO(240, 240, 240, 1),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.item.file != null
                                                ? widget.item.file.path
                                                    .split('/')
                                                    .last
                                                : widget.item.url
                                                    .split('/')
                                                    .last,
                                            style:
                                                TextStyle(color: Colors.blue),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ),

                                        // remove chosen file
                                        widget.item.file != null
                                            ? GestureDetector(
                                                child: Icon(Icons.close,
                                                    color: Colors.black),
                                                onTap: () {
                                                  if (widget.item.type ==
                                                      "audio") {
                                                    List imagePaths =
                                                        audios.isNotEmpty
                                                            ? audios
                                                                .map((img) =>
                                                                    img.path)
                                                                .toList()
                                                            : [];

                                                    setState(() {
                                                      if (imagePaths.contains(
                                                              widget.item.file
                                                                  .path) ==
                                                          true) {
                                                        audios.removeWhere(
                                                            (f) =>
                                                                widget.item.file
                                                                    .path ==
                                                                f.path);
                                                      }
                                                      widget.item.file = null;
                                                      widget.item.saved = widget
                                                                      .item
                                                                      .file !=
                                                                  null &&
                                                              widget.item
                                                                      .saved ==
                                                                  true
                                                          ? true
                                                          : false;
                                                    });
                                                  } else if (widget.item.type ==
                                                      "trailer") {
                                                    List imagePaths =
                                                        trailers.isNotEmpty
                                                            ? trailers
                                                                .map((img) =>
                                                                    img.path)
                                                                .toList()
                                                            : [];

                                                    setState(() {
                                                      if (imagePaths.contains(
                                                              widget.item.file
                                                                  .path) ==
                                                          true) {
                                                        trailers.removeWhere(
                                                            (f) =>
                                                                widget.item.file
                                                                    .path ==
                                                                f.path);
                                                      }

                                                      widget.item.file = null;
                                                      widget.item.saved = widget
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
                                                },
                                              )
                                            : SizedBox(), // when the url is not null, don't add a close button
                                      ],
                                    ),
                                  )
                                : SizedBox()
                          ],
                        ),

                        SizedBox(height: 10),

                        // Trailer / Audio -- textfield for description
                        // Takes the width of the screen, since the file/url is above it.
                        // allows editing of description when media is present
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          child: TextFormField(
                            enabled: !mediaIsNull(),
                            focusNode: descriptionNode,
                            initialValue: widget.item.description,
                            textCapitalization: TextCapitalization.sentences,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            style: TextStyle(
                              color: mediaIsNull() == false
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
                        )
                      ],
                    )
                  :
                  // For Gallery type -- Form for videos
                  widget.item.type == "gallery" &&
                          ((widget.item.file != null &&
                                  lookupMimeType(widget.item.file.path)
                                          .startsWith('video/') ==
                                      true) ||
                              (widget.item.url != null &&
                                  widget.item.format != 'image'))
                      // For Gallery type with Video Formats --
                      ? Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10), // -- test
                              color: Color.fromRGBO(240, 240, 240, 1),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // file path / url
                                  Expanded(
                                    child: Text(
                                      widget.item.file != null
                                          ? widget.item.file.path
                                              .split('/')
                                              .last
                                          : widget.item.url.split('/').last,
                                      style: TextStyle(color: Colors.blue),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),

                                  // close / remove button
                                  widget.item.file != null &&
                                          widget.item.url == null
                                      ? GestureDetector(
                                          child: Icon(Icons.close,
                                              color: Colors.black),
                                          onTap: () {
                                            if (widget.category == "crew") {
                                              List imagePaths = gallery
                                                      .isNotEmpty
                                                  ? gallery
                                                      .map((img) => img.path)
                                                      .toList()
                                                  : [];

                                              setState(() {
                                                if (imagePaths.contains(widget
                                                        .item.file.path) ==
                                                    true) {
                                                  gallery.removeWhere((f) =>
                                                      widget.item.file.path ==
                                                      f.path);
                                                }
                                                widget.item.file = null;
                                                widget.item.saved =
                                                    widget.item.file != null &&
                                                            widget.item.saved ==
                                                                true
                                                        ? true
                                                        : false;
                                              });
                                            } else if (widget.category ==
                                                "movie") {
                                              List imagePaths =
                                                  movieGallery.isNotEmpty
                                                      ? movieGallery.map((img) {
                                                          return img.path;
                                                        }).toList()
                                                      : [];

                                              setState(() {
                                                if (imagePaths.contains(widget
                                                        .item.file.path) ==
                                                    true) {
                                                  movieGallery.removeWhere(
                                                      (f) =>
                                                          widget
                                                              .item.file.path ==
                                                          f.path);
                                                }
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
                                        )
                                      : SizedBox(), // if media is existing (do not add a close button)
                                ],
                              ),
                            ),
                            SizedBox(height: 10),

                            // Description field for Gallery with video types
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextFormField(
                                enabled: !mediaIsNull(),
                                focusNode: descriptionNode,
                                initialValue: widget.item.description,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: TextStyle(
                                  color: mediaIsNull() == false
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

                      // For Gallery Type of image formats // posters
                      // the area for image upload is beside the description field
                      : (widget.item.type == "gallery" ||
                              widget.item.type == "poster")
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (widget.item.file != null &&
                                            lookupMimeType(
                                                        widget.item.file.path)
                                                    .startsWith('image/') ==
                                                true) ||
                                        (widget.item.file == null &&
                                            widget.item.url == null) ||
                                        (widget.item.url != null &&
                                            widget.item.format == 'image')
                                    ? Container(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Stack(
                                          children: [
                                            // Gesture detector for image
                                            widget.item.url == null &&
                                                    widget.item.file == null
                                                ? GestureDetector(
                                                    onTap: widget.category ==
                                                            "crew"
                                                        ? getCrewMedia
                                                        : getMovieMedia,
                                                    child: Container(
                                                      height: 100, // 200
                                                      width: 80, // 150
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: widget.item.file !=
                                                              null
                                                          ? Container(
                                                              height: 100,
                                                              width: 80,
                                                              child: Image.file(
                                                                widget
                                                                    .item.file,
                                                                width: 80,
                                                                height: 100,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            )
                                                          : Container(
                                                              height: 100,
                                                              width: 80,
                                                              child: Icon(
                                                                Icons
                                                                    .camera_alt,
                                                                color: Colors
                                                                    .grey[800],
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Color
                                                                    .fromRGBO(
                                                                        240,
                                                                        240,
                                                                        240,
                                                                        1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                              ),
                                                            ),
                                                    ),
                                                  )
                                                : SizedBox(),

                                            // url is present
                                            widget.item.file != null ||
                                                    widget.item.url != null
                                                ? widget.item.url != null
                                                    ? Container(
                                                        // show image from url
                                                        height: 100, // 200
                                                        width: 80, // 150
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Container(
                                                          height: 100,
                                                          width: 80,
                                                          child:
                                                              CachedNetworkImage(
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Container(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              width: 80,
                                                              height: 100,
                                                              child:
                                                                  Image.network(
                                                                      widget
                                                                          .item
                                                                          .url,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          80),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Material(
                                                              child: Container(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                width: 80,
                                                                height: 100,
                                                                child: Image.network(
                                                                    Config
                                                                        .imgNotFound,
                                                                    width: 80,
                                                                    height: 100,
                                                                    fit: BoxFit
                                                                        .cover),
                                                              ),
                                                            ),
                                                            imageUrl: widget
                                                                    .item.url ??
                                                                Config
                                                                    .imgNotFound,
                                                            width: 80,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      )

                                                    // else show image file
                                                    : widget.item.file != null
                                                        ? Image.file(
                                                            widget.item.file,
                                                            width: 80,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : CachedNetworkImage(
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Container(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              width: 80,
                                                              height: 100,
                                                              child:
                                                                  Image.network(
                                                                      widget
                                                                          .item
                                                                          .url,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          80),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Material(
                                                              child: Container(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                width: 80,
                                                                height: 100,
                                                                child: Image.network(
                                                                    Config
                                                                        .imgNotFound,
                                                                    width: 80,
                                                                    height: 100,
                                                                    fit: BoxFit
                                                                        .cover),
                                                              ),
                                                            ),
                                                            imageUrl: widget
                                                                    .item.url ??
                                                                Config
                                                                    .imgNotFound,
                                                            width: 80,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          )
                                                : SizedBox(),

                                            // file exists -- close button
                                            widget.item.file != null &&
                                                    widget.item.url == null
                                                ? Container(
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

                                SizedBox(width: 15),

                                // Textfield for Description
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: TextFormField(
                                      enabled: !mediaIsNull(),
                                      focusNode: descriptionNode,
                                      initialValue: widget.item.description,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: TextStyle(
                                        color: mediaIsNull() == false
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

              (widget.item.file != null &&
                          (lookupMimeType(widget.item.file.path)
                                      .startsWith('video/') ==
                                  true ||
                              lookupMimeType(widget.item.file.path)
                                      .startsWith('audio/') ==
                                  true)) ||
                      (widget.item.url != null && widget.item.format != 'image')
                  ? SizedBox(height: 15)
                  : SizedBox(),
              Container(
                child: TextButton(
                  // padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  // color: Colors.white,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (widget.item.file != null || widget.item.url != null) {
                      setState(() {
                        widget.open.value = false;
                        widget.item.saved = true;
                      });
                    } else {
                      setState(() {
                        widget.item.saved = false;
                      });
                    }
                  },
                  child: Text('SAVE', style: TextStyle(color: Colors.blue)),
                ),
                alignment: Alignment.center,
              ),
            ],
          )
        : Container(
            color: Color.fromRGBO(240, 240, 240, 1),
            padding: (widget.item.file != null &&
                        (lookupMimeType(widget.item.file.path)
                                    .startsWith('video/') ==
                                true ||
                            lookupMimeType(widget.item.file.path)
                                    .startsWith('audio/') ==
                                true)) ||
                    (widget.item.url != null && widget.item.format != 'image')
                ? EdgeInsets.zero
                : EdgeInsets.all(10),
            margin: EdgeInsets.only(bottom: 10, top: 10),
            child: Column(
              children: [
                (widget.item.file != null &&
                            (lookupMimeType(widget.item.file.path)
                                        .startsWith('video/') ==
                                    true ||
                                lookupMimeType(widget.item.file.path)
                                        .startsWith('audio/') ==
                                    true)) ||
                        (widget.item.url != null &&
                            widget.item.format != 'image')
                    ? Container(
                        margin: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.file != null
                                    ? widget.item.file.path.split('/').last
                                    : widget.item.url.split('/').last,
                                style: TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                            Container(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                // child: Icon(Icons.edit_outlined),
                                child: Text('EDIT',
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 16)),
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
                            (widget.item.url != null &&
                                widget.item.format == 'image')
                        ? Container(
                            alignment: Alignment.centerLeft,
                            height: 100,
                            width: 80,
                            child: widget.item.file != null
                                ? Image.file(
                                    widget.item.file,
                                    width: 80,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      alignment: Alignment.center,
                                      width: 80,
                                      height: 100,
                                      child: Image.network(widget.item.url,
                                          fit: BoxFit.cover,
                                          height: 100,
                                          width: 80),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Material(
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: 80,
                                        height: 100,
                                        child: Image.network(Config.imgNotFound,
                                            width: 80,
                                            height: 100,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    imageUrl:
                                        widget.item.url ?? Config.imgNotFound,
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
                            (widget.item.url != null &&
                                widget.item.format == 'image')
                        ? SizedBox(width: 15)
                        : SizedBox(),
                    Expanded(
                      child: (widget.item.file != null &&
                                  lookupMimeType(widget.item.file.path)
                                          .startsWith('image/') ==
                                      true) ||
                              (widget.item.url != null &&
                                  widget.item.format == 'image')
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
                                    // child: Icon(Icons.edit_outlined),
                                    child: Text('EDIT',
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16)),
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
