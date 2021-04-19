import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/review.dart';
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
import 'package:modal_progress_hud/modal_progress_hud.dart';

class MovieView extends StatefulWidget {
  final Movie movie;

  MovieView({this.movie});

  @override
  _MovieViewState createState() => _MovieViewState(movie);
}

class _MovieViewState extends State<MovieView>
    with SingleTickerProviderStateMixin {
  final Movie movie;

  _MovieViewState(this.movie);

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
  var userReview;

  // Local State Variable/s
  bool _saving = false;

  // variables needed for adding reviews
  final reviewController = TextEditingController();

  // function for calling viewmodel's getCrewForDetails method
  Future<List<List<Crew>>> fetchCrew(String movieId) async {
    var model = CrewViewModel();
    var crew = await model.getCrewForDetails(movieId: movieId);

    setState(() {
      crewEdit = crew;
    });
    return crew;
  }

  String timeAgo(String formattedString) {
    final timestamp = DateTime.parse(formattedString);
    final difference = DateTime.now().difference(timestamp);
    final timeAgo =
        DateTime.now().subtract(Duration(minutes: difference.inMinutes));
    return timeago.format(timeAgo, locale: 'en_short');
  }

  void _showPopupMenu() async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        PopupMenuItem<String>(child: const Text('Doge'), value: 'Doge'),
        PopupMenuItem<String>(child: const Text('Lion'), value: 'Lion'),
      ],
      elevation: 8.0,
    );
  }

  // check if currentUser has left a review. Display in first row if true.
  Widget checkReview(List<Review> reviews) {
    if (reviews.isNotEmpty) {
      userReview =
          reviews.singleWhere((review) => review.userId == currentUser.userId);

      return Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  // leading: Icon(Icons.account_circle, size: 45),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // TO DO: fix text overflows
                          Text(
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
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            timeAgo(userReview.addedAt) + " ago" ?? ' ',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 1,
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        color: Colors.blue,
                        child: PopupMenuButton(
                          padding: EdgeInsets.zero,
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(child: Text('Edit'), value: 'edit'),
                            PopupMenuItem(
                                child: Text('Delete'), value: 'delete'),
                          ],
                          onSelected: (route) {
                            print(route);
                          },
                        ),
                      ),
                    ],
                  ),
                  subtitle: IgnorePointer(
                    ignoring: true,
                    child: userReview.rating != 0.00
                        ? RatingBar.builder(
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 20,
                            initialRating: userReview.rating,
                            unratedColor: Color.fromRGBO(192, 192, 192, 1),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rating) {},
                            updateOnDrag: true,
                          )
                        : Text("No rating",
                            style: TextStyle(
                                fontSize: 14, fontStyle: FontStyle.italic)),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    userReview.review,
                    style: TextStyle(fontSize: 15),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget displayReviews(List<Review> reviews) {
    var userReviews =
        reviews.where((review) => review.userId != currentUser.userId).toList();

    return Column(
        children: userReviews
            .map(
              (review) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      // leading: Icon(Icons.account_circle, size: 45),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              review.firstName +
                                  " " +
                                  (review.middleName != null
                                      ? review.middleName +
                                          " " +
                                          review.lastName
                                      : review.lastName) +
                                  (review.suffix != null
                                      ? " " + review.suffix
                                      : ""),
                              style: TextStyle(fontSize: 14)),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            timeAgo(review.addedAt) + " ago" ?? ' ',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      subtitle: IgnorePointer(
                        ignoring: true,
                        child: review.rating != 0.00
                            ? RatingBar.builder(
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 20,
                                initialRating: review.rating.toDouble(),
                                unratedColor: Color.fromRGBO(192, 192, 192, 1),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rating) {},
                                updateOnDrag: true,
                              )
                            : Text("No rating",
                                style: TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic)),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text(
                        review.review,
                        style: TextStyle(fontSize: 15),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList());
  }

  @override
  void initState() {
    crew = fetchCrew(movie.movieId.toString());
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

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    num _rating;
    // MediaQueryData queryData;
    // queryData = MediaQuery.of(context);

    return ViewModelProvider<ReviewViewModel>.withConsumer(
      viewModel: ReviewViewModel(),
      onModelReady: (model) {
        print(movie.movieId.toString());
        model.getAllReviews(movieId: movie.movieId.toString());

        print(model.reviews.length);
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        // extendBodyBehindAppBar: true,
        // resizeToAvoidBottomPadding: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionBubble(
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
                    builder: (context) =>
                        AddMovie(movie: movie, crewEdit: crewEdit),
                  ),
                );
                _animationController.reverse();
              },
            ),
            //Floating action menu item
            Bubble(
              title: "Delete",
              iconColor: Colors.white,
              bubbleColor: Colors.lightBlue,
              icon: Icons.delete,
              titleStyle: TextStyle(fontSize: 16, color: Colors.white),
              onPress: () async {
                _animationController.reverse();

                var response = await _dialogService.showConfirmationDialog(
                    title: "Confirm Deletion",
                    cancelTitle: "No",
                    confirmationTitle: "Yes",
                    description:
                        "Are you sure that you want to delete this movie?");
                if (response.confirmed == true) {
                  var model = MovieViewModel();

                  _saving = true;

                  var deleteRes =
                      await model.deleteMovie(id: movie.movieId.toString());
                  if (deleteRes != 0) {
                    // show success snackbar
                    _scaffoldKey.currentState.showSnackBar(mySnackBar(
                        context, 'Movie deleted successfully.', Colors.green));

                    _saving = false;

                    // redirect to homepage

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeView(),
                      ),
                    );
                  } else {
                    _saving = false;

                    _scaffoldKey.currentState.showSnackBar(mySnackBar(context,
                        'Something went wrong. Try again.', Colors.red));
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

          // Flaoting Action button Icon
          iconData: Icons.settings,
          backGroundColor: Colors.lightBlue,
        ),
        body: ModalProgressHUD(
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
                            widget.movie.poster ?? Config.imgNotFound),
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
                              imageUrl:
                                  widget.movie.poster ?? Config.imgNotFound,
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
                                    url: widget.movie.poster ??
                                        Config.imgNotFound),
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
                            // Navigator.pop(context)
                            _navigationService.navigateTo(HomeViewRoute),
                        icon: Icon(Icons.arrow_back),
                        iconSize: 30.0,
                        color: Colors.white,
                      ),
                      IconButton(
                        padding: EdgeInsets.only(right: 20.0),
                        onPressed: () => print('Add to Favorites'),
                        icon: Icon(Icons.add),
                        iconSize: 30.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: Text(
                        widget.movie.title.toUpperCase(),
                        style: TextStyle(
                            fontSize: 25.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    widget.movie.genre.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text(
                                  widget.movie.genre.reduce(
                                      (curr, next) => curr + ", " + next),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic),
                                ),
                              ])
                        : Container(),
                    Text(
                      'OVERALL RATING HERE',
                      style: TextStyle(fontSize: 20.0),
                    ),
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
                              movie.releaseDate != null ||
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
                              movie.runningTime != null ||
                                      movie.runningTime != 0
                                  ? movie.runningTime.toString() + " minuto"
                                  : '-',
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
                  widget.movie.synopsis,
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

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text("Mga Review",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              SizedBox(height: 15),

              // Add Review Text Area
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    !model.busy &&
                            (model.reviews
                                        .where((review) =>
                                            review.userId == currentUser.userId)
                                        .length !=
                                    0 &&
                                model.isEditing == false)
                        ? checkReview(model.reviews)
                        : Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(240, 240, 240, 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: InkWell(
                                // to dismiss the keyboard when the user tabs out of the TextField
                                splashColor: Colors.transparent,
                                onTap: () {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
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
                                              Text("Rating: ",
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                              RatingBar.builder(
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemSize: 25,
                                                unratedColor: Color.fromRGBO(
                                                    192, 192, 192, 1),
                                                itemPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 2.0),
                                                itemBuilder: (context, _) =>
                                                    Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                onRatingUpdate: (rating) {
                                                  _rating = rating;
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
                                      child: Text("Review:",
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                    SizedBox(height: 5),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: TextFormField(
                                        controller: reviewController,
                                        focusNode: focusNode,
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          hintText:
                                              "I-type ang iyong review...",
                                          hintStyle: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            borderSide: BorderSide.none,
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            borderSide:
                                                BorderSide(color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.only(left: 20),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5)),
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
                                          onPressed: () {
                                            focusNode.unfocus();

                                            // submit post and save into db
                                            var model = ReviewViewModel();
                                            final response = model.addReview(
                                                movieId:
                                                    movie.movieId.toString(),
                                                userId: currentUser.userId
                                                    .toString(),
                                                rating: _rating.toString(),
                                                review: reviewController.text);

                                            if (response != null) {
                                              // show success snackbar
                                              _scaffoldKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Your review has been posted.',
                                                      Colors.green));
                                            } else {
                                              // show error snackbar
                                              _scaffoldKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Something went wrong. Please try again later.',
                                                      Colors.green));
                                            }
                                          },
                                          child: Text(
                                            "POST",
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ))),
                  ],
                ),
              ),
              // display other reviews for this movie
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: !model.busy && model.reviews.isNotEmpty
                      ? displayReviews(model.reviews)
                      : Container()),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
