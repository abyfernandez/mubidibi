import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/views/configure_admin_view.dart';
import 'package:mubidibi/ui/views/crew_view.dart';
import 'package:mubidibi/ui/views/dashboard_view.dart';
import 'package:mubidibi/ui/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/views/list_all_view.dart';
import 'package:mubidibi/ui/views/login_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:mubidibi/ui/views/search_view.dart';
import 'package:mubidibi/ui/views/see_all_view.dart';
import 'package:mubidibi/ui/views/signin_category_view.dart';
import 'package:mubidibi/ui/views/signup_view.dart';
import 'package:mubidibi/ui/views/startup_view.dart';
import 'package:mubidibi/ui/views/add_movie.dart';
import 'package:mubidibi/ui/views/add_award.dart';

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
      var filter = settings.arguments as String;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: DashboardView(filter: filter),
      );
    case HomeViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: HomeView(),
      );
    case MovieViewRoute:
      var movieId = settings.arguments as int;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: MovieView(movieId: movieId),
      );
    case AddMovieRoute:
      var movie = settings.arguments as Movie;
      var crewEdit = settings.arguments as List<List<Crew>>;
      var movieCrewList = settings.arguments as List<Crew>;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddMovie(
          movie: movie,
          crewEdit: crewEdit,
          movieCrewList: movieCrewList,
        ),
      );
    case AddAwardRoute:
      var award = settings.arguments as Award;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddAward(award: award),
      );
    case AddCrewRoute:
      var crew = settings.arguments as Crew;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddCrew(crew: crew),
      );
    case CrewViewRoute:
      var crewId = settings.arguments as int;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: CrewView(crewId: crewId),
      );
    case SearchViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SearchView(),
      );
    case ConfigureAdminViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: ConfigureAdminView(),
      );
    case SeeAllViewRoute:
      var movies = settings.arguments as List<Movie>;
      var favorites = settings.arguments as List<Movie>;
      var crew = settings.arguments as List<Crew>;
      var type = settings.arguments as String;
      var filter = settings.arguments as String;
      var title = settings.arguments as String;

      return _getPageRoute(
        routeName: settings.name,
        viewToShow: SeeAllView(
          movies: movies,
          favorites: favorites,
          crew: crew,
          type: type,
          filter: filter,
          title: title,
        ),
      );
    case ListAllViewRoute:
      var items = settings.arguments as List;
      var type = settings.arguments as String;
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: ListAllView(
          items: items,
          type: type,
        ),
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
