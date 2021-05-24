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

// CLASS DISPLAY REVIEWS

class DisplayReviews extends StatefulWidget {
  final Function computeOverallRating;
  final Movie movie;
  final User currentUser;
  final GlobalKey<ScaffoldState> sKey;
  final Function() notifyParent;

  const DisplayReviews(
      {Key key,
      this.computeOverallRating,
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
    return timeago.format(timeAgo, locale: 'en');
  }

  Color trackColor(num rate, int index) {
    if (rate >= 1 && rate <= 2) {
      // 1-2
      return Colors.red[400];
    } else if (rate > 2 && rate <= 3.5) {
      // 2.5 - 3.5
      return Colors.orange[400];
    } else {
      return Colors.yellow[400];
    }
  }

  Color sliderColor(num rate, int index) {
    if (rate >= 1 && rate <= 2) {
      // 1-2
      return Colors.red[100];
    } else if (rate > 2 && rate <= 3.5) {
      // 2.5 - 3.5
      return Colors.orange[100];
    } else {
      return Colors.yellow[100];
    }
  }

  void fetchReviews() async {
    var res = await model.getAllReviews(
        movieId: widget.movie.movieId.toString(),
        accountId:
            widget.currentUser != null ? widget.currentUser.userId : "0");

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
                SizedBox(height: 15),
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
                            SizedBox(height: 10),
                            ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // NOTE: putting text in a container and setting overflow to ellipsis fixes the overflow problem
                                    Container(
                                      padding: EdgeInsets.only(top: 10),
                                      width: 200,
                                      child: Text(
                                        review.firstName +
                                            (review.middleName != null
                                                ? " " + review.middleName : "") +
                                                 (review.lastName != null ? " " + review.lastName : "") +
                                            (review.suffix != null
                                                ? " " + review.suffix
                                                : ""),
                                        style: TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ),

                                    // Popup menu
                                    widget.currentUser != null &&
                                            (widget.currentUser.isAdmin ==
                                                    true ||
                                                widget.currentUser.isAdmin ==
                                                    false)
                                        ? Container(
                                            margin: EdgeInsets.zero,
                                            padding: EdgeInsets.zero,
                                            child: TPopupMenuButton(
                                              padding: EdgeInsets.zero,
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                widget.currentUser != null &&
                                                        widget.currentUser
                                                                .isAdmin ==
                                                            true
                                                    ? TPopupMenuItem(
                                                        child: Text(
                                                            isApproved[index] ==
                                                                    true
                                                                ? 'Hide'
                                                                : 'Approve'),
                                                        value:
                                                            isApproved[index] ==
                                                                    true
                                                                ? 'hide'
                                                                : 'approve')
                                                    : null,
                                                widget.currentUser != null &&
                                                        widget.currentUser
                                                                .isAdmin ==
                                                            true
                                                    ? TPopupMenuItem(
                                                        child: Text('Delete'),
                                                        value: 'delete')
                                                    : null,
                                              ],
                                              onSelected: (value) async {
                                                if (value == 'approve' ||
                                                    value == 'hide') {
                                                  var res = await model
                                                      .changeReviewStatus(
                                                          id: review.reviewId,
                                                          status: !isApproved[
                                                              index],
                                                          movieId: widget
                                                              .movie.movieId);

                                                  if (res == true ||
                                                      res == false) {
                                                    setState(() {
                                                      isApproved[index] = res;

                                                      var reviews =
                                                          model.getAllReviews(
                                                              movieId: widget
                                                                  .movie.movieId
                                                                  .toString(),
                                                              accountId: widget
                                                                  .currentUser
                                                                  .userId);

                                                      widget
                                                          .computeOverallRating(
                                                              widget
                                                                  .movie.movieId
                                                                  .toString());
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
                                                        .showSnackBar(mySnackBar(
                                                            context,
                                                            "Something went wrong.",
                                                            Colors.red));
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
                                                            id: review?.reviewId
                                                                    .toString() ??
                                                                '0');

                                                    if (deleteRes != 0) {
                                                      var res = model
                                                          .getAllReviews(
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
                                                              model.userReview
                                                                  .reviewId)
                                                          .toList();

                                                      setState(() {
                                                        userReviews = newItems;
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
                                          )
                                        : SizedBox()
                                  ],
                                ),

                                // timeago and review
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.zero,
                                      child: Text(
                                        timeAgo(review.addedAt) != null
                                            ? timeAgo(review.addedAt)
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
                                            review.review,
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
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
                                                                            0;
                                                                      });
                                                                    } else if (upvoted[
                                                                            index] ==
                                                                        false) {
                                                                      var res = await model.vote(
                                                                          movieId: widget
                                                                              .movie
                                                                              .movieId,
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
                                                                            0;
                                                                      });
                                                                    } else {
                                                                      var res = await model.vote(
                                                                          movieId: widget
                                                                              .movie
                                                                              .movieId,
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
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
                                                            upvoted[index] ==
                                                                    true
                                                                ? Icons
                                                                    .thumb_up_alt
                                                                : Icons
                                                                    .thumb_up_off_alt,
                                                            color: upvoted[
                                                                        index] ==
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
                                                          upvoteCount[index]
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
                                                                    if (upvoted[
                                                                            index] ==
                                                                        null) {
                                                                      var res = await model.vote(
                                                                          movieId: widget
                                                                              .movie
                                                                              .movieId,
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
                                                                            0;
                                                                      });
                                                                    } else if (upvoted[
                                                                            index] ==
                                                                        true) {
                                                                      var res = await model.vote(
                                                                          movieId: widget
                                                                              .movie
                                                                              .movieId,
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
                                                                            0;
                                                                      });
                                                                    } else {
                                                                      var res = await model.vote(
                                                                          movieId: widget
                                                                              .movie
                                                                              .movieId,
                                                                          reviewId: review
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
                                                                            index] = itemRes
                                                                                ?.upvoteCount ??
                                                                            0;
                                                                        downvoteCount[
                                                                            index] = itemRes
                                                                                ?.downvoteCount ??
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
                                                            upvoted[
                                                                        index] ==
                                                                    false
                                                                ? Icons
                                                                    .thumb_down_alt
                                                                : Icons
                                                                    .thumb_down_off_alt,
                                                            color: upvoted[
                                                                        index] ==
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
                                                          downvoteCount[index]
                                                              .toString(),
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black)),
                                                    ],
                                                  )
                                                : SizedBox(),
                                            widget.currentUser != null &&
                                                    widget
                                                        .currentUser.isAdmin &&
                                                    isApproved[index] == false
                                                ? Container(
                                                    padding: EdgeInsets.only(
                                                        right: 10),
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
                                )),
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
                          color: trackColor(review.rating, index),
                        ),
                        child: SleekCircularSlider(
                          min: 1,
                          max: 5,
                          initialValue: review.rating.toDouble(),
                          appearance: CircularSliderAppearance(
                            size: 70,
                            startAngle: 270,
                            angleRange: 355,
                            infoProperties: InfoProperties(
                              modifier: (double value) {
                                final display = review.rating % 1 != 0
                                    ? review.rating
                                    : review.rating.toInt();
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
                              trackColor: trackColor(review.rating, index),
                              progressBarColor:
                                  sliderColor(review.rating, index),
                              dotColor: sliderColor(review.rating, index),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            )
          : SizedBox();
    }).toList());
  }
}
