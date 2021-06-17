// FORM VIEW: CREW (DIRECTORS, WRITERS, ACTORS)

import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/media_file.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/movie_actor.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/widgets/award_widget.dart';
import 'package:mubidibi/ui/widgets/chips_input_test.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/ui/widgets/media_widget.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

// Global Variables for dynamic Widgets
List<int> movieActorsFilter = []; // movies
List<int> crewAwardsFilter = []; // awards

List gallery = [];

class AddCrew extends StatefulWidget {
  final Crew crew;
  final List<Movie> movieOpts;
  final List<Award> crewAwards;
  final List<Award> awardOpts;

  AddCrew({Key key, this.crew, this.movieOpts, this.crewAwards, this.awardOpts})
      : super(key: key);

  @override
  _AddCrewState createState() =>
      _AddCrewState(crew, movieOpts, crewAwards, awardOpts);
}

// ADD MOVIE FIRST PAGE
class _AddCrewState extends State<AddCrew> {
  final Crew crew;
  final List<Movie> movieOpts;
  final List<Award> crewAwards;
  final List<Award> awardOpts;

  _AddCrewState(this.crew, this.movieOpts, this.crewAwards, this.awardOpts);

  // Local state variables
  var currentUser;
  bool _saving = false;
  int crewId;
  File imageFile; // for uploading display photo w/ image picker
  var mimetype; // mimetype of DP
  String displayPic; // for edit crew

  // Lists
  List<Movie> movieDirector = [];
  List<Movie> movieWriter = [];

  // Dynamic Widget Lists
  List<AwardWidget> awardList = [];
  List<MovieActorWidget> movieActorList = [];
  List<MediaWidget> galleryList = [];

  // Options for Dropdowns
  List<Movie> movieOptions;
  List<Award> awardOptions;

  // Filtered Lists for Display in Review Step
  List<AwardWidget> filteredAwards = [];
  List<MovieActorWidget> filteredMovieActorList = [];
  List<MediaWidget> filteredGalleryList = [];

  // CREW FIELD CONTROLLERS
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final suffixController = TextEditingController();
  DateTime _birthday;
  final birthdayController = TextEditingController();
  final birthplaceController = TextEditingController();
  bool isAlive = true;
  DateTime _deathdate;
  final deathdateController = TextEditingController();
  final descriptionController = TextEditingController();
  final descriptionDPController = TextEditingController(); // DP

  // CREW FIELD NODES
  final firstNameNode = FocusNode();
  final middleNameNode = FocusNode();
  final lastNameNode = FocusNode();
  final suffixNode = FocusNode();
  final birthdayNode = FocusNode();
  final birthplaceNode = FocusNode();
  final isAliveNode = FocusNode();
  final deathdateNode = FocusNode();
  final descriptionNode = FocusNode();
  final descriptionDPNode = FocusNode(); // DP

  // CREW FORMKEYS
  List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = [
    "Mga Basic na Detalye",
    "Mga Pelikula",
    "Media",
    "Mga Award",
    "Review"
  ];

  // Edit Crew Lists
  List<int> movieDirectorsToDelete = [];
  List<int> movieWritersToDelete = [];
  List<int> movieActorsToDelete = [];
  List<int> awardsToDelete = [];
  List<int> galleryToDelete = []; // for gallery edit
  int displayPicToDelete = 0;

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  bool mediaIsNull() {
    return imageFile == null && (displayPic == null || displayPic == '')
        ? true
        : false;
  }

