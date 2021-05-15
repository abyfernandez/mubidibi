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
  // var userReview;
  double overallRating = 0.0;

  // local variables
  bool _saving = false;
  bool userHasVoted;

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

  // check if currentUser has left a review. Display in first row if true.
  Widget checkReview(Review userReview, GlobalKey<ScaffoldState> _sKey) {
    var model = ReviewViewModel();
    var _edit = false;

    if (userReview != null) {
      return _edit == false
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          // TO DO: Warning sign na need mag-sign in pag tinatry ng guest user magvote
                          onTap: currentUser != null
                              ? () {
                                  // categories: insert, update, delete
                                  if (userReview.upvoted == null) {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'insert',
                                        value: true,
                                        userId: currentUser.userId);
                                  } else if (userReview.upvoted == false) {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'update',
                                        value: true,
                                        userId: currentUser.userId);
                                  } else {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'delete',
                                        value: null,
                                        userId: currentUser.userId);
                                  }
                                }
                              : null,
                          child: Image.network(
                            'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075331/images/up-arrow_aouhte.png',
                            height: 15,
                            width: 20,
                            color: userReview.upvoted == true
                                ? Colors.green
                                : Color.fromRGBO(192, 192, 192, 1),
                          ),
                        ),
                        Text((userReview.upvoteCount - userReview.downvoteCount)
                            .toString()),
                        GestureDetector(
                          onTap: currentUser != null
                              ? () {
                                  // categories: insert, update, delete
                                  if (userReview.upvoted == null) {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'insert',
                                        value: false,
                                        userId: currentUser.userId);
                                  } else if (userReview.upvoted == true) {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'update',
                                        value: false,
                                        userId: currentUser.userId);
                                  } else {
                                    model.vote(
                                        movieId: movie.movieId,
                                        reviewId: userReview.reviewId,
                                        type: 'delete',
                                        value: null,
                                        userId: currentUser.userId);
                                  }
                                }
                              : null,
                          child: Image.network(
                            'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075332/images/down-arrow_lb8dht.png',
                            height: 15,
                            color: userReview.upvoted == false
                                ? Colors.red
                                : Color.fromRGBO(192, 192, 192, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                                            style: TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Container(
                                          child: Text(
                                            timeAgo(userReview.addedAt) +
                                                    " ago" ??
                                                ' ',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            overflow: TextOverflow.clip,
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.zero,
                                      child: PopupMenuButton(
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem(
                                              child: Text('Edit'),
                                              value: 'edit'),
                                          PopupMenuItem(
                                              child: Text('Delete'),
                                              value: 'delete'),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            // setState(() {
                                            _edit = true;
                                            // });
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
                                                _sKey.currentState.showSnackBar(
                                                    mySnackBar(
                                                        context,
                                                        'Your review has been deleted.',
                                                        Colors.green));

                                                Timer(
                                                    const Duration(
                                                        milliseconds: 2000),
                                                    () {
                                                  model.getAllReviews(
                                                      movieId: movie.movieId
                                                          .toString(),
                                                      accountId: currentUser
                                                          .userId
                                                          .toString());

                                                  Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            MovieView(
                                                          movieId: movie.movieId
                                                              .toString(),
                                                        ),
                                                      ));
                                                });
                                              }
                                            }

                                            setState(() {});
                                          }
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
                                          unratedColor:
                                              Color.fromRGBO(192, 192, 192, 1),
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
                                    horizontal: 20, vertical: 10),
                                child: Column(
                                  children: [
                                    Text(
                                      userReview.review,
                                      style: TextStyle(fontSize: 14),
                                      // textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : ReviewForm(
              userReview: userReview,
              sKey: _sKey,
              movie: movie,
              currentUser: currentUser);
    } else {
      return Container();
    }
  }

  Widget displayReviews(List<Review> reviews) {
    var model = ReviewViewModel();
    var userReviews = currentUser != null
        ? reviews
            .where((review) => review.userId != currentUser.userId)
            .toList()
        : reviews;

    return Column(
        children: userReviews.map((review) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // upvote
                      GestureDetector(
                        // TO DO: Warning sign na need mag-sign in pag tinatry ng guest user magvote
                        onTap: currentUser != null
                            ? () {
                                // categories: insert, update, delete
                                if (review.upvoted == null) {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'insert',
                                      value: true,
                                      userId: currentUser.userId);
                                } else if (review.upvoted == false) {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'update',
                                      value: true,
                                      userId: currentUser.userId);
                                } else {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'delete',
                                      value: null,
                                      userId: currentUser.userId);
                                }
                              }
                            : null,
                        child: Image.network(
                          'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075331/images/up-arrow_aouhte.png',
                          height: 15,
                          width: 20,
                          color: review.upvoted == true
                              ? Colors.green
                              : Color.fromRGBO(192, 192, 192, 1),
                        ),
                      ),
                      // current vote count
                      Text((review.upvoteCount - review.downvoteCount)
                          .toString()),
                      // downvote
                      GestureDetector(
                        onTap: currentUser != null
                            ? () {
                                // categories: insert, update, delete
                                if (review.upvoted == null) {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'insert',
                                      value: false,
                                      userId: currentUser.userId);
                                } else if (review.upvoted == true) {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'update',
                                      value: false,
                                      userId: currentUser.userId);
                                } else {
                                  model.vote(
                                      movieId: movie.movieId,
                                      reviewId: review.reviewId,
                                      type: 'delete',
                                      value: null,
                                      userId: currentUser.userId);
                                }
                              }
                            : null,
                        child: Image.network(
                          'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075332/images/down-arrow_lb8dht.png',
                          height: 15,
                          width: 20,
                          color: review.upvoted == false
                              ? Colors.red
                              : Color.fromRGBO(192, 192, 192, 1),
                        ),
                      ),
                    ],
                  ),
                ),
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
                                  Text(
                                      review.firstName +
                                          (review.middleName != null
                                              ? " " + review.middleName
                                              : "") +
                                          (review.lastName != null
                                              ? " " + review.lastName
                                              : "") +
                                          (review.suffix != null
                                              ? " " + review.suffix
                                              : ""),
                                      style: TextStyle(fontSize: 14)),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    timeAgo(review.addedAt) + " ago" ?? ' ',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
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
                                        unratedColor:
                                            Color.fromRGBO(192, 192, 192, 1),
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
                                  horizontal: 20, vertical: 10),
                              child: Text(
                                review.review,
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
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
      );
    }).toList());
  }

  Widget computeOverallRating(List<Review> reviews) {
    var rating = 0.0;
    for (var i = 0; i < reviews.length; i++) {
      rating += reviews[i].rating;
    }
    rating = rating != 0 ? rating / reviews.length : 0.0;

    // TO DO: accurate display of overall rating
    return IgnorePointer(
        ignoring: true,
        child: RatingBar.builder(
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 25,
          initialRating: rating,
          unratedColor: Color.fromRGBO(192, 192, 192, 1),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {},
          updateOnDrag: true,
        ));
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

  // Widget showReviewForm(Review userReview, GlobalKey<ScaffoldState> _sKey) {
  //   reviewController.text = userReview?.review ?? '';
  //   num rate = userReview?.rating ?? 0.00;
  //   bool _edit = false;

  //   return Container(
  //       decoration: BoxDecoration(
  //         color: Color.fromRGBO(240, 240, 240, 1),
  //         borderRadius: BorderRadius.circular(5),
  //       ),
  //       child: InkWell(
  //           // to dismiss the keyboard when the user taps out of the TextField
  //           splashColor: Colors.transparent,
  //           onTap: () {
  //             FocusScope.of(context).requestFocus(FocusNode());
  //           },
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   SizedBox(
  //                     width: 10,
  //                   ),
  //                   Padding(
  //                     padding: EdgeInsets.only(top: 10),
  //                     child: Row(
  //                       children: [
  //                         Text("Rating: ", style: TextStyle(fontSize: 16)),
  //                         RatingBar.builder(
  //                           initialRating: rate,
  //                           direction: Axis.horizontal,
  //                           allowHalfRating: true,
  //                           itemCount: 5,
  //                           itemSize: 25,
  //                           unratedColor: Color.fromRGBO(192, 192, 192, 1),
  //                           itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
  //                           itemBuilder: (context, _) => Icon(
  //                             Icons.star,
  //                             color: Colors.amber,
  //                           ),
  //                           onRatingUpdate: (rating) {
  //                             rate = rating;
  //                           },
  //                           updateOnDrag: true,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               SizedBox(height: 10),
  //               Padding(
  //                 padding: EdgeInsets.only(left: 10),
  //                 child: Text("Review:", style: TextStyle(fontSize: 16)),
  //               ),
  //               SizedBox(height: 5),
  //               Padding(
  //                 padding: EdgeInsets.symmetric(horizontal: 20),
  //                 child: TextFormField(
  //                   controller: reviewController,
  //                   // initialValue: rev,
  //                   focusNode: focusNode,
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                   ),
  //                   maxLines: null,
  //                   decoration: InputDecoration(
  //                     filled: true,
  //                     fillColor: Colors.white,
  //                     hintText: "I-type ang iyong review...",
  //                     hintStyle: TextStyle(
  //                       color: Colors.black87,
  //                       fontSize: 16,
  //                     ),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(5),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(5),
  //                       borderSide: BorderSide.none,
  //                     ),
  //                     errorBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(5),
  //                       borderSide: BorderSide(color: Colors.red),
  //                     ),
  //                   ),
  //                   validator: (value) {
  //                     if (value.isEmpty || value == null) {
  //                       return 'Required ang field na ito.';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //               ),
  //               SizedBox(height: 10),
  //               Row(children: [
  //                 Container(
  //                   padding: EdgeInsets.only(left: 20),
  //                   alignment: Alignment.centerLeft,
  //                   decoration:
  //                       BoxDecoration(borderRadius: BorderRadius.circular(5)),
  //                   child: ButtonTheme(
  //                     padding: EdgeInsets.symmetric(
  //                         vertical: 6.0,
  //                         horizontal: 10.0), //adds padding inside the button
  //                     materialTapTargetSize: MaterialTapTargetSize
  //                         .shrinkWrap, //limits the touch area to the button area
  //                     minWidth: 0, //wraps child's width
  //                     height: 0,
  //                     child: FlatButton(
  //                       color: Colors.lightBlue,
  //                       onPressed: () async {
  //                         focusNode.unfocus();

  //                         // submit post and save into db
  //                         var model = ReviewViewModel();
  //                         final response = await model.addReview(
  //                             reviewId: userReview?.reviewId ?? "0",
  //                             movieId: movie.movieId.toString(),
  //                             userId: currentUser.userId.toString(),
  //                             rating: rate.toString(),
  //                             review: reviewController.text);

  //                         if (response != null) {
  //                           // show success snackbar
  //                           _sKey.currentState.showSnackBar(mySnackBar(context,
  //                               'Your review has been posted.', Colors.green));

  //                           Timer(const Duration(milliseconds: 2000), () {
  //                             // fetch reviews again
  //                             model.getAllReviews(
  //                                 movieId: movie.movieId.toString(),
  //                                 accountId: currentUser.userId.toString());

  //                             _edit = false;
  //                             setState(() {});
  //                             // Navigator.pop(context);
  //                             // Navigator.pushReplacement(
  //                             //     context,
  //                             //     MaterialPageRoute(
  //                             //         builder: (BuildContext context) =>
  //                             //             MovieView(
  //                             //               movieId: movie.movieId.toString(),
  //                             //             )));
  //                           });
  //                         } else {
  //                           _sKey.currentState.showSnackBar(mySnackBar(
  //                               context,
  //                               'Something went wrong. Please try again later.',
  //                               Colors.red));
  //                         }
  //                       },
  //                       child: Text(
  //                         "POST",
  //                         style: TextStyle(fontSize: 14, color: Colors.white),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 _edit == true
  //                     ? Container(
  //                         padding: EdgeInsets.only(left: 20),
  //                         alignment: Alignment.centerLeft,
  //                         decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(5)),
  //                         child: ButtonTheme(
  //                             padding: EdgeInsets.symmetric(
  //                                 vertical: 6.0,
  //                                 horizontal:
  //                                     10.0), //adds padding inside the button
  //                             materialTapTargetSize: MaterialTapTargetSize
  //                                 .shrinkWrap, //limits the touch area to the button area
  //                             minWidth: 0, //wraps child's width
  //                             height: 0,
  //                             child: FlatButton(
  //                               color: Colors.lightBlue,
  //                               onPressed: () {
  //                                 focusNode.unfocus();
  //                                 _edit = false;
  //                                 setState(() {});
  //                               },
  //                               child: Text(
  //                                 "Cancel",
  //                                 style: TextStyle(
  //                                     fontSize: 14, color: Colors.white),
  //                               ),
  //                             )))
  //                     : SizedBox(),
  //               ]),
  //               SizedBox(height: 10),
  //             ],
  //           )));
  // }

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
    print("didUpdateWidget");
  }

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    if (movie == null) return Center(child: CircularProgressIndicator());

    return ViewModelProvider<ReviewViewModel>.withConsumer(
      viewModel: ReviewViewModel(),
      onModelReady: (model) {
        model.getAllReviews(
            movieId: movie.movieId.toString(),
            accountId: currentUser != null ? currentUser.userId : "0");
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
                      computeOverallRating(model.reviews),
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

                // Add Review Text Area only for registered users and admins
                currentUser != null
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // !model.busy &&
                            //         (model.reviews
                            //                     .where((review) =>
                            //                         review.userId ==
                            //                         currentUser.userId)
                            //                     .length !=
                            //                 0 &&
                            //             model.isEditing == false)
                            //     ? checkReview(model.userReview, _scaffoldKey)
                            //     : ReviewForm(
                            //         userReview: model.userReview,
                            //         sKey: _scaffoldKey,
                            //         movie: movie,
                            //         currentUser: currentUser)
                            ReviewForm(
                                userReview: model.userReview,
                                sKey: _scaffoldKey,
                                movie: movie,
                                currentUser: currentUser)
                          ],
                        ),
                      )
                    : SizedBox(),
                SizedBox(height: 15),
                // display other reviews for this movie
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: !model.busy && model.reviews.isNotEmpty
                        ? displayReviews(model.reviews)
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
  final Review userReview;
  final GlobalKey<ScaffoldState> sKey;
  final Movie movie;
  final User currentUser;

  const ReviewForm(
      {Key key,
      @required this.userReview,
      this.sKey,
      this.movie,
      this.currentUser})
      : super(key: key);

  @override
  ReviewFormState createState() => ReviewFormState();
}

