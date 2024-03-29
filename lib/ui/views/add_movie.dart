import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/line.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/widgets/award_widget.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/ui/widgets/line_widget.dart';
import 'package:mubidibi/ui/widgets/media_widget.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

// For Dynamic Widgets
List<int> actorsFilter = []; // actors
List<int> awardsFilter = []; // awards
List movieGallery = [];
List posters = [];
List trailers = [];
List audios = [];

// for line widget
ValueNotifier<List> rolesFilter = ValueNotifier<List>([]);

class AddMovie extends StatefulWidget {
  final Movie movie;
  final List<List<Crew>> crewEdit;
  final List<Crew> movieCrewList;
  final List<Award> movieAwards;
  final List<Award> awardOpts;

  AddMovie({
    Key key,
    this.movie,
    this.crewEdit,
    this.movieCrewList,
    this.movieAwards,
    this.awardOpts,
  }) : super(key: key);

  @override
  _AddMovieState createState() =>
      _AddMovieState(movie, crewEdit, movieCrewList, movieAwards, awardOpts);
}

// ADD MOVIE FIRST PAGE
class _AddMovieState extends State<AddMovie> {
  final Movie movie;
  final List<List<Crew>> crewEdit;
  final List<Crew> movieCrewList;
  final List<Award> movieAwards;
  final List<Award> awardOpts;

  _AddMovieState(this.movie, this.crewEdit, this.movieCrewList,
      this.movieAwards, this.awardOpts);

  // Local State Variable/s
  bool _saving = false;
  int movieId;
  String test;
  var currentUser;
  var mnl;

  // MOVIE FIELD CONTROLLERS
  DateTime _date;
  final titleController = TextEditingController();
  final synopsisController = TextEditingController();
  final runtimeController = TextEditingController();
  final dateController = TextEditingController();
  final roleController = TextEditingController();
  final linesController = TextEditingController();

  // MOVIE FIELD FOCUSNODES
  final titleNode = FocusNode();
  final synopsisNode = FocusNode();
  final runtimeNode = FocusNode();
  final dateNode = FocusNode();
  final roleNode = FocusNode();
  final directorNode = FocusNode();
  final writerNode = FocusNode();
  final addActorNode = FocusNode();
  final linesNode = FocusNode();

  // MOVIE FORMKEYS
  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // MOVIE SCROLL CONTROLLERS FOR LISTVIEW
  final ScrollController actorController = new ScrollController();

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // LISTS FOR ADD MOVIE
  List<String> filmGenres = []; // Genre(s) -- saved as strings
  List<Crew> directors = []; // Director(s)
  List<Crew> writers = []; // Writer(s)
  List<dynamic> genres = [];
  List<Crew> crewList = [];

  // Dynamic Widget Lists
  List<MediaWidget> posterList = [];
  List<MediaWidget> galleryList = [];
  List<MediaWidget> trailerList = [];
  List<MediaWidget> audioList = [];
  List<LineWidget> lineList = []; // Iconic Lines
  List<ActorWidget> actorList = [];
  List<AwardWidget> awardList = [];

  // Filtered Lists for Display in Review Step
  List<MediaWidget> filteredPosterList = [];
  List<MediaWidget> filteredGalleryList = [];
  List<MediaWidget> filteredTrailerList = [];
  List<MediaWidget> filteredAudioList = [];
  List<ActorWidget> filteredActors = []; // dynamic list with only saved values
  List<AwardWidget> filteredAwards = []; // dynamic list with only saved values
  List<LineWidget> filteredLines = []; // dynamic list with only saved values

