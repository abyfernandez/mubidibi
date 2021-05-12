import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/views/login_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/views/search_view.dart';
import 'package:mubidibi/ui/views/see_all_view.dart';
import 'package:mubidibi/ui/views/signin_category_view.dart';
import 'package:mubidibi/ui/views/signup_view.dart';
import 'package:mubidibi/ui/views/startup_view.dart';
import 'package:mubidibi/ui/views/add_movie.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case StartUpViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: StartUpView(),
      );
    case SignInCategoryViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SignInCategoryView(),
      );
    case LoginViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: LoginView(),
      );
    case SignUpViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SignUpFirstPage(),
      );
    case DashboardViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: DashboardView(),
      );
    case HomeViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: HomeView(),
      );
    case MovieViewRoute:
      var movieId = settings.arguments as String;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: MovieView(movieId: movieId),
      );
    case AddMovieRoute:
      var movie = settings.arguments as Movie;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddMovie(movie: movie),
      );
    case AddCrewRoute:
      var crew = settings.arguments as Crew;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddCrew(crew: crew),
      );
    case CrewViewRoute:
      var crewId = settings.arguments as String;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: CrewView(crewId: crewId),
      );
    case SearchViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SearchView(),
      );
    case SeeAllViewRoute:
      var movies = settings.arguments as List<Movie>;
      var crew = settings.arguments as List<Crew>;
      var photos = settings.arguments as List<String>;
      var screenshots = settings.arguments as List<String>;
      var type = settings.arguments as String;

      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SeeAllView(
            movies: movies,
            crew: crew,
            photos: photos,
            screenshots: screenshots,
            type: type),
      );
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}

PageRoute _getPageRoute({String routeName, Widget viewToShow}) {
  return MaterialPageRoute(
      settings: RouteSettings(
        name: routeName,
      ),
      builder: (_) => viewToShow);
}
