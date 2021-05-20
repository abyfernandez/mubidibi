import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/review.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/ui/widgets/content_scroll.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/review_view_model.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import '../../locator.dart';
import 'full_photo.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'home_view.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/review_form.dart';
import 'package:mubidibi/ui/views/display_reviews.dart';

class MovieView extends StatefulWidget {
  final String movieId;

  MovieView({this.movieId});

  @override
  _MovieViewState createState() => _MovieViewState(movieId);
}

class _MovieViewState extends State<MovieView>
    with SingleTickerProviderStateMixin {
  final String movieId;

  _MovieViewState(this.movieId);

  Movie movie;
  Future<List<List<Crew>>> crew;
  List<List<Crew>> crewEdit;
  Future<List<Review>> reviews;
  ScrollController _scrollController;
  Animation<double> _animation;
  AnimationController _animationController;
  final NavigationService _navigationService = locator<NavigationService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final DialogService _dialogService = locator<DialogService>();
  var currentUser;

  // local variables
  bool _saving = false;
  ValueNotifier<double> rating = ValueNotifier<double>(0.0);
  var tempRating = 0.0;
  var numItems = 0;

  // variables needed for adding reviews
  final reviewController = TextEditingController();

  // function for calling viewmodel's getCrewForDetails method
  Future<List<List<Crew>>> fetchCrew() async {
    var model = CrewViewModel();
    var crew = await model.getCrewForDetails(movieId: movieId);

    setState(() {
      crewEdit = crew;
    });
    return crew;
  }

  void computeOverallRating(String movieId) async {
    tempRating = 0.0;
    numItems = 0;

    var model = ReviewViewModel();
    var isReady = await model.getAllReviews(
        movieId: movieId,
        accountId: currentUser != null ? currentUser.userId : "0");

    if (isReady == true) {
      for (var i = 0; i < model.reviews.length; i++) {
        if (model.reviews[i].isApproved == true) {
          tempRating += model.reviews[i].rating;
          numItems += 1;
        }
      }
      tempRating = tempRating != 0 ? tempRating / numItems : 0.0;
      model.setOverAllRating(tempRating);

      rating.value = tempRating;
    } else {
      rating.value = 0.0;
    }
  }

// refresh page when over all rating is changed
  refresh() {
    setState(() {});
  }

  // function for calling movie viewmodel's getOneMovie method
  Future fetchMovie() async {
    var model = MovieViewModel();
    var film = await model.getOneMovie(movieId: movieId);

    setState(() {
      movie = film;
    });
  }

  String timeAgo(String formattedString) {
    final timestamp = DateTime.parse(formattedString);
    final difference = DateTime.now().difference(timestamp);
    final timeAgo =
        DateTime.now().subtract(Duration(minutes: difference.inMinutes));
    return timeago.format(timeAgo, locale: 'en');
  }

  String displayRuntime() {
    var hours = 0;
    var minutes = 0;

    if (movie.runtime != null && movie.runtime != 0) {
      hours = movie.runtime ~/ 60; // integer division
      minutes = movie.runtime % 60; // modulo division

      return (hours != 0 ? hours.toString() + ' oras ' : '') +
          (minutes != 0 ? minutes.toString() + ' minuto' : '');
    }
    return '-';
  }

  @override
  void initState() {
    fetchMovie();
    crew = fetchCrew();
    currentUser = _authenticationService.currentUser;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
    super.initState();
  }

  GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // formkey
  FocusNode focusNode =
      new FocusNode(); // to close keyboard after posting review
  GlobalKey _toolTipKey = GlobalKey();

  @override
  void didUpdateWidget(MovieView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    if (movie == null) return Center(child: CircularProgressIndicator());

    return ViewModelProvider<ReviewViewModel>.withConsumer(
      viewModel: ReviewViewModel(),
      onModelReady: (model) async {
        var res = await model.getAllReviews(
            movieId: movie.movieId.toString(),
            accountId: currentUser != null ? currentUser.userId : "0");

        computeOverallRating(movie.movieId.toString());
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // TO DO: hide button when scrolling ???
        floatingActionButton: Visibility(
          visible: currentUser != null ? currentUser.isAdmin : false,
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMovie(movie: movie),
                    ),
                  );
                  _animationController.reverse();
                },
              ),
              //Floating action menu item
              movie.isDeleted == false
                  ? Bubble(
                      title: "Delete",
                      iconColor: Colors.white,
                      bubbleColor: Colors.lightBlue,
                      icon: Icons.delete,
                      titleStyle: TextStyle(fontSize: 16, color: Colors.white),
                      onPress: () async {
                        _animationController.reverse();

                        // TO DO: if user is an admin, they can soft delete movies
                        var response = await _dialogService.showConfirmationDialog(
                            title: "Confirm Deletion",
                            cancelTitle: "No",
                            confirmationTitle: "Yes",
                            description:
                                "Are you sure you want to delete this movie?");
                        if (response.confirmed == true) {
                          var model = MovieViewModel();

                          _saving = true;

                          var deleteRes = await model.deleteMovie(
                              id: movie.movieId.toString());
                          if (deleteRes != 0) {
                            // show success snackbar
                            // TO DO: show snackbar; di na sya nagpapakita ever since i added the fetchMovie() line
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'Movie deleted successfully.',
                                Colors.green));

                            Timer(const Duration(milliseconds: 2000), () {
                              _saving = false;

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeView(),
                                ),
                              );
                            });
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

                        // TO DO: if user is an admin, they can restore delete movies
                        var response = await _dialogService.showConfirmationDialog(
                            title: "Confirm Restoration",
                            cancelTitle: "No",
                            confirmationTitle: "Yes",
                            description:
                                "Are you sure you want to restore this movie?");
                        if (response.confirmed == true) {
                          var model = MovieViewModel();

                          _saving = true;

                          var restoreRes = await model.restoreMovie(
                              id: movie.movieId.toString());
                          if (restoreRes != 0) {
                            // show success snackbar
                            // TO DO: show snackbar; di na sya nagpapakita ever since i added the fetchMovie() line
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'This movie is now restored.',
                                Colors.green));

                            Timer(const Duration(milliseconds: 2000), () {
                              _saving = false;
                              // redirect to homepage
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeView(),
                                ),
                              );
                            });
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
            },

            // Floating Action button Icon color
            iconColor: Colors.white,

            // Floating Action button Icon
            iconData: Icons.settings,
            backGroundColor: Colors.lightBlue,
          ),
        ),
        body: SafeArea(
          child: ModalProgressHUD(
            inAsyncCall: _saving,
            child: ListView(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      // height: (queryData.size.height / 2) + 60,   -> using mediaquery causes the widgets to rebuild once it detected change in size (e.g. height of the widget changes when onscreen keyboard opens) so i removed it for the meantime
                      height: 400,
                      decoration: new BoxDecoration(
                        image: new DecorationImage(
                          image: CachedNetworkImageProvider(
                              movie.poster ?? Config.imgNotFound),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          new BackdropFilter(
                            filter:
                                new ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                            child: new Container(
                              decoration: new BoxDecoration(
                                  color: Colors.black.withOpacity(0.3)),
                            ),
                          ),
                          GestureDetector(
                            child: Center(
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
                                imageUrl: movie.poster ?? Config.imgNotFound,
                                width: 250,
                                height: 350,
                                fit: BoxFit.cover,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullPhoto(
                                      url: movie.poster ?? Config.imgNotFound),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          padding: EdgeInsets.only(left: 30.0),
                          onPressed: () =>
                              // _navigationService.navigateTo(HomeViewRoute), -- this causes to redirecto to homepage after searching for movies, instead na bumalik lang sa search page
                              _navigationService.pop(),
                          icon: Icon(Icons.arrow_back),
                          iconSize: 30.0,
                          color: Colors.white,
                        ),
                        // if user is an admin, replace button with a "DELETED" tag if movie is deleted, non if it isn't deleted.
                        // if user is not an admin, show "add to favorite" button instead.
                        currentUser != null && currentUser.isAdmin == true
                            ? movie.isDeleted == true
                                ? IconButton(
                                    padding: EdgeInsets.only(right: 20.0),
                                    onPressed: () => print(
                                        "This movie is currently hidden."),
                                    icon: Icon(Icons.error_outline_outlined),
                                    iconSize: 30.0,
                                    color: Colors.white,
                                  )
                                : SizedBox()
                            : currentUser != null
                                ? IconButton(
                                    padding: EdgeInsets.only(right: 20.0),
                                    onPressed: () => print('Add to Favorites'),
                                    icon: Icon(Icons.add),
                                    iconSize: 30.0,
                                    color: Colors.white,
                                  )
                                : SizedBox(),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Text(
                          movie.title.toUpperCase(),
                          style: TextStyle(
                              fontSize: 25.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      movie.genre != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Center(
                                    child: Text(
                                      movie.genre.reduce(
                                          (curr, next) => curr + ", " + next),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ])
                          : Container(),
                      ValueListenableBuilder(
                        valueListenable: rating,
                        builder: (context, value, widget) {
                          return Center(
                              child: Text(
                                  value != 0
                                      ? value.toString()
                                      : "No ratings yet",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: value != 0
                                          ? FontStyle.normal
                                          : FontStyle.italic)));
                        },
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.end,
                //       children: <Widget>[
                //         Text(
                //           'Petsa ng Paglabas',
                //           style: TextStyle(
                //             color: Colors.black,
                //             fontSize: 18.0,
                //             fontWeight: FontWeight.bold,
                //           ),
                //           textAlign: TextAlign.right,
                //         ),
                //         SizedBox(height: 2.0),
                //         Text(
                //           movie.releaseDate != null &&
                //                   movie.releaseDate.trim() != ''
                //               ? DateFormat("MMM. d, y").format(
                //                   DateTime.parse(movie.releaseDate),
                //                 )
                //               : '-',
                //           style: TextStyle(
                //             fontSize: 16.0,
                //           ),
                //         ),
                //       ],
                //     ),
                //     Center(
                //       child: Container(
                //         height: 50,
                //         child: VerticalDivider(
                //           color: Colors.grey[900],
                //         ),
                //       ),
                //     ),
                //     Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: <Widget>[
                //         Text(
                //           'Runtime',
                //           style: TextStyle(
                //             color: Colors.black,
                //             fontSize: 18.0,
                //             fontWeight: FontWeight.bold,
                //           ),
                //           textAlign: TextAlign.left,
                //         ),
                //         SizedBox(height: 2.0),
                //         Text(
                //           displayRuntime(),
                //           style: TextStyle(
                //             fontSize: 16.0,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    alignment: Alignment.center,
                    child: IntrinsicHeight(
                        child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text(
                              'Petsa ng Paglabas',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              movie.releaseDate != null &&
                                      movie.releaseDate.trim() != ''
                                  ? DateFormat("MMM. d, y").format(
                                      DateTime.parse(movie.releaseDate),
                                    )
                                  : '-',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(color: Colors.grey[900]),
                        Column(
                          children: <Widget>[
                            Text(
                              'Runtime',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              displayRuntime(),
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Buod',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "     " + movie.synopsis,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                crewEdit != null && crewEdit[0].length != 0
                    ? SizedBox(height: 15)
                    : Container(),
                crewEdit != null && crewEdit[0].length != 0
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: ContentScroll(
                          crewEdit: crewEdit,
                          crew: crewEdit != null
                              ? crewEdit[0].map((director) => director).toList()
                              : [],
                          title: 'Mga Direktor',
                          imageHeight: 130.0,
                          imageWidth: 110.0,
                        ),
                      )
                    : Container(),
                crewEdit != null && crewEdit[1].length != 0
                    ? SizedBox(height: 15)
                    : Container(),
                crewEdit != null && crewEdit[1].length != 0
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: ContentScroll(
                          crewEdit: crewEdit,
                          crew: crewEdit != null
                              ? crewEdit[1].map((writer) => writer).toList()
                              : [],
                          title: 'Mga Manunulat',
                          imageHeight: 130.0,
                          imageWidth: 110.0,
                        ),
                      )
                    : Container(),

                crewEdit != null && crewEdit[2].length != 0
                    ? SizedBox(height: 15)
                    : Container(),
                crewEdit != null && crewEdit[2].length != 0
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: ContentScroll(
                          crewEdit: crewEdit,
                          crew: crewEdit != null
                              ? crewEdit[2].map((actors) => actors).toList()
                              : [],
                          title: 'Mga Aktor',
                          imageHeight: 130.0,
                          imageWidth: 110.0,
                        ),
                      )
                    : Container(),
                SizedBox(height: 25),
                model.reviews.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text("Mga Review",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                      )
                    : SizedBox(),
                (currentUser == null && model.isEmpty == true) ||
                        (currentUser != null &&
                            currentUser.isAdmin == false &&
                            model.userReview != null &&
                            model.isEmpty == true)
                    ? Center(
                        child: Text("No reviews yet.",
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 16)),
                      )
                    : SizedBox(),
                // Add Review Text Area only for registered users and admins
                currentUser != null
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SizedBox(height: 15),
                            ReviewForm(
                                computeOverallRating: computeOverallRating,
                                sKey: _scaffoldKey,
                                movie: movie,
                                currentUser: currentUser,
                                notifyParent: refresh)
                          ],
                        ),
                      )
                    : SizedBox(),
                // display other reviews for this movie
                Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: !model.busy && model.reviews.isNotEmpty
                        ? DisplayReviews(
                            computeOverallRating: computeOverallRating,
                            movie: movie,
                            currentUser: currentUser,
                            sKey: _scaffoldKey,
                            notifyParent: refresh)
                        : SizedBox()),
                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
