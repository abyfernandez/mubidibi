import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/models/review.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/shared/audio_file.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/see_all_view.dart';
import 'package:mubidibi/ui/shared/video_file.dart';
import 'package:mubidibi/ui/widgets/content_scroll.dart';
import 'package:mubidibi/ui/widgets/full_photo_ver2.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/review_view_model.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import '../../locator.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:mubidibi/globals.dart' as Config;
import 'package:mubidibi/ui/views/review_form.dart';
import 'package:mubidibi/ui/views/display_reviews.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

class MovieView extends StatefulWidget {
  final int movieId;

  MovieView({this.movieId});

  @override
  _MovieViewState createState() => _MovieViewState(movieId);
}

class _MovieViewState extends State<MovieView>
    with SingleTickerProviderStateMixin {
  final int movieId;

  _MovieViewState(this.movieId);

  Movie movie;
  Future<List<List<Crew>>> crew;
  List<List<Crew>> crewEdit;
  List<Crew> movieCrewList; // edit movie
  List<Award> awards;
  List<Award> awardOpts; // edit movie
  Future<List<Review>> reviews;
  Animation<double> _animation;
  AnimationController _animationController;
  final NavigationService _navigationService = locator<NavigationService>();
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final DialogService _dialogService = locator<DialogService>();
  var currentUser;
  IconData fabIcon;
  int _gallerySlider = 0;
  int _audioSlider = 0;
  int _trailerSlider = 0;
  int _posterSlider = 0;

  // local variables
  bool _saving = false;
  ValueNotifier<double> rating = ValueNotifier<double>(0.0);
  ValueNotifier<bool> favorite = ValueNotifier<bool>(false);
  var tempRating = 0.0;
  var numItems = 0;
  bool willRebuild;
  final CarouselController _galleryController = CarouselController();
  final CarouselController _posterController = CarouselController();
  final CarouselController _trailerController = CarouselController();
  final CarouselController _audioController = CarouselController();

  // variables needed for adding reviews
  final reviewController = TextEditingController();

  // function for calling viewmodel's getCrewForDetails method
  Future<List<List<Crew>>> fetchCrew() async {
    var model = CrewViewModel();
    var crew = await model.getCrewForDetails(movieId: movieId);
    var temp = await model.getAllCrew(
        mode: "form"); // to be passed as parameter when edit movie is called

    setState(() {
      crewEdit = crew;
      movieCrewList = temp;
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

  // function for calling movie viewmodel's getOneMovie method
  Future fetchMovie() async {
    var model = MovieViewModel();
    var film = await model.getOneMovie(movieId: movieId);

    setState(() {
      movie = film;
      favorite.value = film.favoriteId != null ? true : false;
    });
  }

  // function for calling award viewmodel's getAwards method
  Future fetchAwards() async {
    var model = AwardViewModel();
    var temp = await model.getAwards(
        movieId: movieId,
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin");

    var tempAwards = await model.getAllAwards(
        user: currentUser != null && currentUser.isAdmin == true
            ? "admin"
            : "non-admin",
        mode: 'form',
        category: 'movie');

    setState(() {
      awards = temp;
      awardOpts = tempAwards;
    });
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

  Future<bool> onBackPress() async {
    Navigator.pop(context, [willRebuild, favorite.value, movie.movieId]);
    return Future.value(false);
  }

  @override
  void initState() {
    initializeDateFormatting();
    willRebuild = false;

    fetchMovie();
    crew = fetchCrew();
    fetchAwards();
    fabIcon = Icons.settings;
    tz.initializeTimeZones();

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

  FocusNode focusNode =
      new FocusNode(); // to close keyboard after posting review
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didUpdateWidget(MovieView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
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
                      builder: (context) => AddMovie(
                        movie: movie,
                        crewEdit: crewEdit,
                        movieCrewList: movieCrewList,
                        movieAwards: awards,
                        awardOpts: awardOpts,
                      ),
                    ),
                  );
                  setState(() {
                    fetchMovie();
                    crew = fetchCrew();
                    fetchAwards();
                  });

                  _animationController.reverse();
                  setState(() {
                    fabIcon = fabIcon == Icons.settings
                        ? Icons.close
                        : Icons.settings;
                  });
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
                        setState(() {
                          fabIcon = fabIcon == Icons.settings
                              ? Icons.close
                              : Icons.settings;
                        });

                        // if user is an admin, they can soft delete movies
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
                            _saving = false;

                            // show success snackbar
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'Movie deleted successfully.',
                                Colors.green));

                            _saving = true;

                            Timer(const Duration(milliseconds: 2000), () {
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         MovieView(movieId: movie.movieId),
                              //   ),
                              // );
                              fetchMovie();
                              crew = fetchCrew();
                              fetchAwards();
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
                                "Are you sure you want to restore this movie?");
                        if (response.confirmed == true) {
                          var model = MovieViewModel();

                          _saving = true;

                          var restoreRes = await model.restoreMovie(
                              id: movie.movieId.toString());
                          if (restoreRes != 0) {
                            _saving = false;

                            // show success snackbar
                            _scaffoldKey.currentState.showSnackBar(mySnackBar(
                                context,
                                'This movie is now restored.',
                                Colors.green));

                            Timer(const Duration(milliseconds: 2000), () {
                              // // redirect to homepage
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => MovieView(
                              //       movieId: movie.movieId,
                              //     ),
                              //   ),
                              // );
                              fetchMovie();
                              crew = fetchCrew();
                              fetchAwards();
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
          child: SafeArea(
            child: ModalProgressHUD(
              inAsyncCall: _saving,
              child: ListView(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      movie.posters.length > 1
                          ? CarouselSlider(
                              key: ValueKey('poster'),
                              carouselController: _posterController,
                              options: CarouselOptions(
                                enableInfiniteScroll: false,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _posterSlider = index;
                                  });
                                },
                                height: 400,
                                viewportFraction: 1.0,
                              ),
                              items: movie.posters.map((p) {
                                return Container(
                                  height: 400,
                                  decoration: new BoxDecoration(
                                    image: new DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          p?.url ?? Config.imgNotFound),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // blurred poster background
                                      new BackdropFilter(
                                        filter: new ImageFilter.blur(
                                            sigmaX: 7.0, sigmaY: 7.0),
                                        child: new Container(
                                          decoration: new BoxDecoration(
                                              color: Colors.black
                                                  .withOpacity(0.3)),
                                        ),
                                      ),
                                      // smaller poster in the center of the blurred poster background
                                      GestureDetector(
                                        child: Center(
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) =>
                                                Container(
                                              alignment: Alignment.center,
                                              width: 250,
                                              height: 350,
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black54,
                                                    offset: Offset(0.0, 0.0),
                                                    blurRadius: 0.0,
                                                  ),
                                                ],
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(5),
                                                child: Text(
                                                  movie.title +
                                                      (movie.releaseDate !=
                                                                  "" &&
                                                              movie.releaseDate !=
                                                                  null
                                                          ? (" (" +
                                                              DateFormat('y')
                                                                  .format(DateTime
                                                                      .parse(movie
                                                                          .releaseDate)) +
                                                              ") ")
                                                          : ""),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Material(
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 250,
                                                height: 350,
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black54,
                                                      offset: Offset(0.0, 0.0),
                                                      blurRadius: 0.0,
                                                    ),
                                                  ],
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text(
                                                    movie.title +
                                                        (movie.releaseDate !=
                                                                    "" &&
                                                                movie.releaseDate !=
                                                                    null
                                                            ? (" (" +
                                                                DateFormat('y')
                                                                    .format(DateTime
                                                                        .parse(movie
                                                                            .releaseDate)) +
                                                                ") ")
                                                            : ""),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            imageUrl:
                                                p?.url ?? Config.imgNotFound,
                                            width: 250,
                                            height: 350,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FullPhotoT(
                                                  url: p?.url ??
                                                      Config.imgNotFound,
                                                  description:
                                                      p?.description ?? '',
                                                  type: 'network'),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          : Container(
                              height: 400,
                              decoration: new BoxDecoration(
                                image: new DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      movie.posters != null &&
                                              movie.posters.length != 0
                                          ? movie.posters[0].url
                                          : Config.imgNotFound),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  new BackdropFilter(
                                    filter: new ImageFilter.blur(
                                        sigmaX: 7.0, sigmaY: 7.0),
                                    child: new Container(
                                      decoration: new BoxDecoration(
                                          color: Colors.black.withOpacity(0.3)),
                                    ),
                                  ),
                                  GestureDetector(
                                    child: Center(
                                      child: CachedNetworkImage(
                                        placeholder: (context, url) =>
                                            Container(
                                          alignment: Alignment.center,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          width: 250,
                                          height: 350,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black54,
                                                offset: Offset(0.0, 0.0),
                                                blurRadius: 0.0,
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(5),
                                            child: Text(
                                              movie.title +
                                                  (movie.releaseDate != "" &&
                                                          movie.releaseDate !=
                                                              null
                                                      ? (" (" +
                                                          DateFormat('y').format(
                                                              DateTime.parse(movie
                                                                  .releaseDate)) +
                                                          ") ")
                                                      : ""),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Material(
                                          child: Container(
                                            alignment: Alignment.center,
                                            width: 250,
                                            height: 350,
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black54,
                                                  offset: Offset(0.0, 0.0),
                                                  blurRadius: 0.0,
                                                ),
                                              ],
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.all(5),
                                              child: Text(
                                                movie.title +
                                                    (movie.releaseDate != "" &&
                                                            movie.releaseDate !=
                                                                null
                                                        ? (" (" +
                                                            DateFormat('y')
                                                                .format(DateTime
                                                                    .parse(movie
                                                                        .releaseDate)) +
                                                            ") ")
                                                        : ""),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        imageUrl: movie.posters != null &&
                                                movie.posters.length != 0
                                            ? movie.posters[0].url
                                            : Config.imgNotFound,
                                        width: 250,
                                        height: 350,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullPhotoT(
                                              url: movie.posters != null &&
                                                      movie.posters.length != 0
                                                  ? movie.posters[0].url
                                                  : Config.imgNotFound,
                                              description:
                                                  movie.posters[0].description,
                                              type: 'network'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                      movie.posters.length > 1
                          ? Positioned(
                              left: MediaQuery.of(context).size.width / 2,
                              bottom: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: movie.posters.map((p) {
                                  int index = movie.posters.indexOf(p);
                                  return GestureDetector(
                                    child: Container(
                                      width: 8.0,
                                      height: 8.0,
                                      margin: EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 2.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _posterSlider == index
                                            ? Color.fromRGBO(255, 255, 255, 0.9)
                                            : Color.fromRGBO(0, 0, 0, 0.9),
                                      ),
                                    ),
                                    onTap: () {
                                      _posterController.animateToPage(index);
                                      setState(() {
                                        _posterSlider = index;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            )
                          : SizedBox(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          IconButton(
                            padding: EdgeInsets.only(left: 30.0),
                            onPressed: () => Navigator.pop(context,
                                [willRebuild, favorite.value, movie.movieId]),
                            icon: Icon(Icons.arrow_back),
                            iconSize: 30.0,
                            color: Colors.white,
                          ),
                          // if user is an admin, replace button with a "DELETED" tag if movie is deleted, non if it isn't deleted.
                          // if user is not an admin, show "add to favorite" button instead.
                          currentUser != null && currentUser.isAdmin == true
                              ? movie.isDeleted == true
                                  ? MyTooltip(
                                      child: Container(
                                          child: Icon(
                                              Icons.error_outline_outlined,
                                              size: 30,
                                              color: Colors.red),
                                          padding: EdgeInsets.only(right: 20)),
                                      message:
                                          'This movie is currently hidden.')
                                  : ValueListenableBuilder(
                                      valueListenable: favorite,
                                      builder: (context, fav, widget) {
                                        return IconButton(
                                          padding: EdgeInsets.only(right: 20.0),
                                          onPressed: () {
                                            // add to favorites
                                            var model = MovieViewModel();
                                            model
                                                .updateFavorites(
                                                    movieId: movie.movieId,
                                                    type:
                                                        fav ? 'delete' : 'add')
                                                .then((value) => setState(() {
                                                      favorite.value =
                                                          value != 0
                                                              ? !fav
                                                              : fav;
                                                      rebuild.value = true;
                                                      willRebuild = true;
                                                    }));
                                          },
                                          icon: fav
                                              ? Icon(Icons.check)
                                              : Icon(Icons.add),
                                          iconSize: 30.0,
                                          color: Colors.white,
                                        );
                                      })
                              : currentUser != null
                                  ? ValueListenableBuilder(
                                      valueListenable: favorite,
                                      builder: (context, fav, widget) {
                                        return IconButton(
                                          padding: EdgeInsets.only(right: 20.0),
                                          onPressed: () {
                                            // add to favorites
                                            var model = MovieViewModel();
                                            model
                                                .updateFavorites(
                                                    movieId: movie.movieId,
                                                    type:
                                                        fav ? 'delete' : 'add')
                                                .then((value) => setState(() {
                                                      favorite.value =
                                                          value != 0
                                                              ? !fav
                                                              : fav;
                                                      rebuild.value = true;
                                                      willRebuild = true;
                                                    }));
                                          },
                                          icon: fav
                                              ? Icon(Icons.check)
                                              : Icon(Icons.add),
                                          iconSize: 30.0,
                                          color: Colors.white,
                                        );
                                      })
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
                            ? Wrap(
                                children: movie.genre.map((genre) {
                                  return GestureDetector(
                                      child: Container(
                                          child: Chip(
                                            labelPadding: EdgeInsets.only(
                                                left: 3, right: 3),
                                            backgroundColor: Colors.lightBlue,
                                            label: Text(
                                              genre,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          margin: EdgeInsets.only(right: 5)),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    SeeAllView(
                                                        type: "movies",
                                                        title: genre,
                                                        showFilter: true,
                                                        filter: genre)));
                                      });
                                }).toList(),
                              )
                            : SizedBox(),
                        ValueListenableBuilder(
                          valueListenable: rating,
                          builder: (context, value, widget) {
                            return value != 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          value != 0
                                              ? value % 1 != 0
                                                  ? value.toString()
                                                  : value.toInt().toString()
                                              : "",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.black,
                                          )),
                                      Text("/5",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ))
                                    ],
                                  )
                                : Text("No ratings yet",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic));
                          },
                        ),
                        SizedBox(height: 25),
                      ],
                    ),
                  ),
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
                                    ? DateFormat("MMM. d, y", "fil").format(
                                        TZDateTime.from(
                                            DateTime.parse(movie.releaseDate),
                                            tz.getLocation('Asia/Manila')))
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
                  SizedBox(height: 30),
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
                  SizedBox(height: 25),
                  crewEdit != null && crewEdit[0].length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: ContentScroll(
                            crewEdit: crewEdit,
                            crew: crewEdit != null
                                ? crewEdit[0]
                                    .map((director) => director)
                                    .toList()
                                : [],
                            title: 'Mga Direktor',
                            imageHeight: 130.0,
                            imageWidth: 110.0,
                          ),
                        )
                      : SizedBox(),
                  crewEdit != null && crewEdit[0].length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
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
                      : SizedBox(),
                  crewEdit != null && crewEdit[1].length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
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
                      : SizedBox(),
                  crewEdit != null && crewEdit[2].length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  // Mga Award
                  awards != null && awards.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Mga Award",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      : SizedBox(),
                  awards != null && awards.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: awards.map((award) {
                              return ListTile(
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Flexible(
                                      child: Text(
                                          award.name +
                                              (award.year != null
                                                  ? " (" + award.year + ") "
                                                  : ""),
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                          overflow: TextOverflow.clip),
                                    ),
                                  ],
                                ),
                                subtitle: award.type != null
                                    ? Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Text(
                                            award.type == "nominated"
                                                ? "Nominado"
                                                : "Panalo",
                                            style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 16),
                                            softWrap: true,
                                            overflow: TextOverflow.clip),
                                      )
                                    : SizedBox(),
                              );
                            }).toList(),
                          ),
                        )
                      : SizedBox(),
                  awards != null && awards.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  // Mga Sumikat na Linya
                  movie.quotes != null && movie.quotes.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Mga Sumikat na Linya",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      : SizedBox(),
                  movie.quotes != null && movie.quotes.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: movie.quotes.map((quote) {
                              return ListTile(
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    new Icon(Icons.fiber_manual_record,
                                        size: 16),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Flexible(
                                      child: Text("'" + quote.line + "'",
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                          overflow: TextOverflow.clip),
                                    ),
                                  ],
                                ),
                                subtitle: Container(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Text(quote.role,
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16),
                                      softWrap: true,
                                      overflow: TextOverflow.clip),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : SizedBox(),
                  movie.quotes != null && movie.quotes.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  // Trailers
                  movie.trailers != null && movie.trailers.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Trailers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      : SizedBox(),
                  movie.trailers != null && movie.trailers.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  movie.trailers != null && movie.trailers.length != 0
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              CarouselSlider(
                                key: ValueKey('trailers'),
                                options: CarouselOptions(
                                  enableInfiniteScroll: false,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _trailerSlider = index;
                                    });
                                  },
                                  enlargeCenterPage: false,
                                  height: 200,
                                  aspectRatio: 9 / 16,
                                  viewportFraction: 1,
                                ),
                                carouselController: _trailerController,
                                items: movie.trailers.map((p) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: Colors.transparent),
                                    padding:
                                        EdgeInsets.only(left: 20, right: 20),
                                    child: Stack(
                                      children: [
                                        Container(
                                          alignment: Alignment.topCenter,
                                          child: VideoFile(
                                            videoPlayerController:
                                                VideoPlayerController.network(
                                                    p.url),
                                            looping: false,
                                            autoplay: false,
                                            type: "simple",
                                            description: p.url,
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 10,
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: FlatButton(
                                              color: Color.fromRGBO(
                                                  240, 240, 240, 1),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline),
                                                  SizedBox(width: 5),
                                                  Text('Info')
                                                ],
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => VideoFile(
                                                        videoPlayerController:
                                                            VideoPlayerController
                                                                .network(p.url),
                                                        looping: false,
                                                        autoplay: false,
                                                        type: "detailed",
                                                        description:
                                                            p.description ??
                                                                ''),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Arrow Buttons
                                        Container(
                                          alignment: Alignment.center,
                                          margin: EdgeInsets.only(
                                              left: 15, right: 15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              _trailerSlider != 0
                                                  ? Stack(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    240,
                                                                    240,
                                                                    240,
                                                                    1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                          ),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              _trailerController
                                                                  .previousPage();
                                                              setState(() {
                                                                _trailerSlider -=
                                                                    1;
                                                              });
                                                            },
                                                            child: Icon(
                                                                Icons
                                                                    .navigate_before_outlined,
                                                                size: 30),
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  : Container(),
                                              _trailerSlider !=
                                                      movie.trailers.length - 1
                                                  ? Stack(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    240,
                                                                    240,
                                                                    240,
                                                                    1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                          ),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              _trailerController
                                                                  .nextPage();
                                                              setState(() {
                                                                _trailerSlider +=
                                                                    1;
                                                              });
                                                            },
                                                            child: Icon(
                                                                Icons
                                                                    .navigate_next_outlined,
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
                        )
                      : SizedBox(),
                  movie.trailers != null && movie.trailers.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  // Gallery
                  movie.gallery != null && movie.gallery.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Gallery",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      : SizedBox(),
                  movie.gallery != null && movie.gallery.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  movie.gallery != null && movie.gallery.length != 0
                      ? SingleChildScrollView(
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
                                items: movie.gallery.map((p) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: Colors.transparent),
                                    child: Stack(
                                      children: [
                                        p.url.contains('/image/upload/')
                                            ? Container(
                                                child: GestureDetector(
                                                  child: Center(
                                                    child: CachedNetworkImage(
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        child: Container(
                                                          alignment:
                                                              Alignment.center,
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(Theme.of(
                                                                        context)
                                                                    .accentColor),
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Material(
                                                        child: Image.network(
                                                          Config.imgNotFound,
                                                          width: 300,
                                                          height: 200,
                                                          fit: BoxFit
                                                              .contain, // .cover
                                                          alignment:
                                                              Alignment.center,
                                                        ),
                                                      ),
                                                      imageUrl: p?.url ??
                                                          Config.imgNotFound,
                                                      width: 300,
                                                      height: 200,
                                                      fit: BoxFit
                                                          .contain, // .cover
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            FullPhotoT(
                                                                url: p?.url ??
                                                                    Config
                                                                        .imgNotFound,
                                                                type: 'network',
                                                                description: p
                                                                    .description),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Container(
                                                alignment: Alignment.topCenter,
                                                child: VideoFile(
                                                    videoPlayerController:
                                                        VideoPlayerController
                                                            .network(p.url),
                                                    looping: false,
                                                    autoplay: false,
                                                    type: "simple"),
                                              ),
                                        // Arrow Buttons
                                        Container(
                                          alignment: Alignment.center,
                                          margin: EdgeInsets.only(
                                              left: 15, right: 15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              _gallerySlider != 0
                                                  ? Stack(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    240,
                                                                    240,
                                                                    240,
                                                                    1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                          ),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              _galleryController
                                                                  .previousPage();
                                                              setState(() {
                                                                _gallerySlider -=
                                                                    1;
                                                              });
                                                            },
                                                            child: Icon(
                                                                Icons
                                                                    .navigate_before_outlined,
                                                                size: 30),
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  : Container(),
                                              _gallerySlider !=
                                                      movie.gallery.length - 1
                                                  ? Stack(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    240,
                                                                    240,
                                                                    240,
                                                                    1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                          ),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              _galleryController
                                                                  .nextPage();
                                                              setState(() {
                                                                _gallerySlider +=
                                                                    1;
                                                              });
                                                            },
                                                            child: Icon(
                                                                Icons
                                                                    .navigate_next_outlined,
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
                        )
                      : SizedBox(),
                  movie.gallery != null && movie.gallery.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  // Audios
                  movie.audios != null && movie.audios.length != 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Audios",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      : SizedBox(),
                  movie.audios != null && movie.audios.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  movie.audios != null && movie.audios.length != 0
                      ? Container(
                          color: Colors.transparent,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                CarouselSlider(
                                  key: ValueKey('audios'),
                                  options: CarouselOptions(
                                    enableInfiniteScroll: false,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _audioSlider = index;
                                      });
                                    },
                                    enlargeCenterPage: false,
                                    height: 200,
                                    aspectRatio: 16 / 9,
                                    viewportFraction: 1,
                                  ),
                                  carouselController: _audioController,
                                  items: movie.audios.map((p) {
                                    return Container(
                                      decoration: BoxDecoration(
                                          color: Colors.transparent),
                                      padding:
                                          EdgeInsets.only(left: 20, right: 20),
                                      child: Stack(
                                        children: [
                                          Container(
                                            color: Colors.white,
                                          ),
                                          Center(
                                              child: Icon(
                                                  Icons.music_note_sharp,
                                                  size: 30,
                                                  color: Colors.black87)),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: AudioFile(
                                                videoPlayerController:
                                                    VideoPlayerController
                                                        .network(p.url),
                                                looping: false,
                                                autoplay: false,
                                                type: 'simple'),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 10,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: FlatButton(
                                                color: Color.fromRGBO(
                                                    240, 240, 240, 1),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline),
                                                    SizedBox(width: 5),
                                                    Text('Info')
                                                  ],
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => AudioFile(
                                                          videoPlayerController:
                                                              VideoPlayerController
                                                                  .network(
                                                                      p.url),
                                                          looping: false,
                                                          autoplay: false,
                                                          type: "detailed",
                                                          description:
                                                              p.description ??
                                                                  ''),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          // Arrow Buttons
                                          Container(
                                            alignment: Alignment.center,
                                            margin: EdgeInsets.only(
                                                left: 15, right: 15),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                _audioSlider != 0
                                                    ? Stack(
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      240,
                                                                      240,
                                                                      240,
                                                                      1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                            ),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                _audioController
                                                                    .previousPage();
                                                                setState(() {
                                                                  _audioSlider -=
                                                                      1;
                                                                });
                                                              },
                                                              child: Icon(
                                                                  Icons
                                                                      .navigate_before_outlined,
                                                                  size: 30),
                                                            ),
                                                          )
                                                        ],
                                                      )
                                                    : Container(),
                                                _audioSlider !=
                                                        movie.audios.length - 1
                                                    ? Stack(
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      240,
                                                                      240,
                                                                      240,
                                                                      1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                            ),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                _audioController
                                                                    .nextPage();
                                                                setState(() {
                                                                  _audioSlider +=
                                                                      1;
                                                                });
                                                              },
                                                              child: Icon(
                                                                  Icons
                                                                      .navigate_next_outlined,
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
                          ),
                        )
                      : SizedBox(),
                  movie.audios != null && movie.audios.length != 0
                      ? SizedBox(height: 25)
                      : SizedBox(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text("Mga Review",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
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
                              SizedBox(height: 25),
                              ReviewForm(
                                computeOverallRating: computeOverallRating,
                                sKey: _scaffoldKey,
                                movie: movie,
                                currentUser: currentUser,
                              )
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
                            )
                          : SizedBox()),
                  SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