  // EDIT MOVIE LISTS
  List<int> postersToDelete = []; // for poster edit
  List<int> galleryToDelete = []; // for gallery edit
  List<int> trailersToDelete = []; // for trailer edit
  List<int> audiosToDelete = []; // for poster edit
  List<int> directorsToDelete = [];
  List<int> writersToDelete = [];
  List<int> actorsToDelete = [];
  List<int> linesToDelete = [];
  List<String> genresToDelete = [];
  List<int> awardsToDelete = [];
  List<Award> awardOptions = [];

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Mga Basic na Detalye",
    "Media",
    "Mga Personalidad",
    "Mga Award",
    "Mga Sumikat na Linya",
    "Review"
  ];

  // Function: FETCH GENRES
  List<String> genreFromJson(String str) =>
      List<String>.from(json.decode(str).map((x) => x['genre']));

  // fetch genre from API
  void fetchGenres() async {
    final response = await http.get(Config.api + 'genres/');

    if (response.statusCode == 200) {
      // map json to Genre type
      genres = genreFromJson(response.body);
    }
  }

  Future<bool> onBackPress() async {
    // used in onwillpopscope function
    var response = await _dialogService.showConfirmationDialog(
        title: "Confirm cancellation",
        cancelTitle: "No",
        confirmationTitle: "Yes",
        description: "Are you sure that you want to close the form?");
    if (response.confirmed == true) {
      setState(() {
        // clears list para pag binalikan sya empty na ulit
        rolesFilter.value = [];
        actorsFilter = [];
        awardsFilter = [];
        movieGallery = [];
        posters = [];
        trailers = [];
        audios = [];
      });
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  // Function: calls viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();
    crewList = await model.getAllCrew(mode: "form");
  }

  // Function: Shows datepicker and update value of Date
  Future<Null> _selectDate(BuildContext context) async {
    DateTime _datePicker = await showDatePicker(
        context: context,
        initialDate: _date == null ? DateTime.now() : _date,
        firstDate: DateTime(1900),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.day,
        builder: (BuildContext context, Widget child) {
          return child;
        });

    if (_datePicker != null && _datePicker != _date) {
      setState(() {
        _date = _datePicker;
        // dateController.text = DateFormat("MMM. d, y", "fil").format(
        //         TZDateTime.from(_date, tz.getLocation('Asia/Manila'))) ??
        // '';
        dateController.text =
            DateFormat("MMMM d, y", "fil").format(_date) ?? '';
      });
    }
  }

  // Function: get image using image picker for movie poster
  getPosters() async {
    FocusScope.of(context).unfocus();

    // get posters, filter for duplicates, and iterate through them and add to list view builder for gallery

    // (1) Get Photo/s and/or videos
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      List imagePaths =
          posters.isNotEmpty ? posters.map((img) => img.path).toList() : [];

      // filter for duplicates
      List filtered = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        } else {
          Fluttertoast.showToast(msg: 'File already exists.');
        }
      }).toList();

      // iterate and add to list view builder
      if (filtered.isNotEmpty) {
        setState(() {
          for (var i = 0; i < filtered.length; i++) {
            if (filtered[i] != null) {
              posters.add(filtered[i]);

              /// posters list -- stores stored files ?

              // add photo widget to list
              posterList.add(MediaWidget(
                  category: "movie",
                  item: new MediaFile(
                      file: filtered[i], category: "movie", type: "poster"),
                  open: ValueNotifier<bool>(true)));
            }
          }
        });
      }
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
    }
  }

  // Function: Display Posters in the Review Step
  Widget displayPosters() {
    filteredPosterList = posterList
        // .where((p) => p.item.saved == true)  -- commented out to include existing media
        .where((p) => p.item.saved == true || p.item.url != null)
        .toList();

    return Column(
      children: [
        filteredPosterList.length != 0
            ? Container(
                margin: EdgeInsets.only(bottom: 15),
                alignment: Alignment.topLeft,
                child: Text("Mga Poster: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              )
            : SizedBox(),
        filteredPosterList.length != 0
            ? Column(
                children: filteredPosterList.map((p) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    color: Colors.white,
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                            child: Container(
                              alignment: Alignment.centerLeft,
                              height: 100,
                              width: 80,
                              child: p.item.file != null
                                  ? Image.file(
                                      p.item.file,
                                      width: 80,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      placeholder: (context, url) => Container(
                                        alignment: Alignment.center,
                                        width: 80,
                                        height: 100,
                                        child: Image.network(p.item.url,
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
                                          child: Image.network(
                                              Config.imgNotFound,
                                              width: 80,
                                              height: 100,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      imageUrl:
                                          p.item.url ?? Config.imgNotFound,
                                      width: 80,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => p.item.file != null
                                      ? FullPhotoT(
                                          type: 'path', file: p.item.file)
                                      : FullPhotoT(
                                          type: 'network', url: p.item.url),
                                ),
                              );
                            }),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                              p.item.description ?? "Walang description",
                              style: TextStyle(
                                  color: p.item.description == null
                                      ? Colors.black38
                                      : Colors.black,
                                  fontStyle: p.item.description == null
                                      ? FontStyle.italic
                                      : FontStyle.normal)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : SizedBox(),
        filteredPosterList.length != 0 ? SizedBox(height: 15) : SizedBox(),
      ],
    );
  }

  // Function: adds MediaWidget in the ListView builder for Gallery
  addtoGallery() async {
    FocusScope.of(context).unfocus();

    // get media, filter for duplicates, and iterate through them and add to list view builder for gallery

    // (1) Get Photo/s and/or videos
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result != null) {
      List imagePaths = movieGallery.isNotEmpty
          ? movieGallery.map((img) => img.path).toList()
          : [];

      // filter for duplicates
      List filtered = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        } else {
          Fluttertoast.showToast(msg: 'File already exists.');
        }
      }).toList();

      // iterate and add to list view builder
      if (filtered.isNotEmpty) {
        setState(() {
          for (var i = 0; i < filtered.length; i++) {
            if (filtered[i] != null) {
              movieGallery.add(filtered[i]);

              // add photo widget to list
              galleryList.add(MediaWidget(
                  category: "movie",
                  item: new MediaFile(
                      file: filtered[i], category: "movie", type: "gallery"),
                  open: ValueNotifier<bool>(true)));
            }
          }
        });
      }
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No media selected.');
    }
  }

  // Function: Display DP in the Review Step
  Widget displayGallery() {
    filteredGalleryList = galleryList
        .where((g) => g.item.saved == true || g.item.url != null)
        .toList();

    return Column(
      children: [
        filteredGalleryList.length != 0
            ? Container(
                margin: EdgeInsets.only(bottom: 15),
                alignment: Alignment.topLeft,
                child: Text("Gallery: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              )
            : SizedBox(),
        filteredGalleryList.length != 0
            ? Column(
                children: filteredGalleryList.map((g) {
                  return Column(
                    children: [
                      (g.item.file != null &&
                                  lookupMimeType(g.item.file.path)
                                          .startsWith('video/') ==
                                      true) ||
                              (g.item.url != null &&
                                  !g.item.url.contains('/image/upload'))
                          ? Container(
                              padding: EdgeInsets.all(10),
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.item.file != null
                                          ? g.item.file.path.split('/').last
                                          : g.item.url,
                                      style: TextStyle(color: Colors.blue),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (g.item.file != null &&
                                        lookupMimeType(g.item.file.path)
                                                .startsWith('image/') ==
                                            true) ||
                                    (g.item.url != null &&
                                        g.item.url.contains('/image/upload'))
                                ? GestureDetector(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      height: 100,
                                      width: 80,
                                      child: g.item.file != null
                                          ? Image.file(
                                              g.item.file,
                                              width: 80,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : CachedNetworkImage(
                                              placeholder: (context, url) =>
                                                  Container(
                                                alignment: Alignment.center,
                                                width: 80,
                                                height: 100,
                                                child: Image.network(g.item.url,
                                                    fit: BoxFit.cover,
                                                    height: 100,
                                                    width: 80),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Material(
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: 80,
                                                  height: 100,
                                                  child: Image.network(
                                                      Config.imgNotFound,
                                                      width: 80,
                                                      height: 100,
                                                      fit: BoxFit.cover),
                                                ),
                                              ),
                                              imageUrl: g.item.url ??
                                                  Config.imgNotFound,
                                              width: 80,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              g.item.file != null
                                                  ? FullPhotoT(
                                                      type: 'path',
                                                      file: g.item.file)
                                                  : FullPhotoT(
                                                      type: "network",
                                                      url: g.item.url),
                                        ),
                                      );
                                    })
                                : SizedBox(),
                            (g.item.file != null &&
                                        lookupMimeType(g.item.file.path)
                                                .startsWith('image/') ==
                                            true) ||
                                    (g.item.url != null &&
                                        g.item.url.contains('/image/upload'))
                                ? SizedBox(width: 15)
                                : SizedBox(),
                            Expanded(
                              child: Text(
                                  g.item.description ?? "Walang description",
                                  style: TextStyle(
                                      color: g.item.description == null
                                          ? Colors.black38
                                          : Colors.black,
                                      fontStyle: g.item.description == null
                                          ? FontStyle.italic
                                          : FontStyle.normal)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              )
            : SizedBox(),
        filteredGalleryList.length != 0 ? SizedBox(height: 15) : SizedBox(),
      ],
    );
  }

  // Function: get videos for trailers
  getTrailers() async {
    FocusScope.of(context).unfocus();

    // get file, filter for duplicates, and iterate through them and add to list view builder for trailer

    // (1) Get Photo/s and/or videos
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.video,
    );

    if (result != null) {
      List imagePaths =
          trailers.isNotEmpty ? trailers.map((img) => img.path).toList() : [];

      // filter for duplicates
      List filtered = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        } else {
          Fluttertoast.showToast(msg: 'File already exists.');
        }
      }).toList();

      // iterate and add to list view builder
      if (filtered.isNotEmpty) {
        setState(() {
          for (var i = 0; i < filtered.length; i++) {
            if (filtered[i] != null) {
              trailers.add(filtered[i]);

              // add photo widget to list
              trailerList.add(MediaWidget(
                  category: "movie",
                  item: new MediaFile(
                      file: filtered[i], category: "movie", type: "trailer"),
                  open: ValueNotifier<bool>(true)));
            }
          }
        });
      }
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
    }
  }

  // Function: Display Trailers in the Review Step
  Widget displayTrailers() {
    filteredTrailerList = trailerList
        .where((g) => g.item.saved == true || g.item.url != null)
        .toList();

    return Column(
      children: [
        filteredTrailerList.length != 0
            ? Container(
                margin: EdgeInsets.only(bottom: 15),
                alignment: Alignment.topLeft,
                child: Text("Mga Trailer: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              )
            : SizedBox(),
        filteredTrailerList.length != 0
            ? Column(
                children: filteredTrailerList.map((g) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.item.file != null
                                    ? g.item.file.path.split('/').last
                                    : g.item.url.split('/').last,
                                style: TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  g.item.description ?? "Walang description",
                                  style: TextStyle(
                                      color: g.item.description == null
                                          ? Colors.black38
                                          : Colors.black,
                                      fontStyle: g.item.description == null
                                          ? FontStyle.italic
                                          : FontStyle.normal)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              )
            : SizedBox(),
        filteredTrailerList.length != 0 ? SizedBox(height: 15) : SizedBox(),
      ],
    );
  }

  // Function: get audios
  getAudios() async {
    FocusScope.of(context).unfocus();

    // get file, filter for duplicates, and iterate through them and add to list view builder for trailer

    // (1) Get Photo/s and/or videos
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.audio,
    );

    if (result != null) {
      List imagePaths =
          audios.isNotEmpty ? audios.map((img) => img.path).toList() : [];

      // filter for duplicates
      List filtered = result.paths.map((path) {
        if (imagePaths.contains(path) == false) {
          return File(path);
        } else {
          Fluttertoast.showToast(msg: 'File already exists.');
        }
      }).toList();

      // iterate and add to list view builder
      if (filtered.isNotEmpty) {
        setState(() {
          for (var i = 0; i < filtered.length; i++) {
            if (filtered[i] != null) {
              audios.add(filtered[i]);

              // add photo widget to list
              audioList.add(MediaWidget(
                  category: "movie",
                  item: new MediaFile(
                      file: filtered[i], category: "movie", type: "audio"),
                  open: ValueNotifier<bool>(true)));
            }
          }
        });
      }
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
    }
  }

  // Function: Display Audios in the Review Step
  Widget displayAudios() {
    filteredAudioList = audioList
        .where((g) => g.item.saved == true || g.item.url != null)
        .toList();

    return Column(
      children: [
        filteredAudioList.length != 0
            ? Container(
                margin: EdgeInsets.only(bottom: 15),
                alignment: Alignment.topLeft,
                child: Text("Mga Audio: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              )
            : SizedBox(),
        filteredAudioList.length != 0
            ? Column(
                children: filteredAudioList.map((g) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.item.file != null
                                    ? g.item.file.path.split('/').last
                                    : g.item.url,
                                style: TextStyle(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  g.item.description ?? "Walang description",
                                  style: TextStyle(
                                      color: g.item.description == null
                                          ? Colors.black38
                                          : Colors.black,
                                      fontStyle: g.item.description == null
                                          ? FontStyle.italic
                                          : FontStyle.normal)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              )
            : SizedBox(),
        filteredAudioList.length != 0 ? SizedBox(height: 15) : SizedBox(),
      ],
    );
  }

  // Function: Display Actors in the Review Step
  Widget displayActors() {
    filteredActors =
        actorList.where((actor) => actor.crew.saved == true).toList();

    return Column(
      children: [
        filteredActors.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredActors.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Aktor: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        filteredActors.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredActors.map((actor) {
                    if (actor.crew.saved == true && actor.crew.crewId != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              new Expanded(
                                child: Text(actor.crew.name,
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: actor.crew.role.length != 0
                                ? Text(" - " + actor.crew.role.join(" / "),
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip)
                                : SizedBox(),
                          ),
                          SizedBox(height: 10)
                        ],
                      );
                    }
                  }).toList(),
                ),
              )
            : SizedBox(),
        filteredActors.length != 0 ? SizedBox() : SizedBox(height: 10),
      ],
    );
  }

  // Function: adds ActorWidget in the ListView builder
  addActor() {
    FocusScope.of(context).unfocus();
    setState(() {
      // add actor widget to list
      actorList.add(ActorWidget(
        crew: new Crew(),
        crewList: crewList,
        open: ValueNotifier<bool>(true),
        prevId: ValueNotifier<int>(0),
        updateLineList: updateLineList,
      ));
    });
  }

  // Function: Display Awards in the Review Step
  Widget displayAwards() {
    filteredAwards =
        awardList.where((award) => award.item.saved == true).toList();

    return Column(
      children: [
        filteredAwards.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Award: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        filteredAwards.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredAwards.map((award) {
                    if (award.item.saved == true) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(
                                    award.item.name +
                                        (award.item.year != null
                                            ? " (" + award.item.year + ") "
                                            : ""),
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: award.item.type != null
                                ? Text(
                                    " - " +
                                        (award.item.type == "nominated"
                                            ? "Nominado"
                                            : "Panalo"),
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip)
                                : SizedBox(),
                          ),
                          SizedBox(height: 10)
                        ],
                      );
                    }
                  }).toList(),
                ),
              )
            : SizedBox(),
      ],
    );
  }

  // Function: adds AwardWidget in the ListView builder
  addAward() {
    FocusScope.of(context).unfocus();

    setState(() {
      awardList.add(AwardWidget(
        awardOptions: awardOptions,
        item: new Award(),
        open: ValueNotifier<bool>(true),
        prevId: ValueNotifier<int>(0),
        type: "movie",
      ));
    });
  }

  void fetchAwards() async {
    var model = AwardViewModel();
    awardOptions = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'movie');
  }

  // Function: Display Famous Lines in the Review Step
  Widget displayLines() {
    filteredLines = lineList != null && lineList.isNotEmpty
        ? lineList
            .where((line) =>
                line.item.saved == true &&
                line.item.line != null &&
                line.item.line.trim() != "" &&
                line.item.role != null &&
                line.item.role.trim() != "" &&
                rolesFilter.value.contains(line.item.role))
            .toList()
        : [];

    return Column(
      children: [
        filteredLines.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredLines.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Sumikat na Linya: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        filteredLines.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredLines.map((f) {
                    if (f.item.saved == true) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text("'" + f.item.line + "'",
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: f.item.role != null
                                ? Text(" -" + f.item.role,
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip)
                                : SizedBox(),
                          ),
                          SizedBox(height: 10)
                        ],
                      );
                    }
                  }).toList(),
                ),
              )
            : SizedBox(),
        filteredLines.length != 0 ? SizedBox(height: 15) : SizedBox(),
      ],
    );
  }

  // Function: adds LineWidget in the ListView builder
  addLine() {
    FocusScope.of(context).unfocus();

    // extract the roles from the filteredActors list and flatten into a 1-dimensional array

    var rolesOptions =
        filteredActors.map((a) => a.crew.role).expand((i) => i).toList();

    setState(() {
      // update the values in rolesFilter
      rolesFilter = ValueNotifier<List>([]);
      rolesOptions.forEach((r) {
        if (rolesFilter.value.contains(r) == false) rolesFilter.value.add(r);
      });

      lineList.add(LineWidget(
        item: new Line(),
        open: ValueNotifier<bool>(true),
      ));
    });
  }

  void updateLineList(String roleToDelete) {
    // updates listview tree according to existence of roles
    // var index = lineList.indexWhere((a) => a.item.role == roleToDelete);

    // setState(() {
    //   if (index != -1) {
    //     var lineId = lineList[index].item.id;
    //     lineList.removeAt(index);
    //     // for edit: delete item from DB
    //     if (!linesToDelete.contains(lineId)) {
    //       linesToDelete.add(lineId);
    //     }
    //   }
    // });

    lineList.toList(growable: false).forEach((line) {
      if (line.item.role == roleToDelete &&
          !rolesFilter.value.contains(roleToDelete)) {
        if (line.item.id != null && !linesToDelete.contains(line.item.id)) {
          linesToDelete.add(line.item.id);
        }
        lineList.remove(line);
      }
    });
  }

  void updateActors() {
    var temp = actorList;
    actorList = [];
    actorList = temp;
  }

  @override
  void initState() {
    initializeDateFormatting();
    tz.initializeTimeZones();
    // in case user just closes the app and not click the back buttons
    rolesFilter.value = [];
    actorsFilter = [];
    awardsFilter = [];
    movieGallery = [];
    posters = [];

    currentUser = _authenticationService.currentUser;
    fetchCrew();
    fetchAwards();
    fetchGenres();
    directors = [];
    writers = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;

    final _scaffoldKey = GlobalKey<ScaffoldState>();
    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      onModelReady: (model) async {
        movieId = movie?.movieId ?? 0;

        // update controller's text field
        // Basic Details
        titleController.text = movie?.title ?? '';

        _date = movie?.releaseDate != null
            // ? DateTime.parse(movie?.releaseDate).add(Duration(days: 1))
            ? DateTime.parse(movie?.releaseDate)
            : null;

        dateController.text = movie?.releaseDate != null
            // ? DateFormat("MMM. d, y", "fil")
            //     .format(TZDateTime.from(_date, tz.getLocation('Asia/Manila')))
            ? DateFormat("MMMM d, y", "fil").format(_date)
            : '';
        synopsisController.text = movie?.synopsis ?? '';
        runtimeController.text = movie?.runtime?.toString() ?? '';

        filmGenres = List<String>.from(movie?.genre ?? []);

        // Mga Personalidad
        directors = crewEdit != null ? crewEdit[0] : [];
        writers = crewEdit != null ? crewEdit[1] : [];

        var aktors = crewEdit != null ? crewEdit[2] : [];

        for (var i = 0; i < aktors.length; i++) {
          actorsFilter.add(aktors[i].crewId);
          actorList.add(ActorWidget(
            crew: aktors[i],
            crewList: movieCrewList,
            open: ValueNotifier<bool>(false),
            updateLineList: updateLineList,
            prevId: ValueNotifier<int>(0),
          ));
        }

        // Mga Award
        var temp = movieAwards != null ? movieAwards : [];

        for (var i = 0; i < temp.length; i++) {
          awardsFilter.add(temp[i].id);
          awardList.add(AwardWidget(
            awardOptions: awardOpts,
            item: temp[i],
            open: ValueNotifier<bool>(false),
            prevId: ValueNotifier<int>(0),
            type: "movie",
          ));
        }

        // Mga Sumikat Na Linya
        var quotations = movie?.quotes != null ? movie?.quotes : [];
        filteredActors = actorList
            .where((actor) =>
                actor.crew.crewId != null && actor.crew.role.isNotEmpty)
            .toList();

        var rolesOptions =
            filteredActors.map((a) => a.crew.role).expand((i) => i).toList();

        // update the values in rolesFilter
        rolesFilter = ValueNotifier<List>([]);
        rolesOptions.forEach((r) {
          if (rolesFilter.value.contains(r) == false) rolesFilter.value.add(r);
        });

        // on edit, remove the roles that are no longer associated with the actors and save the id in the linesToDelete list
        for (var i = 0; i < quotations.length; i++) {
          lineList.add(LineWidget(
            item: quotations[i],
            open: ValueNotifier<bool>(false),
          ));
        }

        // MEDIA

        // Posters
        List<MediaFile> p = movie?.posters != null ? movie?.posters : [];
        for (var i = 0; i < p.length; i++) {
          p[i].category = "movie";
          posterList.add(MediaWidget(
              category: "movie", item: p[i], open: ValueNotifier<bool>(false)));
        }

        // Gallery
        List<MediaFile> g = movie?.gallery != null ? movie?.gallery : [];
        for (var i = 0; i < g.length; i++) {
          g[i].category = "movie";
          galleryList.add(MediaWidget(
              category: "movie", item: g[i], open: ValueNotifier<bool>(false)));
        }

        // Trailers
        List<MediaFile> t = movie?.trailers != null ? movie?.trailers : [];
        for (var i = 0; i < t.length; i++) {
          t[i].category = "movie";
          trailerList.add(MediaWidget(
              category: "movie", item: t[i], open: ValueNotifier<bool>(false)));
        }

        // Audios
        List<MediaFile> a = movie?.audios != null ? movie?.audios : [];
        for (var i = 0; i < a.length; i++) {
          a[i].category = "movie";
          audioList.add(MediaWidget(
              category: "movie", item: a[i], open: ValueNotifier<bool>(false)));
        }
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();

              var response = await _dialogService.showConfirmationDialog(
                  title: "Confirm cancellation",
                  cancelTitle: "No",
                  confirmationTitle: "Yes",
                  description: "Are you sure that you want to close the form?");
              if (response.confirmed == true) {
                setState(() {
                  actorsFilter = [];
                  awardsFilter = [];
                  rolesFilter.value = [];
                  movieGallery = [];
                  posters = [];
                  trailers = [];
                  audios = [];
                });
                await _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            movie == null ? "Magdagdag ng Pelikula" : "Mag-edit ng Pelikula",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: ModalProgressHUD(
            inAsyncCall: _saving,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: double.infinity,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30.0,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            MyStepper(
                              physics: ClampingScrollPhysics(),

                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons
                                    .image, // Mga Poster, Screenshot, at iba pang Media
                                Icons.recent_actors, // Mga Personalidad
                                Icons.emoji_events_outlined, // Mga Award
                                Icons
                                    .format_quote_outlined, // Mga Sumikat na Linya
                                Icons.grading // Review
                              ],
                              type: MyStepperType.vertical,
                              currentStep: currentStep,
                              onStepTapped: (step) async {
                                FocusScope.of(context).unfocus();
                                if (currentStep == 0) {
                                  // first step
                                  setState(() {
                                    if (_formKeys[currentStep]
                                        .currentState
                                        .validate()) {
                                      currentStep = step;
                                    }
                                  });
                                } else {
                                  // allow tapping of steps
                                  setState(() => currentStep = step);
                                }
                              },
                              onStepCancel: () {
                                FocusScope.of(context).unfocus();
                                if (currentStep != 0)
                                  setState(() => --currentStep);
                              }, // else do nothing
                              onStepContinue: () async {
                                FocusScope.of(context).unfocus();
                                if (currentStep + 1 != stepperTitle.length) {
                                  // do not allow user to continue to next step if inputs aren't filled out yet
                                  switch (currentStep) {
                                    case 0: // Mga Basic na Detalye
                                      setState(() {
                                        if (_formKeys[currentStep]
                                            .currentState
                                            .validate()) {
                                          titleNode.unfocus();
                                          dateNode.unfocus();
                                          runtimeNode.unfocus();
                                          synopsisNode.unfocus();

                                          currentStep++;
                                        }
                                      });
                                      break;

                                    case 1: // Mga Poster, Screenshot at iba pang Media
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        currentStep++;
                                      });
                                      break;
                                    case 2: // Mga Personalidad
                                      setState(() {
                                        FocusScope.of(context).unfocus();
                                        directorNode.unfocus();
                                        writerNode.unfocus();
                                        currentStep++;
                                      });
                                      break;
                                    case 3: // Mga Award
                                      FocusScope.of(context).unfocus();
                                      setState(() => currentStep++);
                                      break;
                                    case 4: // Mga Sumikat na Linya
                                      FocusScope.of(context).unfocus();
                                      setState(() => currentStep++);
                                      break;
                                  }
                                } else {
                                  // Review

                                  // last step

                                  var confirm = await _dialogService
                                      .showConfirmationDialog(
                                          title: "Confirm Details",
                                          cancelTitle: "No",
                                          confirmationTitle: "Yes",
                                          description:
                                              "Are you sure that you want to continue?");

                                  if (confirm.confirmed == true) {
                                    _saving =
                                        true; // set saving to true to trigger circular progress indicator

                                    // Directors
                                    List<int> directorsToSave = [];
                                    if (directors.isNotEmpty) {
                                      directorsToSave = directors
                                          .map((d) => d.crewId)
                                          .toList();

                                      // remove those to be deleted
                                      directorsToSave.removeWhere(
                                          (a) => directorsToDelete.contains(a));

                                      // remove those that are from the old list
                                      if (crewEdit != null) {
                                        var temp = crewEdit[0]
                                            .map((a) => a.crewId)
                                            .toList();
                                        directorsToSave.removeWhere(
                                            (a) => temp.contains(a));
                                      }
                                    }

                                    // Writers
                                    List<int> writersToSave = [];
                                    if (writers.isNotEmpty) {
                                      writersToSave =
                                          writers.map((w) => w.crewId).toList();
                                      writersToSave.removeWhere(
                                          (a) => writersToDelete.contains(a));

                                      // remove those that are from the old list
                                      if (crewEdit != null) {
                                        var temp = crewEdit[1]
                                            .map((a) => a.crewId)
                                            .toList();
                                        writersToSave.removeWhere(
                                            (a) => temp.contains(a));
                                      }
                                    }

                                    // Actors
                                    List<Crew> actorsToSave = [];
                                    if (filteredActors.isNotEmpty) {
                                      // actors that are not from the original actors list + actors updated (with existing id)
                                      actorsToSave = filteredActors
                                          .map((a) => a.crew)
                                          .toList();

                                      // remove the ids included in the actorsToDelete list.
                                      // the remaining items in the actorsToSave list will be the new and updated items
                                      actorsToSave.removeWhere((a) =>
                                          a.id != null &&
                                          actorsToDelete.contains(a.id));
                                    }

                                    // Awards
                                    List<Award> awardsToSave = [];
                                    if (filteredAwards.isNotEmpty) {
                                      awardsToSave = filteredAwards
                                          .map((a) => a.item)
                                          .toList();

                                      awardsToSave.removeWhere((a) =>
                                          awardsToDelete.contains(a.awardId));
                                    }

                                    // Famous Lines
                                    List<Line> linesToSave = [];
                                    if (filteredLines.isNotEmpty) {
                                      linesToSave = filteredLines
                                          .map((a) => a.item)
                                          .toList();

                                      linesToSave.removeWhere(
                                          (a) => linesToDelete.contains(a.id));
                                    }

                                    // Genres
                                    List<String> genresToSave = [];
                                    if (filmGenres.isNotEmpty) {
                                      genresToSave = filmGenres;

                                      genresToSave.removeWhere(
                                          (a) => genresToDelete.contains(a));
                                    }

                                    // Posters
                                    List<File> postersToSave = [];
                                    List<String> posterDesc = [];
                                    if (filteredPosterList.isNotEmpty) {
                                      var temp = filteredPosterList;

                                      temp.removeWhere(
                                          (a) => a.item.file == null);
                                      postersToSave =
                                          temp.map((a) => a.item.file).toList();

                                      posterDesc = temp
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    List<MediaFile> postersToUpdate = [];
                                    if (movie != null &&
                                        movie.posters != null &&
                                        movie.posters.isNotEmpty) {
                                      movie.posters.forEach((p) {
                                        if (!postersToDelete.contains(p.id))
                                          postersToUpdate.add(p);
                                      });
                                    }

                                    // Gallery
                                    List<File> galleryToSave = [];
                                    List<String> galleryDesc = [];
                                    if (filteredGalleryList.isNotEmpty) {
                                      var temp = filteredGalleryList;

                                      temp.removeWhere(
                                          (a) => a.item.file == null);
                                      galleryToSave =
                                          temp.map((a) => a.item.file).toList();

                                      galleryDesc = temp
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    List<MediaFile> galleryToUpdate = [];
                                    if (movie != null &&
                                        movie.gallery != null &&
                                        movie.gallery.isNotEmpty) {
                                      movie.gallery.forEach((p) {
                                        if (!galleryToDelete.contains(p.id))
                                          galleryToUpdate.add(p);
                                      });
                                    }

                                    // Trailers
                                    List<File> trailersToSave = [];
                                    List<String> trailerDesc = [];

                                    if (filteredTrailerList.isNotEmpty) {
                                      var temp = filteredTrailerList;

                                      temp.removeWhere(
                                          (a) => a.item.file == null);
                                      trailersToSave =
                                          temp.map((a) => a.item.file).toList();

                                      trailerDesc = temp
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    List<MediaFile> trailersToUpdate = [];
                                    if (movie != null &&
                                        movie.trailers != null &&
                                        movie.trailers.isNotEmpty) {
                                      movie.trailers.forEach((p) {
                                        if (!trailersToDelete.contains(p.id))
                                          trailersToUpdate.add(p);
                                      });
                                    }

                                    // Audio
                                    List<File> audiosToSave = [];
                                    List<String> audioDesc = [];

                                    if (filteredAudioList.isNotEmpty) {
                                      var temp = filteredAudioList;

                                      temp.removeWhere(
                                          (a) => a.item.file == null);
                                      audiosToSave =
                                          temp.map((a) => a.item.file).toList();

                                      audioDesc = temp
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    List<MediaFile> audiosToUpdate = [];
                                    if (movie != null &&
                                        movie.audios != null &&
                                        movie.audios.isNotEmpty) {
                                      movie.audios.forEach((p) {
                                        if (!audiosToDelete.contains(p.id))
                                          audiosToUpdate.add(p);
                                      });
                                    }

                                    final response = await model.addMovie(
                                      title: titleController.text,
                                      synopsis: synopsisController.text,
                                      movieId: movieId,
                                      releaseDate: _date != null
                                          ? _date.toUtc().toString()
                                          : '',
                                      runtime: runtimeController.text,
                                      genre: genresToSave,
                                      directors: directorsToSave,
                                      writers: writersToSave,
                                      actors: actorsToSave,
                                      awards: awardsToSave,
                                      posters: postersToSave,
                                      posterDesc: posterDesc,
                                      gallery: galleryToSave,
                                      galleryDesc: galleryDesc,
                                      trailers: trailersToSave,
                                      trailerDesc: trailerDesc,
                                      lines: linesToSave,
                                      audios: audiosToSave,
                                      audioDesc: audioDesc,
                                      addedBy: currentUser.userId,

                                      // for edit purposes:
                                      postersToDelete: postersToDelete,
                                      galleryToDelete: galleryToDelete,
                                      trailersToDelete: trailersToDelete,
                                      audiosToDelete: audiosToDelete,
                                      directorsToDelete: directorsToDelete,
                                      writersToDelete: writersToDelete,
                                      actorsToDelete: actorsToDelete,
                                      linesToDelete: linesToDelete,
                                      awardsToDelete: awardsToDelete,
                                      genresToDelete: genresToDelete,

                                      // edit -- update description of existing media
                                      postersToUpdate: postersToUpdate,
                                      galleryToUpdate: galleryToUpdate,
                                      trailersToUpdate: trailersToUpdate,
                                      audiosToUpdate: audiosToUpdate,
                                    );

                                    // when response is returned, stop showing circular progress indicator
                                    if (response != 0) {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show success snackbar

                                      // movieId != 0
                                      //     ? _scaffoldKey.currentState
                                      //         .showSnackBar(mySnackBar(
                                      //             context,
                                      //             'Movie updated successfully.',
                                      //             Colors.green))

                                      //     : _scaffoldKey.currentState
                                      //         .showSnackBar(mySnackBar(
                                      //             context,
                                      //             'Movie added successfully.',
                                      //             Colors.green));

                                      Fluttertoast.showToast(
                                          msg: movieId != 0
                                              ? 'Movie updated successfully.'
                                              : 'Movie added successfully.',
                                          backgroundColor: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 16);

                                      _saving =
                                          true; // set saving to true to trigger circular progress indicator

                                      // get movie using id redirect to detail view using response
                                      var movie = await model.getOneMovie(
                                          movieId: response);

                                      if (movie != null) {
                                        _saving =
                                            false; // set saving to false to trigger circular progress indicator
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          movieId != 0
                                              ? Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MovieView(
                                                            movieId:
                                                                movie.movieId),
                                                  ),
                                                )
                                              : Navigator.pop(context,
                                                  []); // --- this is wrong for add movie since it will only go back to dashboard
                                        });
                                      }
                                    } else {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show error snackbar
                                      // _scaffoldKey.currentState.showSnackBar(
                                      //     mySnackBar(
                                      //         context,
                                      //         'Something went wrong. Check your inputs and try again.',
                                      //         Colors.red));

                                      Fluttertoast.showToast(
                                          msg:
                                              'Something went wrong. Check your inputs and try again.',
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          fontSize: 16);
                                    }
                                  }
                                }
                              },
                              steps: [
                                for (var i = 0; i < stepperTitle.length; i++)
                                  MyStep(
                                    title: Text(
                                      stepperTitle[i],
                                      style: TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                    isActive: i <= currentStep,
                                    state: i == currentStep
                                        ? MyStepState.editing
                                        : i < currentStep
                                            ? MyStepState.complete
                                            : MyStepState.indexed,
                                    content: Container(
                                      // maxHeight: 450,
                                      child: SingleChildScrollView(
                                        child: Form(
                                            key: _formKeys[i],
                                            child: getContent(i)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getContent(int index) {
    switch (index) {
      case 0: // Mga Basic na Detalye
        return Container(
          child: Column(
            children: [
              SizedBox(height: 15),
              // MOVIE TITLE
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  // autofocus: true,
                  focusNode: titleNode,
                  textCapitalization: TextCapitalization.words,
                  controller: titleController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    dateNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Pamagat *",
                    contentPadding: EdgeInsets.all(10),
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                  ),
                  validator: (value) {
                    if (value.isEmpty || value == null) {
                      return 'Required ang field na ito.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: Stack(
                  children: [
                    TextFormField(
                      readOnly: true,
                      focusNode: dateNode,
                      controller: dateController,
                      keyboardType: TextInputType.datetime,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onTap: _date == null
                          ? () {
                              _selectDate(context);
                            }
                          : () => null,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Petsa ng Paglabas",
                        contentPadding: EdgeInsets.all(10),
                      ),
                      onFieldSubmitted: (val) {
                        runtimeNode.requestFocus();
                      },
                    ),
                    _date != null
                        ? PositionedDirectional(
                            top: 10,
                            end: 10,
                            bottom: 10,
                            child: GestureDetector(
                              child: Icon(Icons.close_outlined,
                                  color: Color.fromRGBO(150, 150, 150, 1)),
                              onTap: () {
                                setState(() {
                                  _date = null;
                                  dateController.text = "";
                                });
                              },
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // RUNTIME
              Container(
                color: Color.fromRGBO(240, 240, 240, 1),
                child: TextFormField(
                    focusNode: runtimeNode,
                    controller: runtimeController,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: "Runtime (minuto)",
                      contentPadding: EdgeInsets.all(10),
                    ),
                    onFieldSubmitted: (val) {
                      synopsisNode.requestFocus();
                    }),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: synopsisNode,
                  controller: synopsisController,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Buod *",
                    contentPadding: EdgeInsets.all(10),
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                  ),
                  validator: (value) {
                    if (value.isEmpty || value == null) {
                      return 'Required ang field na ito.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(240, 240, 240, 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TestChipsInput(
                              initialValue: filmGenres,
                              textCapitalization: TextCapitalization.words,
                              enabled: true,
                              textStyle: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 16),
                              decoration: const InputDecoration(
                                labelText: 'Pumili ng genre',
                                contentPadding: EdgeInsets.all(10),
                              ),
                              findSuggestions: (String query) {
                                setState(() {
                                  test = query;
                                });
                                if (query.isNotEmpty) {
                                  var lowercaseQuery = query.toLowerCase();
                                  return genres.where((item) {
                                    return !filmGenres
                                            .map((d) => d)
                                            .toList()
                                            .contains(item) &&
                                        item
                                            .toLowerCase()
                                            .contains(query.toLowerCase());
                                  }).toList(growable: false)
                                    ..sort((a, b) => a
                                        .toLowerCase()
                                        .indexOf(lowercaseQuery)
                                        .compareTo(b
                                            .toLowerCase()
                                            .indexOf(lowercaseQuery)));
                                }
                                return [];
                              },
                              submittedText: test != null
                                  ? test.trimLeft().trimRight()
                                  : "",
                              onChanged: (data) {
                                var newList = List<String>.from(data);
                                setState(() {
                                  filmGenres = newList;
                                });
                              },
                              chipBuilder: (context, state, c) {
                                return InputChip(
                                  key: ObjectKey(c),
                                  label: Text(c),
                                  onDeleted: () {
                                    var genreLC = c.toLowerCase();
                                    if (movie != null &&
                                        movie.genre
                                            .map((g) => g.toLowerCase())
                                            .toList()
                                            .contains(genreLC)) {
                                      // for edit: delete item from DB
                                      if (!genresToDelete
                                          .map((g) => g.toLowerCase())
                                          .toList()
                                          .contains(genreLC)) {
                                        genresToDelete.add(c);
                                      }
                                    }
                                    return state.deleteChip(c);
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              },
                              suggestionBuilder: (context, state, c) {
                                return ListTile(
                                    key: ObjectKey(c),
                                    title: Text(c),
                                    onTap: () {
                                      var genreLC = c.toLowerCase();
                                      if (genresToDelete
                                          .map((g) => g.toLowerCase())
                                          .toList()
                                          .contains(genreLC)) {
                                        genresToDelete.remove(c);
                                      }
                                      return state.selectSuggestion(c);
                                    });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                        "Pindutin ang 'ENTER' para magdagdag ng genre na wala sa listahan."),
                    SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 1: // Poster, Trailer, Gallery and Audio
        return Container(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text('Mga Poster',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              Container(
                  child: FlatButton(
                color: Color.fromRGBO(240, 240, 240, 1),
                onPressed: getPosters,
                child: Text(" Dagdagan"),
              )),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: posterList.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: posterList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(posterList[i]),
                            children: [
                              posterList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              // update poster list by removing the image that is previously saved and recorded
                                              if (posterList[i].item.file !=
                                                  null) {
                                                List imagePaths = posters
                                                        .isNotEmpty
                                                    ? posters
                                                        .map((img) => img.path)
                                                        .toList()
                                                    : [];

                                                // loop through posters' paths
                                                if (imagePaths.contains(
                                                    posterList[i]
                                                        .item
                                                        .file
                                                        .path)) {
                                                  posters.removeWhere((f) =>
                                                      posterList[i]
                                                          .item
                                                          .file
                                                          .path ==
                                                      f.path);
                                                }
                                              } else if (posterList[i]
                                                          .item
                                                          .url !=
                                                      null &&
                                                  posterList[i].item.id !=
                                                      null) {
                                                // delete previously uploaded file
                                                postersToDelete
                                                    .add(posterList[i].item.id);
                                              }
                                              posterList.removeAt(i);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // posterList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //     width: 140,
              //     child: FlatButton(
              //       color: Color.fromRGBO(240, 240, 240, 1),
              //       onPressed: getPosters,
              //       child: Row(
              //         children: [Icon(Icons.camera_alt), Text(" Dagdagan")],
              //       ),
              //     )),
              SizedBox(height: 15),
              Text('Mga Trailer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              Container(
                child: FlatButton(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  onPressed: getTrailers,
                  child: Text(" Dagdagan"),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: trailerList.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: trailerList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(trailerList[i]),
                            children: [
                              trailerList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              // update poster list by removing the image that is previously saved and recorded
                                              if (trailerList[i].item.file !=
                                                  null) {
                                                List imagePaths = trailers
                                                        .isNotEmpty
                                                    ? trailers
                                                        .map((img) => img.path)
                                                        .toList()
                                                    : [];

                                                // loop through trailers' paths
                                                if (imagePaths.contains(
                                                    trailerList[i]
                                                        .item
                                                        .file
                                                        .path)) {
                                                  trailers.removeWhere((f) =>
                                                      trailerList[i]
                                                          .item
                                                          .file
                                                          .path ==
                                                      f.path);
                                                }
                                              } else if (trailerList[i]
                                                          .item
                                                          .url !=
                                                      null &&
                                                  trailerList[i].item.id !=
                                                      null) {
                                                // delete previously uploaded file
                                                trailersToDelete.add(
                                                    trailerList[i].item.id);
                                              }
                                              trailerList.removeAt(i);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // trailerList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //     width: 140,
              //     child: FlatButton(
              //       color: Color.fromRGBO(240, 240, 240, 1),
              //       onPressed: getTrailers,
              //       child: Row(
              //         children: [Icon(Icons.videocam), Text(" Dagdagan")],
              //       ),
              //     )),
              SizedBox(
                height: 15,
              ),
              Text('Gallery',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              Container(
                child: FlatButton(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  onPressed: addtoGallery,
                  child: Text(" Dagdagan"),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: galleryList.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: galleryList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(galleryList[i]),
                            children: [
                              galleryList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              // update gallery list by removing the image that is previously saved and recorded

                                              if (galleryList[i].item.file !=
                                                  null) {
                                                List imagePaths = movieGallery
                                                        .isNotEmpty
                                                    ? movieGallery
                                                        .map((img) => img.path)
                                                        .toList()
                                                    : [];

                                                // loop through gallery's paths
                                                if (imagePaths.contains(
                                                    galleryList[i]
                                                        .item
                                                        .file
                                                        .path)) {
                                                  movieGallery.removeWhere(
                                                      (f) =>
                                                          galleryList[i]
                                                              .item
                                                              .file
                                                              .path ==
                                                          f.path);
                                                }
                                              } else if (galleryList[i]
                                                          .item
                                                          .url !=
                                                      null &&
                                                  galleryList[i].item.id !=
                                                      null) {
                                                // delete previously uploaded file
                                                galleryToDelete.add(
                                                    galleryList[i].item.id);
                                              }
                                              galleryList.removeAt(i);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // galleryList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //     width: 140,
              //     child: FlatButton(
              //       color: Color.fromRGBO(240, 240, 240, 1),
              //       onPressed: addtoGallery,
              //       child: Row(
              //         children: [Icon(Icons.camera_alt), Text(" Dagdagan")],
              //       ),
              //     )),
              SizedBox(
                height: 15,
              ),
              Text('Mga Audio',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              Container(
                child: FlatButton(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  onPressed: getAudios,
                  child: Text(" Dagdagan"),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: audioList.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: audioList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(audioList[i]),
                            children: [
                              audioList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              // update poster list by removing the image that is previously saved and recorded

                                              if (audioList[i].item.file !=
                                                  null) {
                                                List imagePaths = audios
                                                        .isNotEmpty
                                                    ? audios
                                                        .map((img) => img.path)
                                                        .toList()
                                                    : [];

                                                // loop through audios' paths
                                                if (imagePaths.contains(
                                                    audioList[i]
                                                        .item
                                                        .file
                                                        .path)) {
                                                  audios.removeWhere((f) =>
                                                      audioList[i]
                                                          .item
                                                          .file
                                                          .path ==
                                                      f.path);
                                                }
                                              } else if (audioList[i]
                                                          .item
                                                          .url !=
                                                      null &&
                                                  audioList[i].item.id !=
                                                      null) {
                                                // delete previously uploaded file
                                                audiosToDelete
                                                    .add(audioList[i].item.id);
                                              }
                                              audioList.removeAt(i);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // audioList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //     width: 140,
              //     child: FlatButton(
              //       color: Color.fromRGBO(240, 240, 240, 1),
              //       onPressed: getAudios,
              //       child: Row(
              //         children: [Icon(Icons.library_music), Text(" Dagdagan")],
              //       ),
              //     )),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        );
      case 2: // Mga Personalidad
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text('Mga Direktor:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ChipsInput(
                  initialValue: directors,
                  focusNode: directorNode,
                  nextFocusNode: writerNode,
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Pumili ng direktor',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  findSuggestions: (String query) {
                    if (query.isNotEmpty) {
                      var lowercaseQuery = query.toLowerCase();
                      return crewList.where((item) {
                        return !directors
                                .map((d) => d.crewId)
                                .toList()
                                .contains(item.crewId) &&
                            item.name
                                .toLowerCase()
                                .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(
                                b.name.toLowerCase().indexOf(lowercaseQuery)));
                    } else {
                      return [];
                    }
                  },
                  onChanged: (data) {
                    var newList = List<Crew>.from(data);
                    directors = newList;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.name),
                      onDeleted: () {
                        if (crewEdit != null &&
                            crewEdit[0]
                                .map((direk) => direk.crewId)
                                .toList()
                                .contains(c.crewId)) {
                          // for edit: delete item from DB
                          if (directorsToDelete.contains(c.crewId) == false) {
                            directorsToDelete.add(c.crewId);
                          }
                        }
                        return state.deleteChip(c);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                        key: ObjectKey(c),
                        title: Text(c.name),
                        onTap: () {
                          if (directorsToDelete.contains(c.crewId)) {
                            directorsToDelete.remove(c.crewId);
                          }
                          return state.selectSuggestion(c);
                        });
                  },
                ),
              ),
              SizedBox(height: 10),
              Text('Mga Manunulat:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(240, 240, 240, 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ChipsInput(
                  initialValue: writers,
                  focusNode: writerNode,
                  nextFocusNode: addActorNode,
                  keyboardAppearance: Brightness.dark,
                  textCapitalization: TextCapitalization.words,
                  enabled: true,
                  textStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Pumili ng manunulat',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  findSuggestions: (String query) {
                    if (query.isNotEmpty) {
                      var lowercaseQuery = query.toLowerCase();
                      return crewList.where((item) {
                        return !writers
                                .map((w) => w.crewId)
                                .toList()
                                .contains(item.crewId) &&
                            item.name
                                .toLowerCase()
                                .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(
                                b.name.toLowerCase().indexOf(lowercaseQuery)));
                    }
                    return [];
                  },
                  onChanged: (data) {
                    var newList = List<Crew>.from(data);
                    writers = newList;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.name),
                      onDeleted: () {
                        if (crewEdit != null &&
                            crewEdit[1]
                                .map((w) => w.crewId)
                                .toList()
                                .contains(c.crewId)) {
                          // for edit: delete item from DB
                          if (writersToDelete.contains(c.crewId) == false) {
                            writersToDelete.add(c.crewId);
                          }
                        }
                        return state.deleteChip(c);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                        key: ObjectKey(c),
                        title: Text(c.name),
                        onTap: () {
                          if (writersToDelete.contains(c.crewId)) {
                            writersToDelete.remove(c.crewId);
                          }
                          return state.selectSuggestion(c);
                        });
                  },
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mga Aktor:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                child: FlatButton(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: addActor,
                    child: Text(" Dagdagan")),
              ),

              ListView.builder(
                  itemCount: actorList.length,
                  reverse: true,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: actorList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(actorList[i]),
                            children: [
                              actorList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              if (actorList[i].crew.role !=
                                                      null &&
                                                  actorList[i]
                                                      .crew
                                                      .role
                                                      .isNotEmpty) {
                                                // updates listview tree according to existence of roles
                                                lineList
                                                    .toList(growable: false)
                                                    .forEach((line) {
                                                  if (actorList[i].crew.role !=
                                                          null &&
                                                      actorList[i]
                                                          .crew
                                                          .role
                                                          .isNotEmpty &&
                                                      actorList[i]
                                                          .crew
                                                          .role
                                                          .contains(
                                                              line.item.role)) {
                                                    if (line.item.id != null &&
                                                        !linesToDelete.contains(
                                                            line.item.id)) {
                                                      linesToDelete
                                                          .add(line.item.id);
                                                    }
                                                    lineList.remove(line);
                                                  }
                                                });

                                                rolesFilter.value.remove(
                                                    actorList[i].crew.role);
                                              } // -- added

                                              actorsFilter.remove(
                                                  actorList[i].crew.crewId);

                                              // if the id of the item to be deleted in ui exists in crewEdit, this means existing na sya
                                              // previously saved in the database
                                              // remove from DB by adding to the actorsToDelete list
                                              // for edit: delete item from DB
                                              if (actorList[i].crew.id !=
                                                      null &&
                                                  !actorsToDelete.contains(
                                                      actorList[i].crew.id) &&
                                                  (crewEdit != null &&
                                                      crewEdit[2]
                                                          .map((c) => c
                                                              .id) // from c.crewId
                                                          .toList()
                                                          .contains(actorList[i]
                                                              .crew
                                                              .id))) {
                                                actorsToDelete
                                                    .add(actorList[i].crew.id);
                                              } else if (actorList[i]
                                                          .prevId
                                                          .value !=
                                                      null &&
                                                  actorList[i].prevId.value !=
                                                      0 &&
                                                  !actorsToDelete.contains(
                                                      actorList[i]
                                                          .prevId
                                                          .value) &&
                                                  (crewEdit != null &&
                                                      crewEdit[2]
                                                          .map((c) => c
                                                              .id) // from c.crewId
                                                          .toList()
                                                          .contains(actorList[i]
                                                              .prevId
                                                              .value))) {
                                                actorsToDelete.add(
                                                    actorList[i].prevId.value);
                                              }
                                              return actorList
                                                  .remove(actorList[i]);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // actorList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //   width: 140,
              //   child: actorList.isNotEmpty
              //       ? FlatButton(
              //           color: Color.fromRGBO(240, 240, 240, 1),
              //           onPressed: addActor,
              //           child: Row(
              //             children: [
              //               Icon(Icons.person_add_alt_1_outlined),
              //               Text(" Dagdagan")
              //             ],
              //           ),
              //         )
              //       : null,
              // ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 3: // Mga Award
        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  child: FlatButton(
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addAward,
                      child: Text(" Dagdagan"))),
              ListView.builder(
                  itemCount: awardList.length,
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: awardList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            key: ObjectKey(awardList[i]),
                            children: [
                              awardList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: TextButton(
                                          // padding: EdgeInsets.all(0),
                                          // color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              awardsFilter
                                                  .remove(awardList[i].item.id);

                                              if (awardList[i].item.awardId !=
                                                      null &&
                                                  !awardsToDelete.contains(
                                                      awardList[i]
                                                          .item
                                                          .awardId)) if (movieAwards !=
                                                      null &&
                                                  movieAwards
                                                      .map((a) => a.awardId)
                                                      .contains(awardList[i]
                                                          .item
                                                          .awardId)) {
                                                awardsToDelete.add(
                                                    awardList[i].item.awardId);
                                              } else if (awardList[i]
                                                          .prevId
                                                          .value !=
                                                      null &&
                                                  awardList[i].prevId.value !=
                                                      0 &&
                                                  !awardsToDelete.contains(
                                                      awardList[i]
                                                          .prevId
                                                          .value) &&
                                                  (movieAwards != null &&
                                                      movieAwards
                                                          .map((c) => c.awardId)
                                                          .toList()
                                                          .contains(awardList[i]
                                                              .prevId
                                                              .value))) {
                                                awardsToDelete.add(
                                                    awardList[i].prevId.value);
                                              }
                                              awardList.removeAt(i);
                                            });
                                          },
                                          child: Text('TANGGALIN',
                                              style: TextStyle(
                                                  color: Colors.black45)),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              // awardList.isNotEmpty
              //     ? SizedBox(
              //         height: 10,
              //       )
              //     : SizedBox(),
              // Container(
              //   width: 140,
              //   child: awardList.isNotEmpty
              //       ? FlatButton(
              //           color: Color.fromRGBO(240, 240, 240, 1),
              //           onPressed: addAward,
              //           child: Row(
              //             children: [
              //               Icon(Icons.emoji_events_outlined),
              //               Text(" Dagdagan")
              //             ],
              //           ),
              //         )
              //       : null,
              // ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 4: // Mga Sumikat na Linya

        // updates filteredactors list
        filteredActors =
            actorList.where((actor) => actor.crew.saved == true).toList();

        // // updates listview tree according to existence of roles
        // lineList.removeWhere((a) => !rolesFilter.value.contains(a.item.role));
        // if (lineList == null) lineList = [];

        return Container(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: filteredActors.isNotEmpty
                  ? FlatButton(
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addLine,
                      child: Text(" Dagdagan"))
                  : lineList.isEmpty && filteredActors.isEmpty
                      ? Text(
                          'Magdagdag ng aktor para ma-access ang step na ito',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      : SizedBox(),
            ),
            ListView.builder(
                itemCount: lineList.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (BuildContext context, int i) {
                  return ValueListenableBuilder(
                      valueListenable: lineList[i].open,
                      builder: (context, value, widget) {
                        return Stack(
                          key: ObjectKey(lineList[i]),
                          children: [
                            lineList[i],
                            value == true
                                ? Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      child: TextButton(
                                        // padding: EdgeInsets.all(0),
                                        // color: Colors.white,
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            // if the id of the item to be deleted in ui exists in crewEdit, this means existing na sya
                                            // previously saved in the database
                                            // remove from DB by adding to the linesToDelete list
                                            // for edit: delete item from DB
                                            if (lineList[i].item.id != null &&
                                                movie != null &&
                                                movie.quotes
                                                    .map((q) => q.id)
                                                    .toList()
                                                    .contains(
                                                        lineList[i].item.id) &&
                                                !linesToDelete.contains(
                                                    lineList[i].item.id)) {
                                              linesToDelete
                                                  .add(lineList[i].item.id);
                                            }
                                            lineList.removeAt(i);
                                          });
                                        },
                                        child: Text('TANGGALIN',
                                            style: TextStyle(
                                                color: Colors.black45)),
                                      ),
                                      alignment: Alignment.centerRight,
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        );
                      });
                }),
            // SizedBox(
            //   height: 10,
            // ),
            // Container(
            //   width: 140,
            //   child: lineList.isNotEmpty
            //       ? FlatButton(
            //           color: Color.fromRGBO(240, 240, 240, 1),
            //           onPressed: addLine,
            //           child: Row(
            //             children: [
            //               Icon(Icons.question_answer_outlined),
            //               Text(" Dagdagan")
            //             ],
            //           ),
            //         )
            //       : null,
            // ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
      case 5: // Review
        return Container(
          height: 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Color.fromRGBO(240, 240, 240, 1),
          ),
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text("Pamagat: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    titleController.text,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.clip,
                    softWrap: true,
                  ),
                ),
                SizedBox(height: 15),
                filmGenres.length != 0
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Mga Genre: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                filmGenres.length != 0
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                            children: filmGenres
                                .map<Widget>((str) => Container(
                                      margin: EdgeInsets.only(right: 3),
                                      child: Chip(
                                        label: Text(str),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                    ))
                                .toList()),
                      )
                    : SizedBox(),
                filmGenres.length != 0 ? SizedBox(height: 15) : SizedBox(),
                _date != null
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Petsa ng Paglabas: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                _date != null
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _date == null
                              ? ''
                              : DateFormat("MMMM d, y", "fil").format(_date),
                          // : DateFormat("MMM. d, y", "fil").format(
                          //     TZDateTime.from(
                          //         _date, tz.getLocation('Asia/Manila'))),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                _date != null ? SizedBox(height: 15) : SizedBox(),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text("Buod: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    synopsisController.text,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                displayPosters(),
                displayTrailers(),
                displayGallery(),
                displayAudios(),
                directors.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                directors.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Mga Direktor: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                directors.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                directors.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Column(
                            children: directors.map<Widget>((direk) {
                          return new Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(
                                  direk.name,
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.clip,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          );
                        }).toList()),
                      )
                    : SizedBox(),
                writers.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                writers.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Mga Manunulat: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                writers.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                writers.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Column(
                            children: writers.map<Widget>((writer) {
                          return new Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                child: Text(
                                  writer.name,
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.clip,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          );
                        }).toList()),
                      )
                    : SizedBox(),
                displayActors(),
                displayAwards(),
                displayLines(),
              ],
            ),
          ),
        );
    }
    return null;
  }
}

// Dynamic ActorWidget (Adding Actors and their respective roles)

class ActorWidget extends StatefulWidget {
  final List<Crew> crewList;
  final Crew crew;
  final open;
  final Function updateLineList;
  final ValueNotifier<int> prevId;

  const ActorWidget({
    Key key,
    this.crew,
    this.crewList,
    this.open,
    this.updateLineList,
    this.prevId,
  }) : super(key: key);

  @override
  ActorWidgetState createState() => ActorWidgetState();
}

class ActorWidgetState extends State<ActorWidget> {
  var temp;
  bool showError;
  List<Crew> actorId = [];

  @override
  void initState() {
    super.initState();
    showError = widget.crew.crewId != null &&
            widget.crew.role != null &&
            widget.crew.role.isNotEmpty
        ? false
        : true;
    widget.crew.saved = widget.crew.saved == null && widget.crew.crewId == null
        ? false
        : widget.crew.saved == null && widget.crew.id != null
            ? true
            : widget.crew.saved;
    if (widget.crew.crewId != null) {
      actorId = [widget.crew];
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.open.value == true
        ? Container(
            child: Column(children: [
            SizedBox(
              height: 15,
            ),
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(240, 240, 240, 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ChipsInput(
                initialValue: actorId,
                // initialValue: widget.crew.crewId != null ? [widget.crew] : [],
                maxChips: 1,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng aktor ',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  var filteredList = actorsFilter.length != 0
                      ? widget.crewList
                          .where((r) => !actorsFilter.contains(r.crewId))
                          .toList()
                      : widget.crewList;
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();

                    return filteredList.where((item) {
                      return !actorId
                              .map((d) => d.crewId)
                              .toList()
                              .contains(item.crewId) &&
                          item.name.toLowerCase().contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.name
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.name.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return [];
                },
                onChanged: (data) {
                  var newList = List<Crew>.from(data);
                  if (newList.length != 0) {
                    setState(() {
                      // widget.crew.id is intentionally left out
                      widget.crew.crewId = newList[0].crewId;
                      widget.crew.name = newList[0].name;
                      showError = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0
                          ? false
                          : true;
                      actorId = [newList[0]]; // newlist[0]
                      if (!actorsFilter.contains(newList[0].crewId)) {
                        actorsFilter.add(newList[0].crewId);
                      }
                    });
                  } else {
                    setState(() {
                      widget.crew.crewId = null;
                      widget.crew.name = null;
                      showError = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0
                          ? false
                          : true;
                      widget.crew.saved = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0 &&
                              widget.crew.saved == true
                          ? true
                          : false;
                      actorId = [];
                    });
                  }
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c != null ? c.name : ""),
                    onDeleted: () {
                      setState(() {
                        actorsFilter.remove(c.crewId);
                        widget.prevId.value = c.crewId;
                      });
                      return state.deleteChip(c);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.name),
                    onTap: () => {
                      if (!actorsFilter.contains(c.crewId))
                        {
                          setState(() {
                            actorsFilter.add(c.crewId);
                          })
                        },
                      state.selectSuggestion(c)
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Container(
              color: Color.fromRGBO(240, 240, 240, 1),
              child: TestChipsInput(
                initialValue: widget.crew.role != null ? widget.crew.role : [],
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  setState(() {
                    temp = query;
                  });
                  return [];
                },
                submittedText: temp != null ? temp.trimLeft().trimRight() : "",
                onChanged: (data) {
                  var newList = List<String>.from(data);

                  setState(() {
                    widget.crew.role = newList;
                    showError = widget.crew.crewId != null &&
                            widget.crew.role != null &&
                            widget.crew.role.length != 0
                        ? false
                        : true;
                    widget.crew.saved = widget.crew.crewId != null &&
                            widget.crew.role != null &&
                            widget.crew.role.length != 0 &&
                            widget.crew.saved == true
                        ? true
                        : false;
                  });
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c),
                    onDeleted: () {
                      setState(() {
                        if (rolesFilter.value.contains(c)) {
                          rolesFilter.value.remove(
                              c); // removes the deleted role from the role masterlist
                        }
                        widget.updateLineList(c);
                      });
                      return state.deleteChip(c);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return null;
                },
              ),
            ),
            SizedBox(height: 5),
            Text("Pindutin ang 'ENTER' para i-save ang role."),
            SizedBox(height: 15),
            showError == true
                ? Text('Required ang mga field ng Aktor at Role.',
                    style: TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic))
                : SizedBox(),
            showError == true ? SizedBox(height: 15) : SizedBox(),
            Container(
              child: TextButton(
                // padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                // color: Colors.white,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (widget.crew.crewId != null &&
                      widget.crew.role != null &&
                      widget.crew.role.isNotEmpty) {
                    setState(() {
                      // save to actors and roles list
                      widget.crew.saved = true;
                      widget.open.value = false;

                      widget.crew.role.forEach((a) {
                        if (!rolesFilter.value.contains(a))
                          rolesFilter.value.add(a);
                      });
                    });
                  } else {
                    setState(() {
                      widget.crew.saved = false;
                      showError = true;
                    });
                  }
                },
                child: Text('SAVE', style: TextStyle(color: Colors.blue)),
              ),
              alignment: Alignment.center,
            )
          ]))
        :
        // display this instead if widget.open == false
        Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              tileColor: Color.fromRGBO(240, 240, 240, 1),
              title: Text(
                  (widget.crew != null && widget.crew.crewId != null
                      ? widget.crew.name
                      : ""),
                  softWrap: true,
                  overflow: TextOverflow.clip),
              subtitle: Text(
                widget.crew.role != null && widget.crew.role.isNotEmpty
                    ? widget.crew.role.join(", ")
                    : "",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              trailing: GestureDetector(
                // child: Icon(Icons.edit_outlined, color: Colors.black87),
                child: Text('EDIT',
                    style: TextStyle(color: Colors.black54, fontSize: 16)),
                onTap: () {
                  setState(() {
                    widget.open.value = true;
                  });
                },
              ),
            ),
          );
  }
}
