import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/line.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/ui/widgets/award_widget.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/ui/widgets/line_widget.dart';
import 'package:mubidibi/ui/widgets/media_widget.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';

// For Dynamic Widgets
List<int> actorsFilter = []; // actors
List movieGallery = [];
List posters = [];
List trailers = [];
List audios = [];

// for line widget
ValueNotifier<List> rolesFilter = ValueNotifier<List>([]);

class AddMovie extends StatefulWidget {
  final Movie movie;
  final List<List<Crew>> crewEdit;

  AddMovie({Key key, this.movie, this.crewEdit}) : super(key: key);

  @override
  _AddMovieState createState() => _AddMovieState(movie, crewEdit);
}

// ADD MOVIE FIRST PAGE
class _AddMovieState extends State<AddMovie> {
  final Movie movie;
  final List<List<Crew>> crewEdit;

  _AddMovieState(this.movie, this.crewEdit);

  // Local State Variable/s
  bool _saving = false;
  int movieId;
  // List<DropdownMenuItem> genreItems = [];
  String test;
  var imageURI = ''; // for movie edit
  var currentUser;

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

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  // LISTS
  List<String> filmGenres = []; // Genre(s) -- saved as strings
  List<Crew> directors = []; // Director(s)
  List<Crew> writers = []; // Writer(s)
  List<DropdownMenuItem> crewItems = [];
  List<Crew> crewList = [];
  List<ActorWidget> filteredActors = []; // dynamic list with only saved values
  List<AwardWidget> filteredAwards = []; // dynamic list with only saved values
  List<LineWidget> filteredLines = []; // dynamic list with only saved values
  List<ActorWidget> actorList = [];
  List<AwardWidget> awardList = [];
  List<LineWidget> lineList = []; // Iconic Lines
  List<Award> awardOptions;
  List<dynamic> genres = [];
  List<MediaWidget> posterList = [];
  List<MediaWidget> filteredPosterList = [];
  List<MediaWidget> galleryList = [];
  List<MediaWidget> filteredGalleryList = [];
  List<MediaWidget> trailerList = [];
  List<MediaWidget> filteredTrailerList = [];
  List<MediaWidget> audioList = [];
  List<MediaWidget> filteredAudioList = [];

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Mga Basic na Detalye",
    "Mga Poster, Screenshot, at Ibang Media",
    "Mga Personalidad",
    "Mga Award",
    "Mga Sikat na Linya",
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
        rolesFilter.value = [];
        actorsFilter = []; // clears list para pag binalikan sya empty na ulit
        movieGallery = [];
        posters = [];
        trailers = [];
        audios = [];
      });
      await _navigationService.pop();
    }
    return Future.value(false);
  }

  // Function: calls viewmodel's getAllCrew method
  void fetchCrew() async {
    var model = CrewViewModel();

    crewList = await model.getAllCrew(mode: "form");
    // converts from List<Crew> to List<DropdownMenuItem>
    crewItems = crewList.map<DropdownMenuItem<dynamic>>((Crew value) {
      String name = value.firstName +
          (value.middleName != null ? " " + value.middleName : "") +
          (value.lastName != null ? " " + value.lastName : "") +
          (value.suffix != null ? " " + value.suffix : "");
      return DropdownMenuItem<dynamic>(
        key: ValueKey(value.crewId),
        value: name,
        child: Text(name),
      );
    }).toList();
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
        dateController.text = DateFormat("MMM. d, y").format(_date) ?? '';
      });
    }
  }

  // Function: get image using image picker for movie poster
  getPosters() async {
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
          print('Image already exists'); // FlutterToast or Snackbar
        }
      }).toList();

      // iterate and add to list view builder
      if (filtered.isNotEmpty) {
        setState(() {
          for (var i = 0; i < filtered.length; i++) {
            if (filtered[i] != null) {
              posters.add(filtered[i]);

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
      print('No image selected.');
    }
  }

  // Function: Display Posters in the Review Step
  Widget displayPosters() {
    filteredPosterList = posterList.where((p) => p.item.saved == true).toList();

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
                              child: Image.file(
                                p.item.file,
                                width: 80,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullPhotoT(
                                      type: 'path', file: p.item.file),
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
          print('File already exists.'); // FlutterToast or Snackbar
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
      print('No media selected.');
    }
  }

  // Function: Display DP in the Review Step
  Widget displayGallery() {
    filteredGalleryList =
        galleryList.where((g) => g.item.saved == true).toList();

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
                      g.item.file != null &&
                              lookupMimeType(g.item.file.path)
                                      .startsWith('video/') ==
                                  true
                          ? Container(
                              padding: EdgeInsets.all(10),
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      g.item.file.path.split('/').last,
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
                                    g.item.file == null
                                ? GestureDetector(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      height: 100,
                                      width: 80,
                                      child: Image.file(
                                        g.item.file,
                                        width: 80,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullPhotoT(
                                              type: 'path', file: g.item.file),
                                        ),
                                      );
                                    })
                                : SizedBox(),
                            (g.item.file != null &&
                                        lookupMimeType(g.item.file.path)
                                                .startsWith('image/') ==
                                            true) ||
                                    g.item.file == null
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
          print('get trailerss: exists');
          print('File already exists'); // FlutterToast or Snackbar
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
      print('No file selected.');
    }
  }

  // Function: Display Trailers in the Review Step
  Widget displayTrailers() {
    filteredTrailerList =
        trailerList.where((g) => g.item.saved == true).toList();

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
                                g.item.file.path.split('/').last,
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
          print('File already exists'); // FlutterToast or Snackbar
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
      print('No file selected.');
    }
  }

  // Function: Display Audios in the Review Step
  Widget displayAudios() {
    filteredAudioList = audioList.where((g) => g.item.saved == true).toList();

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
                                g.item.file.path.split('/').last,
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
        // TO DO: fix overflow issue when text is too long
        filteredActors.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredActors.map((actor) {
                    if (actor.crew.saved == true) {
                      var item = crewList
                          .firstWhere((p) => p.crewId == actor.crew.crewId);
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
                                child: Text(item.name,
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
        // TO DO: fix overflow issue when text is too long
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
    setState(() {
      awardList.add(AwardWidget(
        awardOptions: awardOptions,
        item: new Award(),
        open: ValueNotifier<bool>(true),
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
    filteredLines = lineList.where((line) => line.item.saved == true).toList();

    return Column(
      children: [
        filteredLines.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredLines.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Sikat na Linya: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        // TO DO: fix overflow issue when text is too long
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
                                child: Text(f.item.line,
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: f.item.role != null
                                ? Text(" (" + f.item.role + ")",
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
        // roles: rolesOptions,
        item: new Line(),
        open: ValueNotifier<bool>(true),
      ));
    });
  }

  @override
  void initState() {
    // in case user just closes the app and not click the back buttons
    rolesFilter.value = [];
    actorsFilter = [];
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
    // TO DO: add awards in stepper
    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      onModelReady: (model) async {
        movieId = movie?.movieId ?? 0;

        // update controller's text field
        titleController.text = movie?.title ?? '';
        _date = movie?.releaseDate != null
            ? DateTime.parse(movie?.releaseDate)
            : null;
        synopsisController.text = movie?.synopsis ?? '';
        runtimeController.text = movie?.runtime?.toString() ?? '';

        // TO DO: IMAGE EDIT
        imageURI = movie?.poster ?? '';

        // CREW
        directors = crewEdit != null
            ? crewEdit.isNotEmpty
                ? crewEdit[0].map((d) => d.crewId).toList()
                : []
            : [];
        writers = crewEdit != null
            ? crewEdit.isNotEmpty
                ? crewEdit[1].map((e) => e.crewId).toList()
                : []
            : [];
        // TO DO: ACTORS FIELD
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
            "Magdagdag ng Pelikula",
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
                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons
                                    .image, // Mga Poster, Screenshot, at iba pang Media
                                Icons.recent_actors, // Mga Personalidad
                                Icons.emoji_events_outlined, // Mga Award
                                Icons
                                    .format_quote_outlined, // Mga Sikat na Linya
                                Icons.grading // Review
                              ],
                              type: MyStepperType.vertical,
                              currentStep: currentStep,
                              onStepTapped: (step) async {
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
                              onStepCancel: () => {
                                if (currentStep != 0)
                                  setState(() => --currentStep)
                              }, // else do nothing
                              onStepContinue: () async {
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
                                      setState(() {
                                        currentStep++;
                                      });
                                      break;
                                    case 2: // Mga Personalidad
                                      setState(() {
                                        directorNode.unfocus();
                                        writerNode.unfocus();
                                        // TO DO: unfocus keyboard when an actor/role textfield is currently active
                                        currentStep++;
                                      });
                                      break;
                                    case 3: // Mga Award
                                      // TO DO: unfocus keyboard when a genre textfield is currently active
                                      setState(() => currentStep++);
                                      break;
                                    case 4: // Mga Sikat na Linya
                                      // TO DO: unfocus keyboard when a genre textfield is currently active
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

                                    // Wirectors
                                    List<int> directorsToSave = [];
                                    if (directors.isNotEmpty) {
                                      directors.map((d) => d.crewId).toList();
                                    }

                                    // Writers
                                    List<int> writersToSave = [];
                                    if (writers.isNotEmpty) {
                                      writers.map((w) => w.crewId).toList();
                                    }

                                    // Actors
                                    List<Crew> actorsToSave = [];
                                    if (filteredActors.isNotEmpty) {
                                      actorsToSave = filteredActors
                                          .map((a) => a.crew)
                                          .toList();
                                    }

                                    // Awards
                                    List<Award> awardsToSave = [];
                                    if (filteredAwards.isNotEmpty) {
                                      awardsToSave = filteredAwards
                                          .map((a) => a.item)
                                          .toList();
                                    }

                                    // Famous Lines
                                    List<Line> linesToSave = [];
                                    if (filteredLines.isNotEmpty) {
                                      linesToSave = filteredLines
                                          .map((a) => a.item)
                                          .toList();
                                    }

                                    // Posters
                                    List<File> postersToSave = [];
                                    List<String> posterDesc = [];
                                    if (filteredPosterList.isNotEmpty) {
                                      postersToSave = filteredPosterList
                                          .map((a) => a.item.file)
                                          .toList();

                                      posterDesc = filteredPosterList
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    // Gallery
                                    List<File> galleryToSave = [];
                                    List<String> galleryDesc = [];
                                    if (filteredGalleryList.isNotEmpty) {
                                      galleryToSave = filteredGalleryList
                                          .map((a) => a.item.file)
                                          .toList();
                                      galleryDesc = filteredGalleryList
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    // Trailers
                                    List<File> trailersToSave = [];
                                    List<String> trailerDesc = [];

                                    if (filteredTrailerList.isNotEmpty) {
                                      trailersToSave = filteredTrailerList
                                          .map((a) => a.item.file)
                                          .toList();
                                      trailerDesc = filteredTrailerList
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    // Audio
                                    List<File> audiosToSave = [];
                                    List<String> audioDesc = [];

                                    if (filteredAudioList.isNotEmpty) {
                                      audiosToSave = filteredAudioList
                                          .map((a) => a.item.file)
                                          .toList();
                                      audioDesc = filteredAudioList
                                          .map((a) => a.item.description)
                                          .toList();
                                    }

                                    final response = await model.addMovie(
                                        title: titleController.text,
                                        synopsis: synopsisController.text,
                                        releaseDate: _date != null
                                            ? _date.toIso8601String()
                                            : '',
                                        runtime: runtimeController.text,
                                        // imageURI: imageURI, // poster edit???
                                        genre: filmGenres,
                                        directors: directorsToSave,
                                        writers: writersToSave,
                                        // TO DO: famous lines and added media
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
                                        movieId: movieId);

                                    // when response is returned, stop showing circular progress indicator
                                    if (response != 0) {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show success snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Movie added successfully.',
                                              Colors.green));

                                      _saving =
                                          true; // set saving to true to trigger circular progress indicator

                                      // get movie using id redirect to detail view using response
                                      var movie = await model.getOneMovie(
                                          movieId: response.toString());

                                      if (movie != null) {
                                        _saving =
                                            false; // set saving to false to trigger circular progress indicator
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MovieView(
                                                  movieId:
                                                      movie.movieId.toString()),
                                            ),
                                          );
                                        });
                                      }
                                    } else {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Something went wrong. Check your inputs and try again.',
                                              Colors.red));
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
                                    content: LimitedBox(
                                      maxWidth: 300,
                                      child: Form(
                                          key: _formKeys[i],
                                          child: getContent(i)),
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
                  autofocus: true,
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
                      onTap: () {
                        _selectDate(context);
                      },
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
                                    return item
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
                                return genres;
                              },
                              submittedText: test != null
                                  ? test.trimLeft().trimRight()
                                  : "",
                              onChanged: (data) {
                                List<String> categories = data.length != 0
                                    ? data
                                        .map((item) => item.toString().trim())
                                        .toList()
                                    : [];
                                setState(() {
                                  filmGenres = categories;
                                });
                              },
                              chipBuilder: (context, state, c) {
                                return InputChip(
                                  key: ObjectKey(c),
                                  label: Text(c),
                                  onDeleted: () => state.deleteChip(c),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              },
                              suggestionBuilder: (context, state, c) {
                                return ListTile(
                                  key: ObjectKey(c),
                                  title: Text(c),
                                  onTap: () => state.selectSuggestion(c),
                                );
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
              ListView.builder(
                  itemCount: posterList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: posterList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              posterList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
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
                                              }
                                              posterList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              posterList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                  width: 140,
                  child: FlatButton(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: getPosters,
                    child: Row(
                      children: [Icon(Icons.camera_alt), Text(" Dagdagan")],
                    ),
                  )),
              SizedBox(height: 15),
              Text('Mga Trailer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: trailerList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: trailerList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              trailerList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
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
                                              }
                                              trailerList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              trailerList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                  width: 140,
                  child: FlatButton(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: getTrailers,
                    child: Row(
                      children: [Icon(Icons.videocam), Text(" Dagdagan")],
                    ),
                  )),
              SizedBox(
                height: 15,
              ),
              Text('Gallery',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: galleryList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: galleryList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              galleryList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
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
                                              }
                                              galleryList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              galleryList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                  width: 140,
                  child: FlatButton(
                    // focusNode: addActorNode,
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: addtoGallery,
                    child: Row(
                      children: [Icon(Icons.camera_alt), Text(" Dagdagan")],
                    ),
                  )),
              SizedBox(
                height: 15,
              ),
              Text('Mga Audio',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 15,
              ),
              ListView.builder(
                  itemCount: audioList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: audioList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              audioList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
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
                                              }
                                              audioList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              audioList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                  width: 140,
                  child: FlatButton(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: getAudios,
                    child: Row(
                      children: [Icon(Icons.library_music), Text(" Dagdagan")],
                    ),
                  )),
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
                        return item.name
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(
                                b.name.toLowerCase().indexOf(lowercaseQuery)));
                    }
                    return crewList;
                  },
                  onChanged: (data) {
                    directors = data;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.name),
                      onDeleted: () => state.deleteChip(c),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.name),
                      onTap: () => state.selectSuggestion(c),
                    );
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
                        return item.name
                            .toLowerCase()
                            .contains(query.toLowerCase());
                      }).toList(growable: false)
                        ..sort((a, b) => a.name
                            .toLowerCase()
                            .indexOf(lowercaseQuery)
                            .compareTo(
                                b.name.toLowerCase().indexOf(lowercaseQuery)));
                    }
                    return crewList;
                  },
                  onChanged: (data) {
                    writers = data;
                  },
                  chipBuilder: (context, state, c) {
                    return InputChip(
                      key: ObjectKey(c),
                      label: Text(c.name),
                      onDeleted: () => state.deleteChip(c),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                  suggestionBuilder: (context, state, c) {
                    return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.name),
                      onTap: () => state.selectSuggestion(c),
                    );
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
              SizedBox(height: 10),
              Container(
                width: 140,
                child: actorList.isEmpty
                    ? FlatButton(
                        focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addActor,
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1_outlined),
                            Text(" Dagdagan")
                          ],
                        ),
                      )
                    : null,
              ),
              ListView.builder(
                  itemCount: actorList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: actorList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              actorList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              if (actorList[i].crew.crewId !=
                                                  null) {
                                                rolesFilter.value.remove(
                                                    actorList[i].crew.role);
                                                actorsFilter.remove(
                                                    actorList[i].crew.crewId);
                                              }
                                              actorList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              actorList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                width: 140,
                child: actorList.isNotEmpty
                    ? FlatButton(
                        focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addActor,
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1_outlined),
                            Text(" Dagdagan")
                          ],
                        ),
                      )
                    : null,
              ),
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
                width: 140,
                child: awardList.isEmpty
                    ? FlatButton(
                        // focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addAward,
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_outlined),
                            Text(" Dagdagan")
                          ],
                        ),
                      )
                    : null,
              ),
              ListView.builder(
                  itemCount: awardList.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int i) {
                    return ValueListenableBuilder(
                        valueListenable: awardList[i].open,
                        builder: (context, value, widget) {
                          return Stack(
                            children: [
                              awardList[i],
                              value == true
                                  ? Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        child: OutlineButton(
                                          padding: EdgeInsets.all(0),
                                          color: Colors.white,
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              awardList.removeAt(i);
                                            });
                                          },
                                          child: Text('Tanggalin'),
                                        ),
                                        alignment: Alignment.centerRight,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          );
                        });
                  }),
              awardList.isNotEmpty
                  ? SizedBox(
                      height: 10,
                    )
                  : SizedBox(),
              Container(
                width: 140,
                child: awardList.isNotEmpty
                    ? FlatButton(
                        // focusNode: addActorNode,
                        color: Color.fromRGBO(240, 240, 240, 1),
                        onPressed: addAward,
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events_outlined),
                            Text(" Dagdagan")
                          ],
                        ),
                      )
                    : null,
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 4: // Mga Sikat na Linya
        // TO DO: dynamic widget

        // updates filteredactors list
        filteredActors =
            actorList.where((actor) => actor.crew.saved == true).toList();
        return Container(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: lineList.isEmpty && filteredActors.isEmpty ? null : 140,
              child: lineList.isEmpty && filteredActors.isNotEmpty
                  ? FlatButton(
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addLine,
                      child: Row(
                        children: [
                          Icon(Icons.question_answer_outlined),
                          Text(" Dagdagan")
                        ],
                      ),
                    )
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
                itemBuilder: (BuildContext context, int i) {
                  return ValueListenableBuilder(
                      valueListenable: lineList[i].open,
                      builder: (context, value, widget) {
                        return Stack(
                          children: [
                            lineList[i],
                            value == true
                                ? Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      child: OutlineButton(
                                        padding: EdgeInsets.all(0),
                                        color: Colors.white,
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            lineList.removeAt(i);
                                          });
                                        },
                                        child: Text('Tanggalin'),
                                      ),
                                      alignment: Alignment.centerRight,
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        );
                      });
                }),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 140,
              child: lineList.isNotEmpty
                  ? FlatButton(
                      // focusNode: addActorNode,
                      color: Color.fromRGBO(240, 240, 240, 1),
                      onPressed: addLine,
                      child: Row(
                        children: [
                          Icon(Icons.question_answer_outlined),
                          Text(" Dagdagan")
                        ],
                      ),
                    )
                  : null,
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ));
      case 5: // Review
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Color.fromRGBO(240, 240, 240, 1),
          ),
          padding: EdgeInsets.all(10),
          child: Scrollbar(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
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
                                : DateFormat("MMM. d, y").format(_date),
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
                  displayAwards(),
                  displayLines(),
                ],
              ),
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

  const ActorWidget({
    Key key,
    this.crew,
    this.crewList,
    this.open,
  }) : super(key: key);

  @override
  ActorWidgetState createState() => ActorWidgetState();
}

