import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/review.dart';
import 'package:mubidibi/models/user.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/viewmodels/review_view_model.dart';
import '../../locator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mubidibi/ui/shared/popup_menu.dart';

// CLASS REVIEW FORM
class ReviewForm extends StatefulWidget {
  final Function computeOverallRating;
  final GlobalKey<ScaffoldState> sKey;
  final Movie movie;
  final User currentUser;

  const ReviewForm({
    Key key,
    this.computeOverallRating,
    this.sKey,
    this.movie,
    this.currentUser,
  }) : super(key: key);

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
  num rate = 5.00;
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
    return timeago.format(timeAgo, locale: 'en');
  }

  void fetchUserReview() async {
    var model = ReviewViewModel();

    var reviews = await model.getAllReviews(
        movieId: widget.movie.movieId.toString(),
        accountId: widget.currentUser.userId);

    setState(() {
      userReview = model.userReview;
      reviewController.text = userReview?.review ?? '';
      rate = userReview?.rating ?? 5.00;
      upvoted = userReview?.upvoted ?? null;
      upvoteCount = userReview?.upvoteCount ?? 0;
      downvoteCount = userReview?.downvoteCount ?? 0;
      isApproved = userReview?.isApproved ?? false;
      _edit = userReview != null ? false : true;
    });
  }

  @override
  void initState() {
    fetchUserReview();
    super.initState();
  }

  final GlobalKey<FormState> _reviewFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return _edit == false && userReview != null
        ?
        // display currentUser's review
        widget.currentUser.isAdmin == true || isApproved == true
            ? Column(
                children: [
                  // SizedBox(height: 15),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Card(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // NOTE: putting text in a container and setting overflow to ellipsis fixes the overflow problem
                                      Container(
                                        padding: EdgeInsets.only(top: 10),
                                        width: 250,
                                        child: Text(
                                          userReview.firstName +
                                              (userReview.middleName != null
                                                  ? " " + userReview.middleName
                                                  : "") +
                                              (userReview.lastName != null
                                                  ? " " + userReview.lastName
                                                  : "") +
                                              (userReview.suffix != null
                                                  ? " " + userReview.suffix
                                                  : ""),
                                          style: TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),

                                      // Popup menu
                                      Container(
                                        padding: EdgeInsets.only(top: 10),
                                        margin: EdgeInsets.zero,
                                        child: TPopupMenuButton(
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (BuildContext context) =>
                                              [
                                            widget.currentUser != null &&
                                                    widget.currentUser
                                                            .isAdmin ==
                                                        true
                                                ? TPopupMenuItem(
                                                    child: Text(
                                                        isApproved == true
                                                            ? 'Hide'
                                                            : 'Approve'),
                                                    value: isApproved == true
                                                        ? 'hide'
                                                        : 'approve')
                                                : null,
                                            TPopupMenuItem(
                                                child: Text('Edit'),
                                                value: 'edit'),
                                            TPopupMenuItem(
                                                child: Text('Delete'),
                                                value: 'delete'),
                                          ],
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              setState(() {
                                                _edit = true;
                                              });
                                            } else if (value == "approve" ||
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
                                                  var reviews = model
                                                      .getAllReviews(
                                                          movieId: widget
                                                              .movie.movieId
                                                              .toString(),
                                                          accountId: widget
                                                              .currentUser
                                                              .userId);

                                                  widget.computeOverallRating(
                                                      widget.movie.movieId
                                                          .toString());
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
                                                        5.0;
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
                                                      .showSnackBar(
                                                    mySnackBar(
                                                        context,
                                                        'This review has been deleted.',
                                                        Colors.green),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  // timeago and review
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.zero,
                                        padding: EdgeInsets.zero,
                                        child: Text(
                                          timeAgo(userReview.addedAt) != null
                                              ? timeAgo(userReview.addedAt)
                                              : ' ',
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 14),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Divider(
                                          color: Colors.black45, endIndent: 30),
                                      SizedBox(height: 20),
                                      Container(
                                        margin: EdgeInsets.only(right: 10),
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          children: [
                                            Text(
                                              userReview.review,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Divider(color: Colors.black45),
                                      Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 0, vertical: 5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              isApproved == true
                                                  ? Row(
                                                      children: [
                                                        GestureDetector(
                                                          // TO DO: Warning sign na need mag-sign in pag tinatry ng guest user magvote -- need improvement
                                                          onTap:
                                                              widget.currentUser !=
                                                                      null
                                                                  ? () async {
                                                                      // categories: insert, update, delete
                                                                      if (upvoted ==
                                                                          null) {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'insert',
                                                                            value:
                                                                                true,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      } else if (upvoted ==
                                                                          false) {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'update',
                                                                            value:
                                                                                true,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      } else {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'delete',
                                                                            value:
                                                                                null,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      }
                                                                    }
                                                                  : () {
                                                                      widget
                                                                          .sKey
                                                                          .currentState
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          duration:
                                                                              Duration(days: 1),
                                                                          backgroundColor:
                                                                              Colors.red,
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
                                                              upvoted == true
                                                                  ? Icons
                                                                      .thumb_up_alt
                                                                  : Icons
                                                                      .thumb_up_off_alt,
                                                              color: upvoted ==
                                                                      true
                                                                  ? Colors.green
                                                                  : Color
                                                                      .fromRGBO(
                                                                          192,
                                                                          192,
                                                                          192,
                                                                          1)),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                            upvoteCount
                                                                .toString(),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black)),
                                                        SizedBox(width: 10),
                                                        GestureDetector(
                                                          onTap:
                                                              widget.currentUser !=
                                                                      null
                                                                  ? () async {
                                                                      // categories: insert, update, delete
                                                                      if (upvoted ==
                                                                          null) {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'insert',
                                                                            value:
                                                                                false,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      } else if (upvoted ==
                                                                          true) {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'update',
                                                                            value:
                                                                                false,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      } else {
                                                                        var res = await model.vote(
                                                                            movieId: widget
                                                                                .movie.movieId,
                                                                            reviewId: userReview
                                                                                .reviewId,
                                                                            type:
                                                                                'delete',
                                                                            value:
                                                                                null,
                                                                            userId:
                                                                                widget.currentUser.userId);

                                                                        var itemRes = res.singleWhere(
                                                                            (review) =>
                                                                                review.userId ==
                                                                                widget.currentUser.userId,
                                                                            orElse: () => null);

                                                                        setState(
                                                                            () {
                                                                          upvoted =
                                                                              itemRes?.upvoted ?? null;
                                                                          upvoteCount =
                                                                              itemRes?.upvoteCount ?? 0;
                                                                          downvoteCount =
                                                                              itemRes?.downvoteCount ?? 0;
                                                                        });
                                                                      }
                                                                    }
                                                                  : null,
                                                          child: Icon(
                                                              upvoted == false
                                                                  ? Icons
                                                                      .thumb_down_alt
                                                                  : Icons
                                                                      .thumb_down_off_alt,
                                                              color: upvoted ==
                                                                      false
                                                                  ? Colors.red
                                                                  : Color
                                                                      .fromRGBO(
                                                                          192,
                                                                          192,
                                                                          192,
                                                                          1)),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                            downvoteCount
                                                                .toString(),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black)),
                                                      ],
                                                    )
                                                  : SizedBox(),
                                              widget.currentUser != null &&
                                                      widget.currentUser
                                                          .isAdmin &&
                                                      isApproved == false
                                                  ? Container(
                                                      padding: EdgeInsets.only(
                                                          right: 10),
                                                      child: Text(
                                                        "Review hidden",
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                            fontStyle: FontStyle
                                                                .italic),
                                                      ),
                                                    )
                                                  : SizedBox(),
                                            ],
                                          )),
                                    ],
                                  )),
                              SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 35,
                        right: 30,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(70),
                              color: trackColor(rate)),
                          child: SleekCircularSlider(
                            min: 1,
                            max: 5,
                            initialValue: rate,
                            appearance: CircularSliderAppearance(
                              animationEnabled: false,
                              size: 70,
                              startAngle: 270,
                              angleRange: 350,
                              infoProperties: InfoProperties(
                                modifier: (double value) {
                                  final display =
                                      rate % 1 != 0 ? rate : rate.toInt();
                                  return display.toString();
                                },
                                mainLabelStyle: TextStyle(fontSize: 18),
                              ),
                              customWidths: CustomSliderWidths(
                                trackWidth: 8,
                                shadowWidth: 3,
                                progressBarWidth: 10,
                                handlerSize: 3,
                              ),
                              customColors: CustomSliderColors(
                                hideShadow: true,
                                trackColor: trackColor(rate),
                                progressBarColor: sliderColor(rate),
                                dotColor: sliderColor(rate),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              )
            : SizedBox()
        // write a review (ver.2)
        : Form(
            key: _reviewFormKey,
            child: Stack(
              children: [
                SizedBox(height: 10),
                ListTile(
                    tileColor: Colors.white,
                    title: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text("Your Review"),
                          Row(
                            children: [
                              SizedBox(height: 40),
                              Expanded(
                                child: Divider(
                                  color: Colors.black45,
                                  endIndent: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    subtitle: Column(
                      children: [
                        SizedBox(height: 25),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: TextFormField(
                            controller: reviewController,
                            focusNode: reviewFocusNode,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                            maxLines: null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromRGBO(240, 240, 240, 1),
                              labelText: "Review *",
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
                        Row(children: [
                          Container(
                            padding: EdgeInsets.only(left: 10),
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

                                          if (_reviewFormKey.currentState
                                              .validate()) {
                                            // submit post and save into db
                                            var model = ReviewViewModel();
                                            final response = await model
                                                .addReview(
                                                    reviewId: userReview
                                                            ?.reviewId ??
                                                        0,
                                                    movieId: widget
                                                        .movie.movieId
                                                        .toString(),
                                                    userId:
                                                        widget
                                                            .currentUser.userId
                                                            .toString(),
                                                    rating: rate.toString(),
                                                    review:
                                                        reviewController.text);

                                            if (response != null) {
                                              // fetch reviews again
                                              var newReview =
                                                  await model.getReview(
                                                      accountId: widget
                                                          .currentUser.userId,
                                                      movieId:
                                                          widget.movie.movieId);

                                              if (newReview != null) {
                                                setState(() {
                                                  userReview = newReview;
                                                  submitting = false;
                                                  _edit = false;
                                                  isApproved = false;
                                                });

                                                // show success snackbar
                                                widget.sKey.currentState
                                                    .showSnackBar(mySnackBar(
                                                        context,
                                                        'Your review is pending for approval.',
                                                        Colors.orange));
                                              } else {
                                                // show error snackbar
                                                widget.sKey.currentState
                                                    .showSnackBar(mySnackBar(
                                                        context,
                                                        'Something went wrong. Please try again later.',
                                                        Colors.red));
                                              }
                                            } else {
                                              widget.sKey.currentState
                                                  .showSnackBar(mySnackBar(
                                                      context,
                                                      'Something went wrong. Please try again later.',
                                                      Colors.red));
                                            }
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
                                        rate = userReview?.rating ?? 5.0;
                                        upvoted = userReview?.upvoted ?? null;
                                        upvoteCount =
                                            userReview?.upvoteCount ?? 0;
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
                        SizedBox(height: 15),
                      ],
                    )),
                Positioned(
                  right: 30,
                  top: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      color: trackColor(rate),
                    ),
                    child: SleekCircularSlider(
                      min: 1,
                      max: 5,
                      initialValue: rate,
                      appearance: CircularSliderAppearance(
                        size: 70,
                        startAngle: 270, // 270
                        angleRange: 350, // 355
                        infoProperties: InfoProperties(
                          modifier: (double value) {
                            final display = rate % 1 != 0 ? rate : rate.toInt();
                            return display.toString();
                          },
                          mainLabelStyle: TextStyle(fontSize: 18),
                        ),
                        customWidths: CustomSliderWidths(
                          trackWidth: 8,
                          shadowWidth: 3,
                          progressBarWidth: 10,
                          handlerSize: 3,
                        ),
                        customColors: CustomSliderColors(
                          trackColor: trackColor(rate),
                          progressBarColor: sliderColor(rate),
                          dotColor: sliderColor(rate),
                        ),
                      ),
                      onChange: (double value) {
                        final newValue = (value * 2).ceil() / 2;
                        setState(() {
                          rate = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