class ReviewFormState extends State<ReviewForm> {
  final reviewController = TextEditingController();
  final reviewFocusNode = FocusNode();
  var model = ReviewViewModel();
  final DialogService _dialogService = locator<DialogService>();
  num rate;
  bool _edit = false;
  bool upvoted;
  int upvoteCount;
  int downvoteCount;

  String timeAgo(String formattedString) {
    final timestamp = DateTime.parse(formattedString);
    final difference = DateTime.now().difference(timestamp);
    final timeAgo =
        DateTime.now().subtract(Duration(minutes: difference.inMinutes));
    return timeago.format(timeAgo, locale: 'en_short');
  }

  @override
  void initState() {
    reviewController.text = widget.userReview?.review ?? '';
    rate = widget.userReview?.rating ?? 0.00;
    upvoted = widget.userReview?.upvoted;
    upvoteCount = widget.userReview?.upvoteCount;
    downvoteCount = widget.userReview?.downvoteCount;
    super.initState();
  }

  Widget build(BuildContext context) {
    return _edit == false
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        // TO DO: Warning sign na need mag-sign in pag tinatry ng guest user magvote
                        onTap: widget.currentUser != null
                            ? () async {
                                // categories: insert, update, delete
                                if (upvoted == null) {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'insert',
                                      value: true,
                                      userId: widget.currentUser.userId);

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                } else if (upvoted == false) {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'update',
                                      value: true,
                                      userId: widget.currentUser.userId);

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                } else {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'delete',
                                      value: null,
                                      userId: widget.currentUser.userId);

