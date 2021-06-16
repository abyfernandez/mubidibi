import 'dart:async';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mubidibi/ui/shared/video_file.dart';
import 'package:mubidibi/ui/views/list_all_view.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:video_player/video_player.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/views/see_all_view.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

class CrewView extends StatefulWidget {
  final int crewId;

  CrewView({this.crewId});

  @override
  _CrewViewState createState() => _CrewViewState(crewId);
}

class _CrewViewState extends State<CrewView>
    with SingleTickerProviderStateMixin {
  final int crewId;

  _CrewViewState(this.crewId);

  Crew crew;
  bool _saving = false;
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final DialogService _dialogService = locator<DialogService>();
  var currentUser;
  Animation<double> _animation;
  AnimationController _animationController;
  IconData fabIcon;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Award> awards;
  List<Award> awardOptions;
  // Video Player / Carousel variables
  int _gallerySlider = 0;
  final CarouselController _galleryController = CarouselController();

  void fetchCrew() async {
    var model = CrewViewModel();
    var c = await model.getOneCrew(crewId: crewId);

    setState(() {
      crew = c;
    });
  }

  void fetchAwards() async {
    var model = AwardViewModel();
    var c = await model.getCrewAwards(
        crewId: crewId,
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin");

    var tempAwards = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'crew');

    setState(() {
      awards = c;
      awardOptions = tempAwards;
    });
  }

  Future<bool> onBackPress() async {
    Navigator.pop(context, []);
    return Future.value(false);
  }

  @override
  void initState() {
    initializeDateFormatting();
    tz.initializeTimeZones();

    fetchCrew();
    fetchAwards();
    currentUser = _authenticationService.currentUser;
    fabIcon = Icons.settings;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  Widget displayTypes() {
    return Wrap(
        children: crew.type != null
            ? crew.type.map((type) {
                return GestureDetector(
                    child: Container(
                        margin: EdgeInsets.only(right: 5),
                        child: Chip(
                          labelPadding: EdgeInsets.only(left: 2, right: 2),
                          label: Text(type,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white)),
                          backgroundColor: Colors.lightBlue,
                        )),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SeeAllView(
                                  type: "crew",
                                  title: type,
                                  showFilter: false,
                                  filter: type)));
                    });
              }).toList()
            : []);
  }

  Widget displayMovies(List crewMovies) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: crewMovies.isNotEmpty
              ? crewMovies.map((movie) {
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MovieView(movieId: movie.movieId),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          alignment: Alignment.center,

                          height: 180, //200
                          width: 120, //130
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(0.0, 0.0),
                                blurRadius: 0.0, // 2
                              ),
                            ],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              movie.title +
                                  (movie.releaseDate != "" &&
                                          movie.releaseDate != null
                                      ? (" (" +
                                          DateFormat('y').format(DateTime.parse(
                                              movie.releaseDate)) +
                                          ") ")
                                      : ""),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          height: 180.0,
                          width: 120.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            image: DecorationImage(
                              alignment: Alignment.topCenter,
                              image: CachedNetworkImageProvider(
                                movie.posters[0].url ?? Config.imgNotFound,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
              : []),
    );
  }

  Widget displayGallery() {
    return SingleChildScrollView(
      child: Column(
        children: [
          CarouselSlider(
            key: ValueKey('gallery'),
            options: CarouselOptions(
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _gallerySlider = index;
                  });
                },
                enlargeCenterPage: false,
                height: 200,
                aspectRatio: 16 / 9,
                viewportFraction: 1),
            carouselController: _galleryController,
            items: crew.gallery.map((p) {
              return Container(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Stack(
                  children: [
                    p.url.contains('/image/upload/')
                        ? Container(
                            child: GestureDetector(
                              child: Center(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).accentColor),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Image.network(
                                      Config.imgNotFound,
                                      width: 200,
                                      height: 300,
                                      fit: BoxFit.contain, // .cover
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                  imageUrl: p?.url ?? Config.imgNotFound,
                                  width: 200,
                                  height: 300,
                                  fit: BoxFit.contain, // .cover
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullPhotoT(
                                        url: p?.url ?? Config.imgNotFound,
                                        type: 'network',
                                        description: p.description),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            alignment: Alignment.topCenter,
                            child: VideoFile(
                                videoPlayerController:
                                    VideoPlayerController.network(p.url),
                                looping: false,
                                autoplay: false,
                                type: "simple"),
                          ),
                    // Arrow Buttons
                    Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(left: 0, right: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _gallerySlider != 0
                              ? Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(240, 240, 240, 1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _galleryController.previousPage();
                                          setState(() {
                                            _gallerySlider -= 1;
                                          });
                                        },
                                        child: Icon(
                                            Icons.navigate_before_outlined,
                                            size: 30),
                                      ),
                                    )
                                  ],
                                )
                              : Container(),
                          _gallerySlider != crew.gallery.length - 1
                              ? Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(240, 240, 240, 1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _galleryController.nextPage();
                                          setState(() {
                                            _gallerySlider += 1;
                                          });
                                        },
                                        child: Icon(
                                            Icons.navigate_next_outlined,
                                            size: 30),
                                      ),
                                    )
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (crew == null) return Center(child: CircularProgressIndicator());

    return ViewModelProvider.withConsumer(
      viewModel: CrewViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();
              Navigator.pop(context, []);
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Visibility(
          visible: currentUser != null
              ? currentUser.isAdmin
              : false, // if current user is a guest user, do not show the FAB
          child: FloatingActionBubble(
            // Menu items
            items: <Bubble>[
              // Floating action menu item
              Bubble(
                title: "Edit",
                iconColor: Colors.white,
                bubbleColor: Colors.lightBlue,
                icon: Icons.edit_outlined,
                titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                onPress: () async {
                  var model = MovieViewModel();
                  var movieOptions = await model.getAllMovies(mode: "form");

                  _animationController.reverse();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCrew(
                          crew: crew,
                          movieOpts: movieOptions,
                          crewAwards: awards,
                          awardOpts: awardOptions),
                    ),
                  );
                  setState(() {
                    fetchCrew();
                    fetchAwards();
                    fabIcon = fabIcon == Icons.settings
                        ? Icons.close
                        : Icons.settings;
                  });
                },
              ),
              //Floating action menu item
              crew.isDeleted == false
                  ? Bubble(
                      title: "Delete",
                      iconColor: Colors.white,
                      bubbleColor: Colors.lightBlue,
                      icon: Icons.delete,
                      titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                      onPress: () async {
                        _animationController.reverse();
                        setState(() {
                          fabIcon = fabIcon == Icons.settings
                              ? Icons.close
                              : Icons.settings;
                        });

                        var response =
                            await _dialogService.showConfirmationDialog(
                                title: "Confirm Deletion",
                                cancelTitle: "No",
                                confirmationTitle: "Yes",
                                description:
                                    "Are you sure you want to delete this item?");
                        if (response.confirmed == true) {
                          var model = CrewViewModel();

                          _saving = true;

                          var deleteRes = await model.deleteCrew(
                              id: crew.crewId.toString());
                          if (deleteRes != 0) {
                            // show success snackbar
                            // _scaffoldKey.currentState.showSnackBar(mySnackBar(
                            //     context,
                            //     'Item deleted successfully.',
                            //     Colors.green));

                            Fluttertoast.showToast(
                                msg: 'Item deleted successfully.',
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16);

                            Timer(const Duration(milliseconds: 2000), () {
                              _saving = false;

                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         CrewView(crewId: crew.crewId),
                              //   ),
                              // );
                              fetchCrew();
                              fetchAwards();
                            });
                          } else {
                            _saving = false;

                            // _scaffoldKey.currentState.showSnackBar(mySnackBar(
                            //     context,
                            //     'Something went wrong. Try again.',
                            //     Colors.red));

                            Fluttertoast.showToast(
                                msg: 'Something went wrong. Try again.',
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16);
                          }
                        }
                      },
                    )
                  : Bubble(
                      title: "Restore",
                      iconColor: Colors.white,
                      bubbleColor: Colors.lightBlue,
                      icon: Icons.restore_from_trash_outlined,
                      titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                      onPress: () async {
                        _animationController.reverse();
                        setState(() {
                          fabIcon = fabIcon == Icons.settings
                              ? Icons.close
                              : Icons.settings;
                        });

                        var response = await _dialogService.showConfirmationDialog(
                            title: "Confirm Restoration",
                            cancelTitle: "No",
                            confirmationTitle: "Yes",
                            description:
                                "Are you sure you want to restore this item?");
                        if (response.confirmed == true) {
                          var model = CrewViewModel();

                          _saving = true;

                          var restoreRes =
                              await model.restoreCrew(id: crew.crewId);
                          if (restoreRes != 0) {
                            // show success snackbar

                            // _scaffoldKey.currentState.showSnackBar(mySnackBar(
                            //     context,
                            //     'This item is now restored.',
                            //     Colors.green));

                            Fluttertoast.showToast(
                                msg: 'This item is now restored.',
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16);

                            Timer(const Duration(milliseconds: 2000), () {
                              _saving = false;
                              // redirect to homepage
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => CrewView(
                              //       crewId: crew.crewId,
                              //     ),
                              //   ),
                              // );
                              fetchCrew();
                              fetchAwards();
                            });
                          } else {
                            _saving = false;

                            // _scaffoldKey.currentState.showSnackBar(mySnackBar(
                            //     context,
                            //     'Something went wrong. Try again.',
                            //     Colors.red));

                            Fluttertoast.showToast(
                                msg: 'Something went wrong. Try again.',
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16);
                          }
                        }
                      },
                    ),
            ],

            // animation controller
            animation: _animation,

            // On pressed change animation state
            onPress: () => {
              _animationController.isCompleted
                  ? _animationController.reverse()
                  : _animationController.forward(),
              setState(() {
                fabIcon =
                    fabIcon == Icons.settings ? Icons.close : Icons.settings;
              })
            },

            // Floating Action button Icon color
            iconColor: Colors.white,

            // Floating Action button Icon
            iconData: fabIcon,
            backGroundColor: Colors.lightBlue,
          ),
        ),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: ModalProgressHUD(
            inAsyncCall: _saving,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              child: Text(
                                crew.name,
                                softWrap: true,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontFamily: 'Poppins',
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            // display type (crew types)
                            displayTypes(),
                            SizedBox(height: 10),
                            Wrap(
                              direction: Axis.vertical,
                              children: [
                                Text(
                                  "Born:   " +
                                      (crew.birthday != null
                                          ? DateFormat("MMM. d, y", "fil")
                                              .format(TZDateTime.from(
                                                  DateTime.parse(crew.birthday),
                                                  tz.getLocation(
                                                      'Asia/Manila')))
                                          : '-'),
                                  style: TextStyle(fontSize: 16),
                                  softWrap: true,
                                  overflow: TextOverflow.fade,
                                ),
                                crew.isAlive == false
                                    ? Text(
                                        'Died:   ' +
                                            (crew.deathdate != null
                                                ? DateFormat("MMM. d, y", "fil")
                                                    .format(TZDateTime.from(
                                                        DateTime.parse(
                                                            crew.deathdate),
                                                        tz.getLocation(
                                                            'Asia/Manila')))
                                                : '-'),
                                        style: TextStyle(fontSize: 16),
                                        softWrap: true,
                                        overflow: TextOverflow.fade)
                                    : Container(),
                              ],
                            ),
                            Text(
                              "Birthplace:   " +
                                  (crew.birthplace != null
                                      ? crew.birthplace
                                      : '-'),
                              style: TextStyle(fontSize: 16),
                              softWrap: true,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GestureDetector(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: Container(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Material(
                              child: Image.network(
                                Config.userNotFound,
                                height: 200,
                                width: 150,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                            imageUrl:
                                crew.displayPic?.url ?? Config.userNotFound,
                            width: 150,
                            height: 200,
                            alignment: Alignment.center,
                            fit: BoxFit.cover,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullPhotoT(
                                  url: crew.displayPic?.url ??
                                      Config.userNotFound,
                                  description: crew?.displayPic?.description,
                                  type: 'network'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                currentUser != null && currentUser.isAdmin == true
                    ? crew.isDeleted
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'This item is currently hidden. Restore in settings.',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox()
                    : SizedBox(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      crew.description != null
                          ? Text(
                              "     " + crew.description,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.justify,
                            )
                          : Center(
                              child: Text(
                                'No description found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                      SizedBox(height: 20),
                      crew.movies.isNotEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                crew.movies[0].length != 0
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  "Mga Pelikula bilang Direktor",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  overflow: TextOverflow.clip,
                                                  softWrap: true,
                                                ),
                                              ),
                                              crew.movies[0].length >= 4
                                                  ? Container(
                                                      child: GestureDetector(
                                                        child: Text(
                                                          'Tingnan Lahat',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.blue),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                        ),
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      SeeAllView(
                                                                movies: crew
                                                                    .movies[0],
                                                                type: 'movies',
                                                                title:
                                                                    "Mga Pelikula Bilang Direktor",
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          displayMovies(crew.movies[0])
                                        ],
                                      )
                                    : SizedBox(),
                                crew.movies[1].length != 0
                                    ? SizedBox(height: 20)
                                    : SizedBox(),
                                crew.movies[1].length != 0
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  "Mga Pelikula bilang Manunulat",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  overflow: TextOverflow.clip,
                                                  softWrap: true,
                                                ),
                                              ),
                                              crew.movies[1].length >= 4
                                                  ? Container(
                                                      child: GestureDetector(
                                                        child: Text(
                                                          'Tingnan Lahat',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.blue),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                        ),
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      SeeAllView(
                                                                movies: crew
                                                                    .movies[1],
                                                                type: 'movies',
                                                                title:
                                                                    "Mga Pelikula Bilang Manunulat",
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          displayMovies(crew.movies[1])
                                        ],
                                      )
                                    : SizedBox(),
                                crew.movies[2].length != 0
                                    ? SizedBox(height: 20)
                                    : SizedBox(),
                                crew.movies[2].length != 0
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  "Mga Pelikula bilang Aktor",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              crew.movies[2].length >= 4
                                                  ? Container(
                                                      child: GestureDetector(
                                                        child: Text(
                                                          'Tingnan Lahat',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.blue),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                        ),
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      SeeAllView(
                                                                movies: crew
                                                                    .movies[2],
                                                                type: 'movies',
                                                                title:
                                                                    "Mga Pelikula Bilang Aktor",
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          displayMovies(crew.movies[2])
                                        ],
                                      )
                                    : SizedBox(),
                              ],
                            )
                          : SizedBox(),
                      awards != null && awards.length != 0
                          ? SizedBox(height: 20)
                          : SizedBox(),
                      // Mga Award
                      awards != null && awards.length != 0
                          ? Container(
                              // padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Mga Award",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      awards.length >= 4
                                          ? GestureDetector(
                                              child: Text(
                                                'Tingnan Lahat',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue),
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ListAllView(
                                                      type: 'award',
                                                      items: awards,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(),
                                    ],
                                  ),
                                  Column(
                                    children: awards.map((award) {
                                      var i = awards.indexOf(award);
                                      return i < 2
                                          ? ListTile(
                                              title: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  new Icon(
                                                      Icons.fiber_manual_record,
                                                      size: 16),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                        award.name +
                                                            (award.year != null
                                                                ? " (" +
                                                                    award.year +
                                                                    ") "
                                                                : ""),
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                        softWrap: true,
                                                        overflow:
                                                            TextOverflow.clip),
                                                  ),
                                                ],
                                              ),
                                              subtitle: award.type != null
                                                  ? Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 20.0),
                                                      child: Text(
                                                          (award.event ?? '') +
                                                                      award
                                                                          .type ==
                                                                  "nominated"
                                                              ? "Nominado"
                                                              : "Panalo",
                                                          style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              fontSize: 16),
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .clip),
                                                    )
                                                  : SizedBox(),
                                            )
                                          : SizedBox();
                                    }).toList(),
                                  ),
                                  awards.length >= 3
                                      ? Container(
                                          alignment: Alignment.center,
                                          child: Text(' . . . ',
                                              style: TextStyle(fontSize: 20)))
                                      : SizedBox(),
                                ],
                              ),
                            )
                          : SizedBox(),
                      awards != null && awards.length != 0
                          ? SizedBox(height: 25)
                          : SizedBox(),
                      crew.gallery.isNotEmpty
                          ? SizedBox(height: 25)
                          : SizedBox(),
                      crew.gallery.isNotEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                crew.gallery.isNotEmpty
                                    ? SizedBox(height: 10)
                                    : SizedBox(),
                                displayGallery(),
                                SizedBox(height: 20)
                              ],
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
