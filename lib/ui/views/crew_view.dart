import 'dart:ui';
import 'dart:convert';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/home_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'full_photo.dart';

// TO DO: instead of passing the crew data, use the API call to get crew data by ID
class CrewView extends StatefulWidget {
  final String crewId;

  CrewView({this.crewId});

  @override
  _CrewViewState createState() => _CrewViewState(crewId);
}

class _CrewViewState extends State<CrewView>
    with SingleTickerProviderStateMixin {
  final String crewId;

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

  void fetchCrew() async {
    var model = CrewViewModel();
    var c = await model.getOneCrew(crewId: crewId);

    setState(() {
      crew = c;
    });
  }

  @override
  void initState() {
    fetchCrew();
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
                return Container(
                    margin: EdgeInsets.only(right: 5),
                    child: Chip(
                      labelPadding: EdgeInsets.only(left: 2, right: 2),
                      label: Text(type, style: TextStyle(fontSize: 12)),
                      backgroundColor: Color.fromRGBO(176, 224, 230, 1),
                    ));
              }).toList()
            : []);
  }

  Widget displayMovies(List crewMovies) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: crewMovies.isNotEmpty
              ? crewMovies.map((movie) {
                  return Container(
                    height: 150,
                    width: 120,
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2, // 7
                          )
                        ]),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MovieView(movieId: movie.movieId.toString()),
                          ),
                        );
                        print(movie.title);
                      },

                      // Make this a stack/ conditional statement so that the movie title can still be seen if poster is not available
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
                            Config.imgNotFound,
                            height: 350,
                            width: 250,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        imageUrl:
                            movie.poster != null && movie.poster.length != 0
                                ? movie.poster[0]
                                : Config.imgNotFound,
                        width: 250,
                        height: 230,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList()
              : []),
    );
  }

  Widget displayPhotos() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: crew.photos.isNotEmpty
              ? crew.photos.map((pic) {
                  return Container(
                    height: 150,
                    width: 120,
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 7,
                          )
                        ]),
                    child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullPhoto(url: pic ?? Config.imgNotFound),
                            ),
                          );
                        },
                        child: Image.network(
                          pic,
                          height: 250,
                          width: 230,
                          alignment: Alignment.topCenter,
                          fit: BoxFit.cover,
                        )),
                  );
                }).toList()
              : []),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);

    final _scaffoldKey = GlobalKey<ScaffoldState>();

    if (crew == null) return Center(child: CircularProgressIndicator());

    return ViewModelProvider.withConsumer(
      viewModel: CrewViewModel(),
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // TO DO: hide button when scrolling ???
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
                  _animationController.reverse();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCrew(crew: crew),
                    ),
                  );
                  setState(() {
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

                        // TO DO: if user is an admin, they can soft delete crew
                        var response =
                            await _dialogService.showConfirmationDialog(
                                title: "Confirm Deletion",
                                cancelTitle: "No",
                                confirmationTitle: "Yes",
                                description:
                                    "Are you sure you want to delete this crew?");
                        if (response.confirmed == true) {
                          var model = CrewViewModel();

                          _saving = true;

                          var deleteRes = await model.deleteCrew(
                              id: crew.crewId.toString());
                          if (deleteRes != 0) {
                            // show success snackbar
                            // TO DO: show snackbar; di na sya nagpapakita ever since i added the fetchCrew() line
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'Crew deleted successfully.',
                                Colors.green));

                            fetchCrew();
                            _saving = false;

                            // redirect to homepage if user is not an admin

                            if (currentUser != null &&
                                currentUser.isAdmin != true) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeView(),
                                ),
                              );
                            }
                          } else {
                            _saving = false;

                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'Something went wrong. Try again.',
                                Colors.red));
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

                        // TO DO: if user is an admin, they can restore delete movies
                        var response = await _dialogService.showConfirmationDialog(
                            title: "Confirm Restoration",
                            cancelTitle: "No",
                            confirmationTitle: "Yes",
                            description:
                                "Are you sure you want to restore this movie?");
                        if (response.confirmed == true) {
                          var model = CrewViewModel();

                          _saving = true;

                          var restoreRes = await model.restoreCrew(
                              id: crew.crewId.toString());
                          if (restoreRes != 0) {
                            // show success snackbar
                            // TO DO: show snackbar; di na sya nagpapakita ever since i added the fetchMovie() line
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'This movie is now restored.',
                                Colors.green));

                            _saving = false;
                            fetchCrew();
                            print("is deleted: ");
                            print(crew.isDeleted);

                            // redirect to homepage

                          } else {
                            _saving = false;

                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'Something went wrong. Try again.',
                                Colors.red));
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
        body: ListView(
          children: <Widget>[
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        crew.firstName +
                            (crew.middleName != null
                                ? " " + crew.middleName
                                : "") +
                            (crew.lastName != null ? " " + crew.lastName : "") +
                            (crew.suffix != null ? ' ' + crew.suffix : ''),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 25,
                          fontFamily: 'Poppins',
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
                                    ? DateFormat('MMM. d, y')
                                        .format(DateTime.parse(crew.birthday))
                                    : '-'),
                            style: TextStyle(fontSize: 16),
                            softWrap: true,
                            overflow: TextOverflow.fade,
                          ),
                          crew.isAlive == false
                              ? Text(
                                  'Died:   ' +
                                      (crew.deathdate != null
                                          ? DateFormat('MMM. d, y').format(
                                              DateTime.parse(crew.deathdate))
                                          : '-'),
                                  style: TextStyle(fontSize: 16),
                                  softWrap: true,
                                  overflow: TextOverflow.fade)
                              : Container(),
                        ],
                      ),
                      Text(
                        "Birthplace:   " +
                            (crew.birthplace != null ? crew.birthplace : '-'),
                        style: TextStyle(fontSize: 16),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
                Container(
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
                        imageUrl: crew.displayPic ?? Config.userNotFound,
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
                          builder: (context) => FullPhoto(
                              url: crew.displayPic ?? Config.userNotFound),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
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
                  SizedBox(height: 10),
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
                  SizedBox(height: 10),
                  crew.movies.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            crew.movies[0].length != 0
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Mga Pelikula bilang Direktor",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          crew.movies[0].length >= 4
                                              ? GestureDetector(
                                                  // child: Text(
                                                  //   'Tingnan Lahat',
                                                  //   style: TextStyle(
                                                  //       fontSize: 14,
                                                  //       fontWeight: FontWeight.bold),
                                                  // ),
                                                  child: Icon(Icons
                                                      .arrow_forward_ios_outlined),
                                                  onTap: () {},
                                                )
                                              : Container(),
                                        ],
                                      ),
                                      displayMovies(crew.movies[0])
                                    ],
                                  )
                                : SizedBox(),
                            crew.movies[1].length != 0
                                ? SizedBox(height: 10)
                                : SizedBox(),
                            crew.movies[1].length != 0
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Mga Pelikula bilang Manunulat",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          crew.movies[1].length >= 4
                                              ? GestureDetector(
                                                  // child: Text(
                                                  //   'Tingnan Lahat',
                                                  //   style: TextStyle(
                                                  //       fontSize: 14,
                                                  //       fontWeight: FontWeight.bold),
                                                  // ),
                                                  child: Icon(Icons
                                                      .arrow_forward_ios_outlined),
                                                  onTap: () {},
                                                )
                                              : Container(),
                                        ],
                                      ),
                                      displayMovies(crew.movies[1])
                                    ],
                                  )
                                : SizedBox(),
                            crew.movies[2].length != 0
                                ? SizedBox(height: 10)
                                : SizedBox(),
                            crew.movies[2].length != 0
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Mga Pelikula bilang Aktor",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          crew.movies[2].length >= 4
                                              ? GestureDetector(
                                                  child: Text(
                                                    'Tingnan Lahat',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.blue),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                  ),
                                                  // child: Icon(Icons
                                                  //     .arrow_forward_ios_outlined),
                                                  onTap: () {},
                                                )
                                              : Container(),
                                        ],
                                      ),
                                      displayMovies(crew.movies[2])
                                    ],
                                  )
                                : SizedBox(),
                          ],
                        )
                      : SizedBox(),
                  SizedBox(height: 10),
                  crew.photos.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Mga Larawan",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                // TO DO: MAKE A PAGE TO VIEW ALL PHOTOS / IMAGE VIEWER (FOR MULTIPLE IMAGES)
                                crew.photos.length >= 4
                                    ? GestureDetector(
                                        child: Icon(
                                            Icons.arrow_forward_ios_outlined),

                                        // child: Text('Tingnan Lahat',
                                        //     style: TextStyle(
                                        //         fontSize: 18,
                                        //         fontWeight: FontWeight.bold)),
                                        onTap: () {},
                                      )
                                    : Container(),
                              ],
                            ),
                            displayPhotos()
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