                                  Timer(Duration(seconds: 1),
                                      () => print(res.upvoted ?? 'test'));

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                }
                              }
                            : null,
                        child: Image.network(
                          'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075331/images/up-arrow_aouhte.png',
                          height: 15,
                          width: 20,
                          color: upvoted == true
                              ? Colors.green
                              : Color.fromRGBO(192, 192, 192, 1),
                        ),
                      ),
                      Text((upvoteCount - downvoteCount).toString()),
                      GestureDetector(
                        onTap: widget.currentUser != null
                            ? () async {
                                // categories: insert, update, delete
                                if (upvoted == null) {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'insert',
                                      value: false,
                                      userId: widget.currentUser.userId);

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                } else if (upvoted == true) {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'update',
                                      value: false,
                                      userId: widget.currentUser.userId);

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                } else {
                                  var res = await model.vote(
                                      movieId: widget.movie.movieId,
                                      reviewId: widget.userReview.reviewId,
                                      type: 'delete',
                                      value: null,
                                      userId: widget.currentUser.userId);

                                  setState(() {
                                    upvoted = res.upvoted;
                                    upvoteCount = res.upvoteCount;
                                    downvoteCount = res.downvoteCount;
                                  });
                                }
                              }
                            : null,
                        child: Image.network(
                          'https://res.cloudinary.com/mubidibi-sp/image/upload/v1619075332/images/down-arrow_lb8dht.png',
                          height: 15,
                          color: upvoted == false
                              ? Colors.red
                              : Color.fromRGBO(192, 192, 192, 1),
                        ),
                      ),
                    ],
                  ),
                ),
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
                                    children: [
                                      // NOTE: putting text in a container and setting overflow to ellipsis fixes the overflow problem
                                      Container(
                                        width: 200,
                                        child: Text(
                                          widget.userReview.firstName +
                                              " " +
                                              (widget.userReview.middleName !=
                                                      null
                                                  ? widget.userReview
                                                          .middleName +
                                                      " " +
                                                      widget.userReview.lastName
                                                  : widget
                                                      .userReview.lastName) +
                                              (widget.userReview.suffix != null
                                                  ? " " +
                                                      widget.userReview.suffix
                                                  : ""),
                                          style: TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Container(
                                        child: Text(
                                          timeAgo(widget.userReview.addedAt) +
                                                  " ago" ??
                                              ' ',
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                          overflow: TextOverflow.clip,
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.zero,
                                    padding: EdgeInsets.zero,
                                    child: PopupMenuButton(
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem(
                                            child: Text('Edit'), value: 'edit'),
                                        PopupMenuItem(
                                            child: Text('Delete'),
                                            value: 'delete'),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          setState(() {
                                            _edit = true;
                                          });
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
                                                    id: widget.userReview
                                                            ?.reviewId
                                                            .toString() ??
                                                        '0');

                                            if (deleteRes != 0) {
                                              widget.sKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Your review has been deleted.',
                                                      Colors.green));

                                              Timer(
                                                  const Duration(
                                                      milliseconds: 2000), () {
                                                model.getAllReviews(
                                                    movieId: widget
                                                        .movie.movieId
                                                        .toString(),
                                                    accountId: widget
                                                        .currentUser.userId
                                                        .toString());

                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          MovieView(
                                                        movieId: widget
                                                            .movie.movieId
                                                            .toString(),
                                                      ),
                                                    ));
                                              });
                                            }
                                          }

                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: IgnorePointer(
                                ignoring: true,
                                child: widget.userReview.rating != 0.00
                                    ? RatingBar.builder(
                                        direction: Axis.horizontal,
                                        allowHalfRating: true,
                                        itemCount: 5,
                                        itemSize: 20,
                                        initialRating: rate,
                                        unratedColor:
                                            Color.fromRGBO(192, 192, 192, 1),
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
                                  horizontal: 20, vertical: 10),
                              child: Column(
                                children: [
                                  Text(
                                    widget.userReview.review,
                                    style: TextStyle(fontSize: 14),
                                    // textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
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
                                  rate = rating;
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
                            onPressed: () async {
                              reviewFocusNode.unfocus();

                              // submit post and save into db
                              var model = ReviewViewModel();
                              final response = await model.addReview(
                                  reviewId: widget.userReview?.reviewId ?? "0",
                                  movieId: widget.movie.movieId.toString(),
                                  userId: widget.currentUser.userId.toString(),
                                  rating: rate.toString(),
                                  review: reviewController.text);

                              if (response != null) {
                                // show success snackbar
                                widget.sKey.currentState.showSnackBar(
                                    mySnackBar(
                                        context,
                                        'Your review has been posted.',
                                        Colors.green));

                                Timer(const Duration(milliseconds: 2000), () {
                                  // fetch reviews again
                                  model.getAllReviews(
                                      movieId: widget.movie.movieId.toString(),
                                      accountId:
                                          widget.currentUser.userId.toString());

                                  setState(() {
                                    _edit = false;
                                  });
                                  // Navigator.pop(context);
                                  // Navigator.pushReplacement(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //         builder: (BuildContext context) =>
                                  //             MovieView(
                                  //               movieId: movie.movieId.toString(),
                                  //             )));
                                });
                              } else {
                                widget.sKey.currentState.showSnackBar(mySnackBar(
                                    context,
                                    'Something went wrong. Please try again later.',
                                    Colors.red));
                              }
                            },
                            child: Text(
                              "POST",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      _edit == true
                          ? Container(
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
                                    onPressed: () {
                                      reviewFocusNode.unfocus();
                                      setState(() {
                                        _edit = false;
                                      });
                                    },
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                  )))
                          : SizedBox(),
                    ]),
                    SizedBox(height: 10),
                  ],
                )));
  }
}
