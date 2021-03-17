import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/ui/shared/list_items.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/models/movie.dart';

class MovieView extends StatefulWidget {
  MovieView({Key key}) : super(key: key);

  @override
  _MovieViewState createState() => _MovieViewState();
}

class _MovieViewState extends State<MovieView> {
  Future<Movie> futureMovie;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<MovieViewModel>.withConsumer(
      viewModel: MovieViewModel(),
      builder: (context, model, child) => Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: <Widget>[
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF73AEF5),
                        Color(0xFF61A4F1),
                        Color(0xFF478DE0),
                        Color(0xFF398AE5),
                      ],
                      stops: [0.1, 0.4, 0.7, 0.9],
                    ),
                  ),
                ),
                Container(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 120.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 30.0),

                        // SIGN IN BUTTON
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 25.0),
                          width: double.infinity,
                          child: RaisedButton(
                            elevation: 5.0,
                            onPressed: () {
                              // futureMovie = model.getAllMovies();
                            },
                            padding: EdgeInsets.all(15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            color: Colors.white,
                            child: Text(
                              'GET MOVIE',
                              style: TextStyle(
                                color: Color(0xFF527DAA),
                                letterSpacing: 1.5,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // TEST

                        Center(
                          child: FutureBuilder<Movie>(
                            future: futureMovie,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                print("has data");
                                return Text(snapshot.data.synopsis);
                              } else if (snapshot.hasError) {
                                return Text("${snapshot.error}");
                              }

                              // By default, show a loading spinner.
                              return CircularProgressIndicator();
                            },
                          ),
                        ),

                        // END OF TEST
                      ],
                    ),
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
