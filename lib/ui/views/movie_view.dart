import 'dart:convert';
// import 'dart:html';
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/review.dart';
import 'package:mubidibi/models/user.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/shared/app_colors.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
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

ValueNotifier<double> rating = ValueNotifier<double>(0.0);
var tempRating = 0.0;
var numItems = 0;

void computeOverallRating(String movieId, GlobalKey<ScaffoldState> sKey) async {
  rating = ValueNotifier<double>(0.0);
  tempRating = 0.0;
  numItems = 0;

  var model = ReviewViewModel();
  var isReady = await model.getAllReviews(movieId: movieId);

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
  }
}

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
  var overAllRating = rating;

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
    return timeago.format(timeAgo, locale: 'en_short');
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
        await model.getAllReviews(
            movieId: movie.movieId.toString(),
            accountId: currentUser != null ? currentUser.userId : "0");

        computeOverallRating(movie.movieId.toString(), _scaffoldKey);
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
                                  Text(
                                    movie.genre.reduce(
                                        (curr, next) => curr + ", " + next),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ])
                          : Container(),
                      // ValueListenableBuilder(
                      //   valueListenable: rating,
                      //   builder: (context, value, widget) {
                      //     print("VALUE: $value");
                      //     return Text(value.toString());
                      //   },
                      // ),
                      SizedBox(height: 25),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                'Petsa ng Paglabas',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
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
                          Column(
                            children: <Widget>[
                              Text(
                                'Runtime',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
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
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
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
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
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
                SizedBox(height: 15),

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
                SizedBox(height: 15),
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
                            ReviewForm(
                                // review: model.userReview,
                                sKey: _scaffoldKey,
                                movie: movie,
                                currentUser: currentUser,
                                notifyParent: refresh)
                          ],
                        ),
                      )
                    : SizedBox(),
                SizedBox(height: 15),
                // display other reviews for this movie
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: !model.busy && model.reviews.isNotEmpty
                        ? DisplayReviews(
                            // reviews: model.reviews,
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

// CLASS REVIEW FORM
class ReviewForm extends StatefulWidget {
  // final Review review;
  final GlobalKey<ScaffoldState> sKey;
  final Movie movie;
  final User currentUser;
  final Function() notifyParent;

  const ReviewForm(
      {Key key,
      // @required this.review,
      this.sKey,
      this.movie,
      this.currentUser,
      this.notifyParent})
      : super(key: key);

  @override
  ReviewFormState createState() => ReviewFormState();
}

class ReviewFormState extends State<ReviewForm> {
  final reviewController = TextEditingController();
  final reviewFocusNode = FocusNode();
  var model = ReviewViewModel();
  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();

  Review review;
  num rate = 0.0;
  bool _edit;
  bool upvoted;
  int upvoteCount;
  int downvoteCount;
  bool isApproved;
  Review userReview;
  bool submitting = false;

  String timeAgo(String formattedString) {
    final timestamp = DateTime.parse(formattedString);
    final difference = DateTime.now().difference(timestamp);
    final timeAgo =
        DateTime.now().subtract(Duration(minutes: difference.inMinutes));
    return timeago.format(timeAgo, locale: 'en_short');
  }

  void fetchUserReview() async {
    var model = ReviewViewModel();

    var reviews = await model.getAllReviews(
        movieId: widget.movie.movieId.toString(),
        accountId: widget.currentUser.userId);
    setState(() {
      userReview = model.userReview;
      reviewController.text = userReview?.review ?? '';
      rate = userReview?.rating ?? 0.0;
      upvoted = userReview?.upvoted ?? null;
      upvoteCount = userReview?.upvoteCount ?? 0;
      downvoteCount = userReview?.downvoteCount ?? 0;
      isApproved = userReview?.isApproved;
      _edit = userReview != null ? false : true;
    });
  }

  @override
  void initState() {
    fetchUserReview();
    print('initstate: $rate');

    // userReview = widget.review;
    // var model = ReviewViewModel();
    // reviewController.text = userReview?.review ?? '';
    // rate = userReview?.rating ?? 0.00;
    // upvoted = userReview?.upvoted ?? null;
    // upvoteCount = userReview?.upvoteCount ?? 0;
    // downvoteCount = userReview?.downvoteCount ?? 0;
    // isApproved = userReview?.isApproved;
    // _edit = userReview != null ? false : true;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('build: $rate');

    return _edit == false && userReview != null
        ?
        // display currentUser's review
        widget.currentUser.isAdmin == true || isApproved == true
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Card(
                            shadowColor: Colors.transparent,
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.none,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // NOTE: putting text in a container and setting overflow to ellipsis fixes the overflow problem
                                          Container(
                                            width: 200,
                                            child: Text(
                                              userReview.firstName +
                                                  " " +
                                                  (userReview.middleName != null
                                                      ? userReview.middleName +
                                                          " " +
                                                          userReview.lastName
                                                      : userReview.lastName) +
                                                  (userReview.suffix != null
                                                      ? " " + userReview.suffix
                                                      : ""),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Container(
                                            child: Text(
                                              timeAgo(userReview.addedAt) !=
                                                      null
                                                  ? (timeAgo(
                                                          userReview.addedAt) +
                                                      (timeAgo(userReview
                                                                  .addedAt) ==
                                                              "now"
                                                          ? ""
                                                          : " ago"))
                                                  : ' ',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        margin: EdgeInsets.zero,
                                        padding: EdgeInsets.zero,
                                        child: PopupMenuButton(
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (BuildContext context) =>
                                              [
                                            // PopupMenuItem(
                                            //     child: Text('Edit'),
                                            //     value: 'edit'),

                                            widget.currentUser != null &&
                                                    widget.currentUser
                                                            .isAdmin ==
                                                        true
                                                ? PopupMenuItem(
                                                    child: Text(
                                                        isApproved == true
                                                            ? 'Hide'
                                                            : 'Approve'),
                                                    value: isApproved == true
                                                        ? 'hide'
                                                        : 'approve')
                                                : null,

                                            PopupMenuItem(
                                                child: Text('Delete'),
                                                value: 'delete'),
                                          ],
                                          onSelected: (value) async {
                                            // if (value == 'edit') {
                                            //   setState(() {
                                            //     _edit = true;
                                            //   });
                                            // }
                                            if (value == "approve" ||
                                                value == "hide") {
                                              var res = await model
                                                  .changeReviewStatus(
                                                      id: userReview.reviewId,
                                                      status: !isApproved,
                                                      movieId:
                                                          widget.movie.movieId);

                                              if (res != null) {
                                                setState(() {
                                                  isApproved = res;
                                                });

                                                widget.sKey.currentState
                                                    .showSnackBar(mySnackBar(
                                                        context,
                                                        'You ' +
                                                            (value == 'approve'
                                                                ? "approved "
                                                                : "hid ") +
                                                            "this review.",
                                                        Colors.green));
                                              } else {
                                                widget.sKey.currentState
                                                    .showSnackBar(mySnackBar(
                                                        context,
                                                        "Something went wrong.",
                                                        Colors.red));
                                              }
                                            } else {
                                              var response = await _dialogService
                                                  .showConfirmationDialog(
                                                      title: "Confirm Deletion",
                                                      cancelTitle: "No",
                                                      confirmationTitle: "Yes",
                                                      description:
                                                          "Are you sure you want to delete your review?");
                                              if (response.confirmed == true) {
                                                var model = ReviewViewModel();

                                                var deleteRes =
                                                    await model.deleteReview(
                                                        id: userReview?.reviewId
                                                                .toString() ??
                                                            '0');

                                                if (deleteRes != 0) {
                                                  setState(() {
                                                    // reset
                                                    userReview = null;
                                                    reviewController.text =
                                                        userReview?.review ??
                                                            '';
                                                    rate = userReview?.rating ??
                                                        0.0;
                                                    upvoted =
                                                        userReview?.upvoted ??
                                                            null;
                                                    upvoteCount = userReview
                                                            ?.upvoteCount ??
                                                        0;
                                                    downvoteCount = userReview
                                                            ?.downvoteCount ??
                                                        0;
                                                    isApproved = userReview
                                                            ?.isApproved ??
                                                        false;
                                                    _edit = true;
                                                  });

                                                  widget.sKey.currentState
                                                      .showSnackBar(mySnackBar(
                                                          context,
                                                          'This review has been deleted.',
                                                          Colors.green));
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: IgnorePointer(
                                    ignoring: true,
                                    child: rate != null
                                        ? RatingBar.builder(
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
                                            itemSize: 20,
                                            initialRating: rate,
                                            unratedColor: Color.fromRGBO(
                                                192, 192, 192, 1),
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            onRatingUpdate: (rating) {},
                                            updateOnDrag: true,
                                          )
                                        : Text("No rating",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic)),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  child: Column(
                                    children: [
                                      Text(
                                        userReview.review,
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(),
                                Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        isApproved == true
                                            ? Row(
                                                children: [
                                                  GestureDetector(
                                                    // TO DO: Warning sign na need mag-sign in pag tinatry ng guest user magvote
                                                    onTap:
                                                        widget.currentUser !=
                                                                null
                                                            ? () async {
                                                                // categories: insert, update, delete
                                                                if (upvoted ==
                                                                    null) {
                                                                  var res = await model.vote(
                                                                      movieId: widget
                                                                          .movie
                                                                          .movieId,
                                                                      reviewId:
                                                                          userReview
                                                                              .reviewId,
                                                                      type:
                                                                          'insert',
                                                                      value:
                                                                          true,
                                                                      userId: widget
                                                                          .currentUser
                                                                          .userId);

                                                                  var itemRes = res.singleWhere(
                                                                      (review) =>
                                                                          review
                                                                              .userId ==
                                                                          widget
                                                                              .currentUser
                                                                              .userId,
                                                                      orElse: () =>
                                                                          null);

                                                                  setState(() {
                                                                    upvoted =
                                                                        itemRes?.upvoted ??
                                                                            null;
                                                                    upvoteCount =
                                                                        itemRes?.upvoteCount ??
                                                                            0;
                                                                    downvoteCount =
                                                                        itemRes?.downvoteCount ??
                                                                            0;
                                                                  });
                                                                } else if (upvoted ==
                                                                    false) {
                                                                  var res = await model.vote(
                                                                      movieId: widget
                                                                          .movie
                                                                          .movieId,
                                                                      reviewId:
                                                                          userReview
                                                                              .reviewId,
                                                                      type:
                                                                          'update',
                                                                      value:
                                                                          true,
                                                                      userId: widget
                                                                          .currentUser
                                                                          .userId);

                                                                  var itemRes = res.singleWhere(
                                                                      (review) =>
                                                                          review
                                                                              .userId ==
                                                                          widget
                                                                              .currentUser
                                                                              .userId,
                                                                      orElse: () =>
                                                                          null);

                                                                  setState(() {
                                                                    upvoted =
                                                                        itemRes?.upvoted ??
                                                                            null;
                                                                    upvoteCount =
                                                                        itemRes?.upvoteCount ??
                                                                            0;
                                                                    downvoteCount =
                                                                        itemRes?.downvoteCount ??
                                                                            0;
                                                                  });
                                                                } else {
                                                                  var res = await model.vote(
                                                                      movieId: widget
                                                                          .movie
                                                                          .movieId,
                                                                      reviewId:
                                                                          userReview
                                                                              .reviewId,
                                                                      type:
                                                                          'delete',
                                                                      value:
                                                                          null,
                                                                      userId: widget
                                                                          .currentUser
                                                                          .userId);

                                                                  var itemRes = res.singleWhere(
                                                                      (review) =>
                                                                          review
                                                                              .userId ==
                                                                          widget
                                                                              .currentUser
                                                                              .userId,
                                                                      orElse: () =>
                                                                          null);

                                                                  setState(() {
                                                                    upvoted =
                                                                        itemRes?.upvoted ??
                                                                            null;
                                                                    upvoteCount =
                                                                        itemRes?.upvoteCount ??
                                                                            0;
                                                                    downvoteCount =
                                                                        itemRes?.downvoteCount ??
                                                                            0;
                                                                  });
                                                                }
                                                              }
                                                            : () {
                                                                widget.sKey
                                                                    .currentState
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    duration:
                                                                        Duration(
                                                                            days:
                                                                                1),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    content:
                                                                        Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Text(
                                                                              "You're not signed in. Click ",
                                                                              style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.white),
                                                                            ),
                                                                            InkWell(
                                                                                onTap: () {
                                                                                  _navigationService.navigateTo(SignInCategoryViewRoute);
                                                                                },
                                                                                child: Text(
                                                                                  'here',
                                                                                  style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.blue, decoration: TextDecoration.underline),
                                                                                )),
                                                                          ],
                                                                        ),
                                                                        GestureDetector(
                                                                            child:
                                                                                Icon(Icons.close),
                                                                            onTap: () {
                                                                              widget.sKey.currentState.hideCurrentSnackBar();
                                                                            }),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                    child: Icon(
                                                        Icons.thumb_up_off_alt,
                                                        color: upvoted == true
                                                            ? Colors.green
                                                            : Color.fromRGBO(
                                                                192,
                                                                192,
                                                                192,
                                                                1)),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(upvoteCount.toString()),
                                                  SizedBox(width: 10),
                                                  GestureDetector(
                                                    onTap: widget.currentUser !=
                                                            null
                                                        ? () async {
                                                            // categories: insert, update, delete
                                                            if (upvoted ==
                                                                null) {
                                                              var res = await model.vote(
                                                                  movieId: widget
                                                                      .movie
                                                                      .movieId,
                                                                  reviewId:
                                                                      userReview
                                                                          .reviewId,
                                                                  type:
                                                                      'insert',
                                                                  value: false,
                                                                  userId: widget
                                                                      .currentUser
                                                                      .userId);

                                                              var itemRes = res.singleWhere(
                                                                  (review) =>
                                                                      review
                                                                          .userId ==
                                                                      widget
                                                                          .currentUser
                                                                          .userId,
                                                                  orElse: () =>
                                                                      null);

                                                              setState(() {
                                                                upvoted = itemRes
                                                                        ?.upvoted ??
                                                                    null;
                                                                upvoteCount =
                                                                    itemRes?.upvoteCount ??
                                                                        0;
                                                                downvoteCount =
                                                                    itemRes?.downvoteCount ??
                                                                        0;
                                                              });
                                                            } else if (upvoted ==
                                                                true) {
                                                              var res = await model.vote(
                                                                  movieId: widget
                                                                      .movie
                                                                      .movieId,
                                                                  reviewId:
                                                                      userReview
                                                                          .reviewId,
                                                                  type:
                                                                      'update',
                                                                  value: false,
                                                                  userId: widget
                                                                      .currentUser
                                                                      .userId);

                                                              var itemRes = res.singleWhere(
                                                                  (review) =>
                                                                      review
                                                                          .userId ==
                                                                      widget
                                                                          .currentUser
                                                                          .userId,
                                                                  orElse: () =>
                                                                      null);

                                                              setState(() {
                                                                upvoted = itemRes
                                                                        ?.upvoted ??
                                                                    null;
                                                                upvoteCount =
                                                                    itemRes?.upvoteCount ??
                                                                        0;
                                                                downvoteCount =
                                                                    itemRes?.downvoteCount ??
                                                                        0;
                                                              });
                                                            } else {
                                                              var res = await model.vote(
                                                                  movieId: widget
                                                                      .movie
                                                                      .movieId,
                                                                  reviewId:
                                                                      userReview
                                                                          .reviewId,
                                                                  type:
                                                                      'delete',
                                                                  value: null,
                                                                  userId: widget
                                                                      .currentUser
                                                                      .userId);

                                                              var itemRes = res.singleWhere(
                                                                  (review) =>
                                                                      review
                                                                          .userId ==
                                                                      widget
                                                                          .currentUser
                                                                          .userId,
                                                                  orElse: () =>
                                                                      null);

                                                              setState(() {
                                                                upvoted = itemRes
                                                                        ?.upvoted ??
                                                                    null;
                                                                upvoteCount =
                                                                    itemRes?.upvoteCount ??
                                                                        0;
                                                                downvoteCount =
                                                                    itemRes?.downvoteCount ??
                                                                        0;
                                                              });
                                                            }
                                                          }
                                                        : null,
                                                    child: Icon(
                                                        Icons
                                                            .thumb_down_off_alt,
                                                        color: upvoted == false
                                                            ? Colors.red
                                                            : Color.fromRGBO(
                                                                192,
                                                                192,
                                                                192,
                                                                1)),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                      downvoteCount.toString()),
                                                ],
                                              )
                                            : SizedBox(),
                                        widget.currentUser != null &&
                                                widget.currentUser.isAdmin &&
                                                isApproved == false
                                            ? Container(
                                                child: Text(
                                                  "Review hidden",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontStyle:
                                                          FontStyle.italic),
                                                ),
                                              )
                                            : SizedBox(),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox()

        // write review
        : Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(240, 240, 240, 1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: InkWell(
                // to dismiss the keyboard when the user taps out of the TextField
                splashColor: Colors.transparent,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Text("Rating: ", style: TextStyle(fontSize: 16)),
                              RatingBar.builder(
                                initialRating: rate,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 25,
                                unratedColor: Color.fromRGBO(192, 192, 192, 1),
                                itemPadding:
                                    EdgeInsets.symmetric(horizontal: 2.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rating) {
                                  setState(() {
                                    rate = rating;
                                  });
                                },
                                updateOnDrag: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text("Review:", style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: reviewController,
                        focusNode: reviewFocusNode,
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "I-type ang iyong review...",
                          hintStyle: TextStyle(
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value.isEmpty || value == null) {
                            return 'Required ang field na ito.';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(children: [
                      Container(
                        padding: EdgeInsets.only(left: 20),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5)),
                        child: ButtonTheme(
                          padding: EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal:
                                  10.0), //adds padding inside the button
                          materialTapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, //limits the touch area to the button area
                          minWidth: 0, //wraps child's width
                          height: 0,
                          child: FlatButton(
                              color: Colors.lightBlue,
                              onPressed: submitting == false
                                  ? () async {
                                      reviewFocusNode.unfocus();

                                      // submit post and save into db
                                      var model = ReviewViewModel();
                                      final response = await model.addReview(
                                          reviewId: userReview?.reviewId ?? 0,
                                          movieId:
                                              widget.movie.movieId.toString(),
                                          userId: widget.currentUser.userId
                                              .toString(),
                                          rating: rate.toString(),
                                          review: reviewController.text);

                                      if (response != null) {
                                        // fetch reviews again
                                        var newReview = await model.getReview(
                                            accountId:
                                                widget.currentUser.userId,
                                            movieId: widget.movie.movieId);

                                        if (newReview != null) {
                                          setState(() {
                                            userReview = newReview;
                                            submitting = false;
                                            _edit = false;
                                          });

                                          // show success snackbar
                                          widget.sKey.currentState.showSnackBar(
                                              mySnackBar(
                                                  context,
                                                  'Your review is pending for approval.',
                                                  Colors.orange));
                                        } else {
                                          // show error snackbar
                                          widget.sKey.currentState.showSnackBar(
                                              mySnackBar(
                                                  context,
                                                  'Something went wrong. Please try again later.',
                                                  Colors.red));
                                        }
                                      } else {
                                        widget.sKey.currentState.showSnackBar(
                                            mySnackBar(
                                                context,
                                                'Something went wrong. Please try again later.',
                                                Colors.red));
                                      }
                                    }
                                  : null,
                              child: Text(
                                "POST",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white),
                              )),
                        ),
                      ),
                      _edit == true
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: InkWell(
                                onTap: () {
                                  reviewFocusNode.unfocus();
                                  setState(() {
                                    // reset
                                    userReview = null;
                                    reviewController.text =
                                        userReview?.review ?? '';
                                    rate = userReview?.rating ?? 0.0;
                                    upvoted = userReview?.upvoted ?? null;
                                    upvoteCount = userReview?.upvoteCount ?? 0;
                                    downvoteCount =
                                        userReview?.downvoteCount ?? 0;
                                    isApproved =
                                        userReview?.isApproved ?? false;
                                    _edit = true;
                                  });
                                },
                                child: Text(
                                  "CANCEL",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            )
                          : SizedBox(),
                    ]),
                    SizedBox(height: 10),
                  ],
                )));
  }
}

// CLASS DISPLAY REVIEWS

class DisplayReviews extends StatefulWidget {
  // final List<Review> reviews;
  final Movie movie;
  final User currentUser;
  final GlobalKey<ScaffoldState> sKey;
  final Function() notifyParent;

  const DisplayReviews(
      {Key key,
      // @required this.reviews,
      this.movie,
      this.currentUser,
      this.sKey,
      this.notifyParent})
      : super(key: key);

  @override
  DisplayReviewsState createState() => DisplayReviewsState();
}

class DisplayReviewsState extends State<DisplayReviews> {
  var model = ReviewViewModel();
  List<bool> upvoted = [];
  List<int> upvoteCount = [];
  List<int> downvoteCount = [];
  List<Review> userReviews = [];
  List<bool> isApproved = [];

  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();

  String timeAgo(String formattedString) {
    final timestamp = DateTime.parse(formattedString);
    final difference = DateTime.now().difference(timestamp);
    final timeAgo =
        DateTime.now().subtract(Duration(minutes: difference.inMinutes));
    return timeago.format(timeAgo, locale: 'en_short');
  }

  void fetchReviews() async {
    var res = await model.getAllReviews(
        movieId: widget.movie.movieId.toString(),
        accountId: widget.currentUser.userId);

    setState(() {
      userReviews = widget.currentUser != null
          ? model.reviews
              .where((review) => review.userId != widget.currentUser.userId)
              .toList()
          : model.reviews;

      for (var i = 0; i < userReviews?.length ?? 0; i++) {
        upvoted.add(userReviews[i]?.upvoted);
        upvoteCount.add(userReviews[i]?.upvoteCount ?? 0);
        downvoteCount.add(userReviews[i]?.downvoteCount ?? 0);
        isApproved.add(userReviews[i]?.isApproved ?? false);
      }
    });
  }

  @override
  void initState() {
    fetchReviews();
    // userReviews = widget.currentUser != null
    //     ? widget.reviews
    //         .where((review) => review.userId != widget.currentUser.userId)
    //         .toList()
    //     : widget.reviews;

    // for (var i = 0; i < userReviews?.length ?? 0; i++) {
    //   upvoted.add(userReviews[i]?.upvoted);
    //   upvoteCount.add(userReviews[i]?.upvoteCount ?? 0);
    //   downvoteCount.add(userReviews[i]?.downvoteCount ?? 0);
    //   isApproved.add(userReviews[i]?.isApproved ?? false);
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: userReviews.map((review) {
      var index = userReviews.indexOf(review);
      return (widget.currentUser != null &&
                  widget.currentUser.isAdmin == true) ||
              isApproved[index] == true
          ? Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Card(
                              shadowColor: Colors.transparent,
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.none,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 200,
                                              child: Text(
                                                  review.firstName +
                                                      (review.middleName != null
                                                          ? " " +
                                                              review.middleName
                                                          : "") +
                                                      (review.lastName != null
                                                          ? " " +
                                                              review.lastName
                                                          : "") +
                                                      (review.suffix != null
                                                          ? " " + review.suffix
                                                          : ""),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            widget.currentUser != null
                                                ? Container(
                                                    child: Text(
                                                      timeAgo(review.addedAt) !=
                                                              null
                                                          ? (timeAgo(review
                                                                  .addedAt) +
                                                              (timeAgo(review
                                                                          .addedAt) ==
                                                                      "now"
                                                                  ? ""
                                                                  : " ago"))
                                                          : ' ',
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14),
                                                    ),
                                                  )
                                                : SizedBox(),
                                          ],
                                        ),
                                        widget.currentUser != null &&
                                                widget.currentUser.isAdmin ==
                                                    true
                                            ? Container(
                                                margin: EdgeInsets.zero,
                                                padding: EdgeInsets.zero,
                                                child: PopupMenuButton(
                                                  padding: EdgeInsets.zero,
                                                  itemBuilder:
                                                      (BuildContext context) =>
                                                          [
                                                    widget.currentUser !=
                                                                null &&
                                                            widget.currentUser
                                                                    .isAdmin ==
                                                                true
                                                        ? PopupMenuItem(
                                                            child: Text(isApproved[
                                                                        index] ==
                                                                    true
                                                                ? 'Hide'
                                                                : 'Approve'),
                                                            value: isApproved[
                                                                        index] ==
                                                                    true
                                                                ? 'hide'
                                                                : 'approve')
                                                        : null,
                                                    widget.currentUser !=
                                                                null &&
                                                            widget.currentUser
                                                                    .isAdmin ==
                                                                true
                                                        ? PopupMenuItem(
                                                            child:
                                                                Text('Delete'),
                                                            value: 'delete')
                                                        : null,
                                                  ],
                                                  onSelected: (value) async {
                                                    if (value == 'approve' ||
                                                        value == 'hide') {
                                                      var res = await model
                                                          .changeReviewStatus(
                                                              id: review
                                                                  .reviewId,
                                                              status:
                                                                  !isApproved[
                                                                      index],
                                                              movieId: widget
                                                                  .movie
                                                                  .movieId);

                                                      if (res != null) {
                                                        setState(() {
                                                          isApproved[index] =
                                                              res;
                                                        });

                                                        widget.sKey.currentState
                                                            .showSnackBar(mySnackBar(
                                                                context,
                                                                'You ' +
                                                                    (value ==
                                                                            'approve'
                                                                        ? "approved "
                                                                        : "hid ") +
                                                                    "this review.",
                                                                Colors.green));
                                                      } else {
                                                        widget.sKey.currentState
                                                            .showSnackBar(
                                                                mySnackBar(
                                                                    context,
                                                                    "Something went wrong.",
                                                                    Colors
                                                                        .red));
                                                      }
                                                    } else {
                                                      var response = await _dialogService
                                                          .showConfirmationDialog(
                                                              title:
                                                                  "Confirm Deletion",
                                                              cancelTitle: "No",
                                                              confirmationTitle:
                                                                  "Yes",
                                                              description:
                                                                  "Are you sure you want to delete this review?");
                                                      if (response.confirmed ==
                                                          true) {
                                                        var model =
                                                            ReviewViewModel();

                                                        var deleteRes = await model
                                                            .deleteReview(
                                                                id: review
                                                                        ?.reviewId
                                                                        .toString() ??
                                                                    '0');

                                                        if (deleteRes != 0) {
                                                          model.getAllReviews(
                                                              movieId: widget
                                                                  .movie.movieId
                                                                  .toString(),
                                                              accountId: widget
                                                                  .currentUser
                                                                  .userId);

                                                          var newItems = model
                                                              .reviews
                                                              .where((item) =>
                                                                  item.reviewId !=
                                                                  model
                                                                      .userReview
                                                                      .reviewId)
                                                              .toList();

                                                          setState(() {
                                                            userReviews =
                                                                newItems;
                                                          });

                                                          widget
                                                              .sKey.currentState
                                                              .showSnackBar(mySnackBar(
                                                                  context,
                                                                  'This review has been deleted.',
                                                                  Colors
                                                                      .green));
                                                        }
                                                      }
                                                    }
                                                  },
                                                ),
                                              )
                                            : Container(
                                                child: Text(
                                                  timeAgo(review.addedAt) !=
                                                          null
                                                      ? (timeAgo(
                                                              review.addedAt) +
                                                          (timeAgo(review
                                                                      .addedAt) ==
                                                                  "now"
                                                              ? ""
                                                              : " ago"))
                                                      : ' ',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                              )
                                      ],
                                    ),
                                    subtitle: IgnorePointer(
                                      ignoring: true,
                                      child: review.rating != null
                                          ? RatingBar.builder(
                                              direction: Axis.horizontal,
                                              allowHalfRating: true,
                                              itemCount: 5,
                                              itemSize: 20,
                                              initialRating:
                                                  review.rating.toDouble(),
                                              unratedColor: Color.fromRGBO(
                                                  192, 192, 192, 1),
                                              itemBuilder: (context, _) => Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) {},
                                              updateOnDrag: true,
                                            )
                                          : Text("No rating",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontStyle: FontStyle.italic)),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                    child: Text(
                                      review.review,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Divider(),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          isApproved[index] == true
                                              ? Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap:
                                                          widget.currentUser !=
                                                                  null
                                                              ? () async {
                                                                  // categories: insert, update, delete
                                                                  if (upvoted[
                                                                          index] ==
                                                                      null) {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'insert',
                                                                        value:
                                                                            true,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);

                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  } else if (upvoted[
                                                                          index] ==
                                                                      false) {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'update',
                                                                        value:
                                                                            true,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);

                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  } else {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'delete',
                                                                        value:
                                                                            null,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);

                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  }
                                                                }
                                                              : () {
                                                                  widget.sKey
                                                                      .currentState
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      duration:
                                                                          Duration(
                                                                              days: 1),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                      content:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                "You're not signed in. Click ",
                                                                                style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.white),
                                                                              ),
                                                                              InkWell(
                                                                                  onTap: () {
                                                                                    _navigationService.navigateTo(SignInCategoryViewRoute);
                                                                                  },
                                                                                  child: Text(
                                                                                    'here',
                                                                                    style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.blue, decoration: TextDecoration.underline),
                                                                                  )),
                                                                            ],
                                                                          ),
                                                                          GestureDetector(
                                                                              child: Icon(Icons.close),
                                                                              onTap: () {
                                                                                widget.sKey.currentState.hideCurrentSnackBar();
                                                                              }),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                      child: Icon(
                                                          Icons
                                                              .thumb_up_off_alt,
                                                          color: upvoted[
                                                                      index] ==
                                                                  true
                                                              ? Colors.green
                                                              : Color.fromRGBO(
                                                                  192,
                                                                  192,
                                                                  192,
                                                                  1)),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(upvoteCount[index]
                                                        .toString()),
                                                    SizedBox(width: 10),
                                                    GestureDetector(
                                                      onTap:
                                                          widget.currentUser !=
                                                                  null
                                                              ? () async {
                                                                  // categories: insert, update, delete
                                                                  if (upvoted[
                                                                          index] ==
                                                                      null) {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'insert',
                                                                        value:
                                                                            false,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);
                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  } else if (upvoted[
                                                                          index] ==
                                                                      true) {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'update',
                                                                        value:
                                                                            false,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);

                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  } else {
                                                                    var res = await model.vote(
                                                                        movieId: widget
                                                                            .movie
                                                                            .movieId,
                                                                        reviewId:
                                                                            review
                                                                                .reviewId,
                                                                        type:
                                                                            'delete',
                                                                        value:
                                                                            null,
                                                                        userId: widget
                                                                            .currentUser
                                                                            .userId);

                                                                    var itemRes = res.singleWhere(
                                                                        (r) =>
                                                                            r.reviewId ==
                                                                            review
                                                                                .reviewId,
                                                                        orElse: () =>
                                                                            null);

                                                                    setState(
                                                                        () {
                                                                      upvoted[
                                                                          index] = itemRes
                                                                              ?.upvoted ??
                                                                          null;
                                                                      upvoteCount[
                                                                              index] =
                                                                          itemRes?.upvoteCount ??
                                                                              0;
                                                                      downvoteCount[
                                                                              index] =
                                                                          itemRes?.downvoteCount ??
                                                                              0;
                                                                    });
                                                                  }
                                                                }
                                                              : () {
                                                                  widget.sKey
                                                                      .currentState
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      duration:
                                                                          Duration(
                                                                              days: 1),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                      content:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                "You're not signed in. Click ",
                                                                                style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.white),
                                                                              ),
                                                                              InkWell(
                                                                                  onTap: () {
                                                                                    _navigationService.navigateTo(SignInCategoryViewRoute);
                                                                                  },
                                                                                  child: Text(
                                                                                    'here',
                                                                                    style: Theme.of(context).textTheme.subtitle1.apply(color: Colors.blue, decoration: TextDecoration.underline),
                                                                                  )),
                                                                            ],
                                                                          ),
                                                                          GestureDetector(
                                                                              child: Icon(Icons.close),
                                                                              onTap: () {
                                                                                widget.sKey.currentState.hideCurrentSnackBar();
                                                                              }),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                      child: Icon(
                                                          Icons
                                                              .thumb_down_off_alt,
                                                          color: upvoted[
                                                                      index] ==
                                                                  false
                                                              ? Colors.red
                                                              : Color.fromRGBO(
                                                                  192,
                                                                  192,
                                                                  192,
                                                                  1)),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(downvoteCount[index]
                                                        .toString()),
                                                  ],
                                                )
                                              : SizedBox(),
                                          widget.currentUser != null &&
                                                  widget.currentUser.isAdmin &&
                                                  isApproved[index] == false
                                              ? Container(
                                                  child: Text(
                                                    "Review hidden",
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                )
                                              : SizedBox(),
                                        ],
                                      ))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            )
          : SizedBox();
    }).toList());
  }
}