  // Function: Display MovieActor in the Review Step
  Widget displayMovieActors() {
    filteredMovieActorList =
        movieActorList.where((item) => item.movieActor.saved == true).toList();

    return Column(
      children: [
        filteredMovieActorList.length != 0 ? SizedBox(height: 10) : SizedBox(),
        filteredMovieActorList.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Mga Pelikula Bilang Aktor: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : SizedBox(),
        filteredMovieActorList.length != 0
            ? Container(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredMovieActorList.map((film) {
                    if (film.movieActor.saved == true) {
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
                                child: Text(film.movieActor.movieTitle,
                                    style: TextStyle(fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: film.movieActor.role.length != 0
                                ? Text(" - " + film.movieActor.role.join(" / "),
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip)
                                : SizedBox(),
                          ),
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

  addMovieActor() {
    FocusScope.of(context).unfocus();

    setState(() {
      // add Movie Actor widget to the list
      movieActorList.add(MovieActorWidget(
        movieOptions: movieOptions,
        movieActor: new MovieActor(),
        open: ValueNotifier<bool>(true),
        prevId: ValueNotifier<int>(0),
      ));
    });
  }

  // Function: Shows datepicker and update value of Date
  Future<Null> _selectDate(BuildContext context, String mode) async {
    if (mode == "birthday") {
      DateTime _datePicker = await showDatePicker(
          context: context,
          initialDate: _birthday == null ? DateTime.now() : _birthday,
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
          initialDatePickerMode: DatePickerMode.day,
          builder: (BuildContext context, Widget child) {
            return child;
          });

      if (_datePicker != null && _datePicker != _birthday) {
        setState(() {
          _birthday = _datePicker;
          birthdayController.text =
              // DateFormat("MMM. d, y", "fil").format(
              //         TZDateTime.from(_birthday, tz.getLocation('Asia/Manila'))) ??
              //     '';
              DateFormat("MMMM d, y", "fil").format(_birthday) ?? '';
        });
      }
    } else {
      DateTime _datePicker = await showDatePicker(
          context: context,
          initialDate: _deathdate == null ? DateTime.now() : _deathdate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2030),
          initialDatePickerMode: DatePickerMode.day,
          builder: (BuildContext context, Widget child) {
            return child;
          });

      if (_datePicker != null && _datePicker != _deathdate) {
        setState(() {
          _deathdate = _datePicker;
          deathdateController.text =
              // DateFormat("MMM. d, y", "fil").format(
              //         TZDateTime.from(_deathdate, tz.getLocation('Asia/Manila'))) ??
              // '';
              DateFormat("MMMM d, y", "fil").format(_deathdate) ?? '';
        });
      }
    }
  }

  // Function: get image using image picker for crew's display photo
  void getImage() async {
    FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      imageFile = File(result.files.single.path);
      setState(() {
        imageFile = imageFile;
        mimetype = lookupMimeType(result.files.single.path);
      });
    } else {
      // User canceled the picker
      Fluttertoast.showToast(msg: 'No file selected.');
    }
  }

  // Function: adds AwardWidget in the ListView builder
  addAward() {
    setState(() {
      // add award widget to list
      awardList.add(AwardWidget(
        awardOptions: awardOptions,
        item: new Award(),
        open: ValueNotifier<bool>(true),
        prevId: ValueNotifier<int>(0),
        type: "crew",
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
        filteredAwards != null && filteredAwards.isNotEmpty
            ? SizedBox(height: 15)
            : SizedBox()
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
      List imagePaths =
          gallery.isNotEmpty ? gallery.map((img) => img.path).toList() : [];

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
              gallery.add(filtered[i]);

              // add photo widget to list
              galleryList.add(MediaWidget(
                  category: "crew",
                  item: new MediaFile(
                      file: filtered[i], category: "crew", type: "gallery"),
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
        filteredGalleryList != null && filteredGalleryList.isNotEmpty
            ? SizedBox(height: 15)
            : SizedBox()
      ],
    );
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
        movieActorsFilter =
            []; // clears list para pag binalikan sya empty na ulit
        gallery = [];
        crewAwardsFilter = [];
      });
      await _navigationService.pop();
    }
    return Future.value(false);
  }

  void fetchMovies() async {
    var model = MovieViewModel();
    movieOptions = await model.getAllMovies(mode: "form");
  }

  void fetchAwards() async {
    var model = AwardViewModel();
    awardOptions = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'crew');
  }

  @override
  void initState() {
    initializeDateFormatting();
    tz.initializeTimeZones();

    currentUser = _authenticationService.currentUser;
    fetchMovies();
    fetchAwards();

    // clear lists
    movieActorsFilter = [];
    crewAwardsFilter = [];
    gallery = [];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    return ViewModelProvider<CrewViewModel>.withConsumer(
      viewModel: CrewViewModel(),
      onModelReady: (model) async {
        crewId = crew?.crewId ?? 0;

        // update controller's text field
        firstNameController.text = crew?.firstName ?? "";
        middleNameController.text = crew?.middleName ?? "";
        lastNameController.text = crew?.lastName ?? "";
        suffixController.text = crew?.suffix ?? "";
        _birthday = crew?.birthday != null
            // ? DateTime.parse(crew?.birthday).add(Duration(days: 1))
            ? DateTime.parse(crew?.birthday)
            : null;

        birthdayController.text = crew?.birthday != null
            // ? DateFormat("MMM. d, y", "fil").format(
            //     TZDateTime.from(_birthday, tz.getLocation('Asia/Manila')))
            // : '';
            ? DateFormat("MMM. d, y", "fil").format(_birthday)
            : '';

        birthplaceController.text = crew?.birthplace ?? "";
        isAlive = crew?.isAlive ?? true;

        _deathdate = crew?.deathdate != null
            ? DateTime.parse(crew?.deathdate).add(Duration(days: 1))
            : null;
        deathdateController.text = crew?.deathdate != null
            // ? DateFormat("MMM. d, y", "fil").format(
            //     TZDateTime.from(_deathdate, tz.getLocation('Asia/Manila')))
            // : '';
            ? DateFormat("MMM. d, y", "fil").format(_deathdate)
            : '';

        descriptionController.text = crew?.description ?? "";

        // Mga Pelikula
        movieDirector = crew != null &&
                crew.movies != null &&
                crew.movies[0] != null &&
                crew.movies[0].isNotEmpty
            ? crew.movies[0]
            : [];
        movieWriter = crew != null &&
                crew.movies != null &&
                crew.movies[1] != null &&
                crew.movies[1].isNotEmpty
            ? crew.movies[1]
            : [];

        List<Movie> aktors = crew != null &&
                crew.movies != null &&
                crew.movies[2] != null &&
                crew.movies[2].isNotEmpty
            ? crew.movies[2]
            : [];

        for (var i = 0; i < aktors.length; i++) {
          movieActorsFilter.add(aktors[i].movieId);
          // add Movie Actor widget to the list
          movieActorList.add(MovieActorWidget(
            movieOptions: movieOpts,
            movieActor: MovieActor(
              id: aktors[i].movieId,
              movieId: aktors[i].movieId,
              movieTitle: aktors[i].title,
              role: aktors[i].role,
            ),
            open: ValueNotifier<bool>(false),
            prevId: ValueNotifier<int>(0),
          ));
        }

        // Mga Award
        var temp = crewAwards != null ? crewAwards : [];

        for (var i = 0; i < temp.length; i++) {
          crewAwardsFilter.add(temp[i].id);
          awardList.add(AwardWidget(
            awardOptions: awardOpts,
            item: temp[i],
            open: ValueNotifier<bool>(false),
            prevId: ValueNotifier<int>(0),
            type: "crew",
          ));
        }

        // Media

        // Display Pic
        displayPic = crew?.displayPic?.url ?? '';
        descriptionDPController.text = crew?.displayPic?.description ?? "";

        // Gallery
        List<MediaFile> g = crew?.gallery != null ? crew?.gallery : [];
        for (var i = 0; i < g.length; i++) {
          g[i].category = "crew";
          galleryList.add(MediaWidget(
              category: "crew", item: g[i], open: ValueNotifier<bool>(false)));
        }
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
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
                  movieActorsFilter = [];
                  crewAwardsFilter = [];
                  gallery = [];
                });
                _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            crew != null
                ? "Mag-edit ng Personalidad"
                : "Magdagdag ng Personalidad",
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            MyStepper(
                              physics: ClampingScrollPhysics(),
                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons.movie_outlined, // Mga Pelikula
                                Icons.image, // Mga Larawan
                                Icons.emoji_events_outlined, // Mga Award
                                Icons.grading // Review
                              ],
                              type: MyStepperType.vertical,
                              currentStep: currentStep,
                              onStepTapped: (step) async {
                                FocusScope.of(context).unfocus();
                                if (currentStep == 0) {
                                  // first step (First Name)
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
                                if (currentStep + 1 != stepperTitle.length) {
                                  FocusScope.of(context).unfocus();
                                  // do not allow user to continue to next step if inputs aren't filled out yet
                                  switch (currentStep) {
                                    case 0: // basic details
                                      setState(() {
                                        if (_formKeys[currentStep]
                                            .currentState
                                            .validate()) {
                                          currentStep++;
                                        }
                                      });
                                      break;

                                    case 1: // movies
                                      setState(() {
                                        FocusScope.of(context).unfocus();
                                        setState(() => ++currentStep);
                                      });
                                      break;

                                    case 2: // photos
                                      FocusScope.of(context).unfocus();
                                      setState(() => ++currentStep);

                                      break;

                                    case 3: // awards
                                      FocusScope.of(context).unfocus();
                                      setState(() => ++currentStep);
                                      break;
                                  }
                                } else {
                                  // last step
                                  FocusScope.of(context).unfocus();

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

                                    // movieDirectors
                                    List<int> movieDirectorsToSave = [];
                                    if (movieDirector.isNotEmpty) {
                                      movieDirectorsToSave = movieDirector
                                          .map((a) => a.movieId)
                                          .toList();

                                      // remove those to be deleted
                                      movieDirectorsToSave.removeWhere((a) =>
                                          movieDirectorsToDelete.contains(a));

                                      // remove those that are from the old list
                                      if (crew?.movies != null &&
                                          crew?.movies[0] != null &&
                                          crew?.movies[0].isNotEmpty) {
                                        var temp = crew?.movies[0]
                                            .map((a) => a.movieId)
                                            .toList();
                                        movieDirectorsToSave.removeWhere(
                                            (a) => temp.contains(a));
                                      }
                                    }

                                    // movieWriters
                                    List<int> movieWritersToSave = [];
                                    if (movieWriter.isNotEmpty) {
                                      movieWritersToSave = movieWriter
                                          .map((a) => a.movieId)
                                          .toList();

                                      // remove those to be deleted
                                      movieWritersToSave.removeWhere((a) =>
                                          movieWritersToDelete.contains(a));

                                      // remove those that are from the old list
                                      if (crew?.movies != null &&
                                          crew?.movies[1] != null &&
                                          crew?.movies[1].isNotEmpty) {
                                        var temp = crew?.movies[1]
                                            .map((a) => a.movieId)
                                            .toList();
                                        movieWritersToSave.removeWhere(
                                            (a) => temp.contains(a));
                                      }
                                    }

                                    // actors
                                    List<MovieActor> movieActorsToSave = [];
                                    if (filteredMovieActorList.isNotEmpty) {
                                      movieActorsToSave = filteredMovieActorList
                                          .map((a) => a.movieActor)
                                          .toList();

                                      movieActorsToSave.removeWhere((a) =>
                                          a.id != null &&
                                          movieActorsToDelete.contains(a.id));
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
                                    if (crew != null &&
                                        crew.gallery != null &&
                                        crew.gallery.isNotEmpty) {
                                      crew.gallery.forEach((p) {
                                        if (!galleryToDelete.contains(p.id))
                                          galleryToUpdate.add(p);
                                      });
                                    }

                                    final response = await model.addCrew(
                                      firstName: firstNameController.text,
                                      middleName: middleNameController.text,
                                      lastName: lastNameController.text,
                                      suffix: suffixController.text,
                                      birthday: _birthday != null
                                          ? _birthday.toUtc().toString()
                                          : '',
                                      birthplace: birthplaceController.text,
                                      isAlive: isAlive,
                                      deathdate: _deathdate != null
                                          ? _deathdate.toUtc().toString()
                                          : '',
                                      description: descriptionController.text,
                                      displayPic: imageFile,
                                      descDP: descriptionDPController.text,
                                      mimetype: mimetype,
                                      addedBy: currentUser.userId,
                                      crewId: crewId,

                                      // for edit purposes
                                      gallery: galleryToSave,
                                      galleryDesc: galleryDesc,
                                      galleryToDelete: galleryToDelete,
                                      directors: movieDirectorsToSave,
                                      directorsToDelete: movieDirectorsToDelete,
                                      writers: movieWritersToSave,
                                      writersToDelete: movieWritersToDelete,
                                      actorsToDelete: movieActorsToDelete,
                                      displayPicToDelete: displayPicToDelete,
                                      actors: movieActorsToSave,
                                      awards: awardsToSave,
                                      awardsToDelete: awardsToDelete,
                                      // update description of existing media
                                      galleryToUpdate: galleryToUpdate,
                                      displayPicToUpdate: crew != null &&
                                              crew.displayPic != null &&
                                              crew.displayPic.id != null
                                          ? crew.displayPic
                                          : null,
                                    );

                                    // when response is returned, stop showing circular progress indicator

                                    if (response != 0) {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator

                                      // show success snackbar
                                      // _scaffoldKey.currentState.showSnackBar(
                                      //     mySnackBar(
                                      //         context,
                                      //         'Crew added successfully.',
                                      //         Colors.green));

                                      Fluttertoast.showToast(
                                          msg: crewId != 0
                                              ? 'Crew updated successfully.'
                                              : 'Crew added successfully.',
                                          backgroundColor: Colors.green,
                                          textColor: Colors.white,
                                          fontSize: 16);

                                      _saving =
                                          true; // set saving to true to trigger circular progress indicator

                                      // get movie using id redirect to detail view using response
                                      var crewRes = await model.getOneCrew(
                                          crewId: response);

                                      if (crewRes != null) {
                                        _saving =
                                            false; // set saving to false to trigger circular progress indicator
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          Navigator.pop(context, []);
                                        });
                                      }
                                    } else {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show error snackbar
                                      // _scaffoldKey.currentState.showSnackBar(
                                      // mySnackBar(
                                      //     context,
                                      //     'Something went wrong. Check your inputs and try again.',
                                      //     Colors.red));

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
                                      width: 300,
                                      child: SingleChildScrollView(
                                        child: Form(
                                            key: _formKeys[i],
                                            child: getContent(i)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
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
      case 0: // basic details
        return Container(
          child: Column(
            children: [
              SizedBox(height: 15),
              // CREW FIRST NAME
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: firstNameNode,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  controller: firstNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    middleNameNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    filled: true,
                    labelText: "First Name *",
                    contentPadding: EdgeInsets.all(10),
                  ),
                  validator: (value) {
                    if (value.isEmpty || value == null) {
                      return 'Required ang field na ito.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 15),
              // CREW MIDDLE NAME
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: middleNameNode,
                  textCapitalization: TextCapitalization.words,
                  controller: middleNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    lastNameNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Middle Name",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CREW LAST NAME
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: lastNameNode,
                  textCapitalization: TextCapitalization.words,
                  controller: lastNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    suffixNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Last Name",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CREW SUFFIX
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: suffixNode,
                  textCapitalization: TextCapitalization.words,
                  controller: suffixController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    birthdayNode.requestFocus();
                  },
                  decoration: InputDecoration(
                    labelText: "Suffix",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // CREW BIRTHDAY
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  children: [
                    TextFormField(
                      readOnly: true,
                      focusNode: birthdayNode,
                      keyboardType: TextInputType.datetime,
                      controller: birthdayController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      onFieldSubmitted: (val) {
                        birthplaceNode.requestFocus();
                      },
                      onTap: _birthday == null
                          ? () {
                              _selectDate(context, "birthday");
                            }
                          : null,
                      decoration: InputDecoration(
                        labelText: "Birthday",
                        filled: true,
                        fillColor: Color.fromRGBO(240, 240, 240, 1),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    _birthday != null
                        ? PositionedDirectional(
                            top: 10,
                            end: 10,
                            bottom: 10,
                            child: GestureDetector(
                              child: Icon(Icons.close_outlined,
                                  color: Color.fromRGBO(150, 150, 150, 1)),
                              onTap: () {
                                setState(() {
                                  _birthday = null;
                                  birthdayController.text = "";
                                });
                              },
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
              SizedBox(height: 15),
              // CREW BIRTHPLACE
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: birthplaceNode,
                  textCapitalization: TextCapitalization.words,
                  controller: birthplaceController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  onFieldSubmitted: (val) {
                    isAliveNode.requestFocus();
                  },
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Birthplace",
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Text("Is this person still alive?",
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic)),
                    Row(
                      children: [
                        Switch(
                          focusNode: isAliveNode,
                          value: isAlive == null ? true : isAlive,
                          onChanged: (bool newValue) {
                            setState(() {
                              isAlive = newValue;
                            });
                          },
                        ),
                        // CREW DEATHDATE
                        isAlive == false
                            ? Flexible(
                                child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Stack(
                                  children: [
                                    TextFormField(
                                      readOnly: true,
                                      focusNode: deathdateNode,
                                      keyboardType: TextInputType.datetime,
                                      controller: deathdateController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      onTap: _deathdate == null
                                          ? () {
                                              _selectDate(context, "deathdate");
                                            }
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: "Death date",
                                        filled: true,
                                        fillColor:
                                            Color.fromRGBO(240, 240, 240, 1),
                                        contentPadding: EdgeInsets.all(10),
                                      ),
                                    ),
                                    _birthday != null
                                        ? PositionedDirectional(
                                            top: 10,
                                            end: 10,
                                            bottom: 10,
                                            child: GestureDetector(
                                              child: Icon(Icons.close_outlined,
                                                  color: Color.fromRGBO(
                                                      150, 150, 150, 1)),
                                              onTap: () {
                                                setState(() {
                                                  _deathdate = null;
                                                  deathdateController.text = "";
                                                });
                                              },
                                            ),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ))
                            : SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: TextFormField(
                  focusNode: descriptionNode,
                  controller: descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Description",
                    contentPadding: EdgeInsets.all(10),
                    filled: true,
                    fillColor: Color.fromRGBO(240, 240, 240, 1),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        );
      case 1: // Movies
        return Container(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 10),
            Text('Bilang Direktor:',
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
                initialValue: movieDirector,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();
                    return movieOptions.where((item) {
                      return !movieDirector
                              .map((d) => d.movieId)
                              .toList()
                              .contains(item.movieId) &&
                          item.title
                              .toLowerCase()
                              .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return [];
                },
                onChanged: (data) {
                  var newList = List<Movie>.from(data);
                  movieDirector = newList;
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c.title +
                        (c.releaseDate != "" && c.releaseDate != null
                            ? (" (" +
                                DateFormat('y')
                                    .format(DateTime.parse(c.releaseDate)) +
                                ") ")
                            : "")),
                    onDeleted: () {
                      if (crew != null &&
                          crew.movies[0]
                              .map((direk) => direk.movieId)
                              .toList()
                              .contains(c.movieId)) {
                        // for edit: delete item from DB
                        if (!movieDirectorsToDelete.contains(c.movieId)) {
                          movieDirectorsToDelete.add(c.movieId);
                        }
                      }
                      state.deleteChip(c);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.title +
                          (c.releaseDate != "" && c.releaseDate != null
                              ? (" (" +
                                  DateFormat('y')
                                      .format(DateTime.parse(c.releaseDate)) +
                                  ") ")
                              : "")),
                      onTap: () {
                        if (movieDirectorsToDelete.contains(c.movieId)) {
                          movieDirectorsToDelete.remove(c.movieId);
                        }
                        return state.selectSuggestion(c);
                      });
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Bilang Manunulat:',
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
                initialValue: movieWriter,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();
                    return movieOptions.where((item) {
                      return !movieWriter
                              .map((d) => d.movieId)
                              .toList()
                              .contains(item.movieId) &&
                          item.title
                              .toLowerCase()
                              .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return [];
                },
                onChanged: (data) {
                  var newList = List<Movie>.from(data);
                  movieWriter = newList;
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c.title +
                        (c.releaseDate != "" && c.releaseDate != null
                            ? (" (" +
                                DateFormat('y')
                                    .format(DateTime.parse(c.releaseDate)) +
                                ") ")
                            : "")),
                    onDeleted: () {
                      if (crew != null &&
                          crew.movies[1]
                              .map((writer) => writer.movieId)
                              .toList()
                              .contains(c.movieId)) {
                        // for edit: delete item from DB
                        if (!movieWritersToDelete.contains(c.movieId)) {
                          movieWritersToDelete.add(c.movieId);
                        }
                      }
                      state.deleteChip(c);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                      key: ObjectKey(c),
                      title: Text(c.title +
                          (c.releaseDate != "" && c.releaseDate != null
                              ? (" (" +
                                  DateFormat('y')
                                      .format(DateTime.parse(c.releaseDate)) +
                                  ") ")
                              : "")),
                      onTap: () {
                        if (movieWritersToDelete.contains(c.movieId)) {
                          movieWritersToDelete.remove(c.movieId);
                        }
                        return state.selectSuggestion(c);
                      });
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Bilang Aktor:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 10,
            ),
            Container(
                child: FlatButton(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    onPressed: addMovieActor,
                    child: Text(" Dagdagan"))),
            ListView.builder(
                itemCount: movieActorList.length,
                shrinkWrap: true,
                reverse: true,
                itemBuilder: (BuildContext context, int i) {
                  return ValueListenableBuilder(
                      valueListenable: movieActorList[i].open,
                      builder: (context, value, widget) {
                        return Stack(
                          key: ObjectKey(movieActorList[i]),
                          children: [
                            movieActorList[i],
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
                                            if (movieActorList[i]
                                                    .movieActor
                                                    .movieId !=
                                                null) {
                                              // delete from filter list
                                              movieActorsFilter.remove(
                                                  movieActorList[i]
                                                      .movieActor
                                                      .movieId);

                                              // if the id of the item to be deleted in ui exists in crewEdit, this means existing na sya
                                              // previously saved in the database
                                              // remove from DB by adding to the actorsToDelete list
                                              // for edit: delete item from DB
                                              if (!movieActorsToDelete.contains(
                                                      movieActorList[i]
                                                          .movieActor
                                                          .movieId) &&
                                                  (crew != null &&
                                                      crew.movies != null &&
                                                      crew.movies.isNotEmpty &&
                                                      crew.movies[2]
                                                          .map((c) => c.movieId)
                                                          .toList()
                                                          .contains(
                                                              movieActorList[i]
                                                                  .movieActor
                                                                  .movieId))) {
                                                movieActorsToDelete.add(
                                                    movieActorList[i]
                                                        .movieActor
                                                        .movieId);
                                              }
                                            } else if (movieActorList[i]
                                                        .prevId
                                                        .value !=
                                                    null &&
                                                movieActorList[i]
                                                        .prevId
                                                        .value !=
                                                    0) {
                                              if (!movieActorsToDelete.contains(
                                                      movieActorList[i]
                                                          .prevId
                                                          .value) &&
                                                  (crew != null &&
                                                      crew.movies != null &&
                                                      crew.movies.isNotEmpty &&
                                                      crew.movies[2]
                                                          .map((c) => c.movieId)
                                                          .toList()
                                                          .contains(
                                                              movieActorList[i]
                                                                  .prevId
                                                                  .value))) {
                                                movieActorsToDelete.add(
                                                    movieActorList[i]
                                                        .prevId
                                                        .value);
                                              }
                                            }
                                            movieActorList.removeAt(i);
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
            SizedBox(
              height: 10,
            ),
            // Container(
            //   width: 140,
            //   child: movieActorList.isNotEmpty
            //       ? FlatButton(
            //           // focusNode: addActorNode,
            //           color: Color.fromRGBO(240, 240, 240, 1),
            //           onPressed: addMovieActor,
            //           child: Row(
            //             children: [
            //               Icon(Icons.person_add_alt_1_outlined),
            //               Text(" Dagdagan")
            //             ],
            //           ),
            //         )
            //       : null,
            // ),
            // SizedBox(
            //   height: 10,
            // ),
          ]),
        );
      case 2: // Photos
        return Container(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text('Display Photo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Stack(
                      children: [
                        (displayPic == null || displayPic == "") &&
                                imageFile == null
                            ? GestureDetector(
                                onTap: getImage,
                                child: Container(
                                  // margin: EdgeInsets.only(left: 20),
                                  height: 100, // 200
                                  width: 80, // 150
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Container(
                                    height: 100,
                                    width: 80,
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey[800],
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(240, 240, 240, 1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(),

                        // image is present
                        imageFile != null ||
                                (displayPic != null && displayPic != "")
                            ? displayPic != null && displayPic != ""
                                ? Container(
                                    // show image from url
                                    height: 100, // 200
                                    width: 80, // 150
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Container(
                                      height: 100,
                                      width: 80,
                                      child: CachedNetworkImage(
                                        placeholder: (context, url) =>
                                            Container(
                                          alignment: Alignment.center,
                                          width: 80,
                                          height: 100,
                                          child: Image.network(displayPic,
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
                                            displayPic ?? Config.imgNotFound,
                                        width: 80,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                // show image file
                                : Image.file(
                                    imageFile,
                                    width: 80,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                            : SizedBox(),

                        imageFile != null ||
                                (displayPic != null && displayPic != "")
                            ? Container(
                                width: 25,
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  child: Icon(Icons.close),
                                  onTap: () {
                                    setState(() {
                                      if (imageFile != null)
                                        imageFile = null;
                                      else if (displayPic != null &&
                                          displayPic != "") {
                                        displayPicToDelete = crew != null
                                            ? crew.displayPic.id
                                            : 0;
                                        displayPic = null;
                                        descriptionDPController.text = '';
                                      }
                                    });
                                  },
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(0.0, 0.0),
                                      blurRadius: 0.0,
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                  // textfield for description
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      child: TextFormField(
                        enabled: !mediaIsNull(),
                        focusNode: descriptionDPNode,
                        controller: descriptionDPController,
                        textCapitalization: TextCapitalization.sentences,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      ),
                    ),
                  ),
                ],
              ),
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
              )),
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
                                                List imagePaths = gallery
                                                        .isNotEmpty
                                                    ? gallery
                                                        .map((img) => img.path)
                                                        .toList()
                                                    : [];

                                                // loop through gallery's paths
                                                if (imagePaths.contains(
                                                    galleryList[i]
                                                        .item
                                                        .file
                                                        .path)) {
                                                  gallery.removeWhere((f) =>
                                                      galleryList[i]
                                                          .item
                                                          .file
                                                          .path ==
                                                      f.path);
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
              //       // focusNode: addActorNode,
              //       color: Color.fromRGBO(240, 240, 240, 1),
              //       onPressed: addtoGallery,
              //       child: Row(
              //         children: [Icon(Icons.camera_alt), Text(" Dagdagan")],
              //       ),
              //     )),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      case 3: // Awards
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
                                              crewAwardsFilter
                                                  .remove(awardList[i].item.id);

                                              if (awardList[i].item.id !=
                                                  null) {
                                                if (crewAwards != null &&
                                                    crewAwards
                                                        .map((a) => a.id)
                                                        .contains(awardList[i]
                                                            .item
                                                            .id)) {
                                                  // for edit: delete item from DB
                                                  if (awardsToDelete.contains(
                                                          awardList[i]
                                                              .item
                                                              .id) ==
                                                      false) {
                                                    awardsToDelete.add(
                                                        awardList[i].item.id);
                                                  }
                                                }
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
                                                  (crewAwards != null &&
                                                      crewAwards
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
              // SizedBox(
              //   height: 10,
              // ),
              // Container(
              //   width: 140,
              //   child: awardList.isNotEmpty
              //       ? FlatButton(
              //           // focusNode: addActorNode,
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
      case 4: // review
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Name: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    firstNameController.text +
                        (middleNameController.text.trim() != ""
                            ? " " + middleNameController.text
                            : "") +
                        " " +
                        lastNameController.text +
                        (suffixController.text.trim() != ""
                            ? " " + suffixController.text
                            : ""),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.clip,
                    softWrap: true,
                  ),
                ),
                _birthday != null ? SizedBox(height: 10) : SizedBox(),
                _birthday != null
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Birthday: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                _birthday != null
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _birthday == null
                              ? ''
                              // : DateFormat("MMM. d, y", "fil").format(
                              //     TZDateTime.from(_birthday,
                              //         tz.getLocation('Asia/Manila'))),
                              : DateFormat("MMM. d, y", "fil")
                                  .format(_birthday),
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ))
                    : SizedBox(),
                birthplaceController.text.trim() != ""
                    ? SizedBox(height: 10)
                    : SizedBox(),
                birthplaceController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Birthplace: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                birthplaceController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          birthplaceController.text,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.clip,
                          softWrap: true,
                        ))
                    : SizedBox(),
                isAlive == false ? SizedBox(height: 10) : SizedBox(),
                isAlive == false
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Died: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                isAlive == false
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                            _deathdate == null
                                ? 'Walang record'
                                // : DateFormat("MMM. d, y", "fil").format(
                                //     TZDateTime.from(_birthday,
                                //         tz.getLocation('Asia/Manila'))),
                                : DateFormat("MMM. d, y", "fil")
                                    .format(_deathdate),
                            style: TextStyle(
                              fontStyle: _deathdate == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                descriptionController.text.trim() != ""
                    ? SizedBox(height: 15)
                    : SizedBox(),
                descriptionController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Description: ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                descriptionController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          descriptionController.text.trim() != ""
                              ? descriptionController.text
                              : "",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.clip,
                          softWrap: true,
                        ),
                      )
                    : SizedBox(),
                movieDirector.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                movieDirector.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Mga Pelikula Bilang Direktor: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                movieDirector.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Column(
                            children: movieDirector.map<Widget>((film) {
                          return new Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              new Expanded(
                                child: Text(
                                  film.title,
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
                movieWriter.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                movieWriter.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Mga Pelikula Bilang Manunulat: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                movieWriter.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Column(
                            children: movieWriter.map<Widget>((film) {
                          return new Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              new Icon(Icons.fiber_manual_record, size: 16),
                              SizedBox(
                                width: 5,
                              ),
                              new Expanded(
                                child: Text(
                                  film.title,
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
                displayMovieActors(),
                imageFile != null || (displayPic != null && displayPic != "")
                    ? SizedBox(height: 10)
                    : SizedBox(),
                imageFile != null || (displayPic != null && displayPic != "")
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Display Photo: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                imageFile != null || (displayPic != null && displayPic != "")
                    ? SizedBox(height: 10)
                    : SizedBox(),
                imageFile != null || (displayPic != null && displayPic != "")
                    ? Container(
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
                                  child: imageFile != null
                                      ? Image.file(
                                          imageFile,
                                          width: 80,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : displayPic != null && displayPic != ""
                                          ? Image.network(
                                              displayPic,
                                              width: 80,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : SizedBox(),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => imageFile != null
                                            ? FullPhotoT(
                                                type: 'path', file: imageFile)
                                            : FullPhotoT(
                                                type: 'network',
                                                url: displayPic)),
                                  );
                                }),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                  descriptionDPController.text.trim() != ""
                                      ? descriptionDPController.text
                                      : "Walang description",
                                  style: TextStyle(
                                      color:
                                          descriptionDPController.text.trim() ==
                                                  ""
                                              ? Colors.black38
                                              : Colors.black,
                                      fontStyle:
                                          descriptionDPController.text.trim() ==
                                                  ""
                                              ? FontStyle.italic
                                              : FontStyle.normal)),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(),
                SizedBox(height: 15),
                displayGallery(),
                displayAwards(),
                // SizedBox(height: 15),
              ],
            ),
          ),
        );
    }
    return null;
  }
}

// Movie Actor Widget
class MovieActorWidget extends StatefulWidget {
  final List<Movie> movieOptions;
  final MovieActor movieActor;
  final open;
  final ValueNotifier<int> prevId;

  const MovieActorWidget({
    Key key,
    this.movieActor,
    this.movieOptions,
    this.open,
    this.prevId,
  }) : super(key: key);

  @override
  MovieActorWidgetState createState() => MovieActorWidgetState();
}

class MovieActorWidgetState extends State<MovieActorWidget> {
  List<String> tempRoles;
  Movie tempMovie;
  var temp;
  bool showError = true;
  List<Movie> movieActorId = [];

  @override
  void initState() {
    widget.movieActor.saved =
        widget.movieActor.saved == null && widget.movieActor.id == null
            ? false
            : widget.movieActor.saved == null && widget.movieActor.id != null
                ? true
                : widget.movieActor.saved;
    if (widget.movieActor.movieId != null) {
      // to get info on the movie chosen
      var film = widget.movieOptions
          .singleWhere((a) => a.movieId == widget.movieActor.movieId);
      if (film != null) {
        movieActorId = [film];
      }
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
                initialValue: movieActorId,
                maxChips: 1,
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Pumili ng pelikula',
                  contentPadding: EdgeInsets.all(10),
                ),
                findSuggestions: (String query) {
                  var filteredList = movieActorsFilter.length != 0
                      ? widget.movieOptions
                          .where((r) => !movieActorsFilter.contains(r.movieId))
                          .toList()
                      : widget.movieOptions;
                  if (query.isNotEmpty) {
                    var lowercaseQuery = query.toLowerCase();

                    return filteredList.where((item) {
                      return !movieActorId
                              .map((d) => d.movieId)
                              .toList()
                              .contains(item.movieId) &&
                          item.title
                              .toLowerCase()
                              .contains(query.toLowerCase());
                    }).toList(growable: false)
                      ..sort((a, b) => a.title
                          .toLowerCase()
                          .indexOf(lowercaseQuery)
                          .compareTo(
                              b.title.toLowerCase().indexOf(lowercaseQuery)));
                  }
                  return [];
                },
                onChanged: (data) {
                  var newList = List<Movie>.from(data);

                  if (newList.length != 0) {
                    setState(() {
                      // widget.movieActor.id is intentionally left out
                      widget.movieActor.movieId = newList[0].movieId;
                      widget.movieActor.movieTitle = newList[0].title;
                      showError = widget.movieActor.movieId != null &&
                              widget.movieActor.role != null &&
                              widget.movieActor.role.length != 0
                          ? false
                          : true;

                      movieActorId = [newList[0]];
                      if (!movieActorsFilter.contains(newList[0].movieId)) {
                        movieActorsFilter.add(newList[0].movieId);
                      }
                    });
                  } else {
                    setState(() {
                      widget.movieActor.movieId = null;
                      widget.movieActor.movieTitle = null;
                      showError = widget.movieActor.movieId != null &&
                              widget.movieActor.role != null &&
                              widget.movieActor.role.length != 0
                          ? false
                          : true;
                      widget.movieActor.saved =
                          widget.movieActor.movieId != null &&
                                  widget.movieActor.role != null &&
                                  widget.movieActor.role.length != 0 &&
                                  widget.movieActor.saved == true
                              ? true
                              : false;
                      movieActorId = [];
                    });
                  }
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c.title +
                        (c.releaseDate != "" && c.releaseDate != null
                            ? (" (" +
                                DateFormat('y')
                                    .format(DateTime.parse(c.releaseDate)) +
                                ") ")
                            : "")),
                    onDeleted: () {
                      setState(() {
                        movieActorsFilter.remove(c.movieId);
                        widget.prevId.value = c.movieId;
                      });
                      state.deleteChip(c);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
                suggestionBuilder: (context, state, c) {
                  return ListTile(
                    key: ObjectKey(c),
                    title: Text(c.title +
                        (c.releaseDate != "" && c.releaseDate != null
                            ? (" (" +
                                DateFormat('y')
                                    .format(DateTime.parse(c.releaseDate)) +
                                ") ")
                            : "")),
                    onTap: () => {
                      if (!movieActorsFilter.contains(c.movieId))
                        {
                          setState(() {
                            movieActorsFilter.add(c.movieId);
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
                initialValue: widget.movieActor.role != null
                    ? widget.movieActor.role
                    : [],
                keyboardAppearance: Brightness.dark,
                textCapitalization: TextCapitalization.words,
                enabled: true,
                textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Role *',
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
                    widget.movieActor.role = newList;
                    showError = widget.movieActor.movieId != null &&
                            widget.movieActor.role != null &&
                            widget.movieActor.role.length != 0
                        ? false
                        : true;
                    widget.movieActor.saved =
                        widget.movieActor.movieId != null &&
                                widget.movieActor.role != null &&
                                widget.movieActor.role.length != 0 &&
                                widget.movieActor.saved == true
                            ? true
                            : false;
                  });
                },
                chipBuilder: (context, state, c) {
                  return InputChip(
                    key: ObjectKey(c),
                    label: Text(c),
                    onDeleted: () => state.deleteChip(c),
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
                  if (widget.movieActor.movieId != null &&
                      widget.movieActor.role != null &&
                      widget.movieActor.role.length != 0) {
                    setState(() {
                      // save to actors and roles list
                      widget.open.value = false;
                      widget.movieActor.saved = true;
                    });
                  } else {
                    setState(() {
                      widget.movieActor.saved = false;
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
                  (widget.movieActor != null &&
                          widget.movieActor.movieId != null
                      ? (widget.movieActor.movieTitle)
                      : ""),
                  softWrap: true,
                  overflow: TextOverflow.clip),
              subtitle: Text(
                widget.movieActor.role != null &&
                        widget.movieActor.role.isNotEmpty
                    ? widget.movieActor.role.join(", ")
                    : "",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              trailing: GestureDetector(
                child: Icon(Icons.edit),
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