class ActorWidgetState extends State<ActorWidget> {
  var temp;
  Crew tempActor;
  List<String> tempRoles;
  bool showError = true;
  List<Crew> actorId = [];

  @override
  void initState() {
    widget.crew.saved = widget.crew.saved == null ? false : widget.crew.saved;
    if (widget.crew.crewId != null) {
      var actor =
          widget.crewList.singleWhere((a) => a.crewId == widget.crew.crewId);

      if (actor != null) actorId = [actor];
    }
    super.initState();
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
                maxChips: 1,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng aktor',
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
                      return item.name
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.name
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.name.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return filteredList;
                  // return widget.crewList;
                },
                onChanged: (data) {
                  if (data.length != 0) {
                    setState(() {
                      widget.crew.crewId = data[0].crewId;
                      widget.crew.firstName = data[0].firstName;
                      widget.crew.middleName = data[0].middleName;
                      widget.crew.lastName = data[0].lastName;
                      widget.crew.suffix = data[0].suffix;
                      showError = widget.crew.crewId != null &&
                              widget.crew.role != null &&
                              widget.crew.role.length != 0
                          ? false
                          : true;
                      actorId = [data[0]];
                      if (!actorsFilter.contains(data[0].crewId)) {
                        actorsFilter.add(data[0].crewId);
                      }
                    });
                  } else {
                    setState(() {
                      widget.crew.crewId = null;
                      widget.crew.firstName = null;
                      widget.crew.middleName = null;
                      widget.crew.lastName = null;
                      widget.crew.suffix = null;
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
                    onDeleted: () => {
                      setState(() {
                        actorsFilter.remove(c.crewId);
                      }),
                      state.deleteChip(c),
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
                  List<String> tempList = [];
                  tempList = data.map((role) => role.toString()).toList();

                  setState(() {
                    widget.crew.role = tempList;
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
                        if (rolesFilter.value.contains(c) == true) {
                          rolesFilter.value.remove(
                              c); // removes the deleted role from the role masterlist
                        }
                      });
                      state.deleteChip(c);
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
              child: OutlineButton(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                color: Colors.white,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (widget.crew.crewId != null && widget.crew.role != null) {
                    setState(() {
                      // save to actors and roles list
                      widget.open.value = false;
                      widget.crew.saved = true;

                      // save roles in roles masterlist
                      widget.crew.role.forEach((a) {
                        if (rolesFilter.value.contains(a) == false)
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
                child: Text('Save'),
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
                  (widget.crew != null
                      ? (widget.crew.firstName +
                          (widget.crew.middleName != null
                              ? " " + widget.crew.middleName
                              : "") +
                          (widget.crew.lastName != null
                              ? " " + widget.crew.lastName
                              : "") +
                          (widget.crew.suffix != null
                              ? " " + widget.crew.suffix
                              : ""))
                      : ""),
                  softWrap: true,
                  overflow: TextOverflow.clip),
              subtitle: Text(
                widget.crew.role != null ? widget.crew.role.join(", ") : "",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              trailing: GestureDetector(
                child: Icon(Icons.edit_outlined, color: Colors.black87),
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
