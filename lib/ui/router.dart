import 'package:mubidibi/ui/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/constants/route_names.dart';
import 'package:mubidibi/ui/views/login_view.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
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
    case HomeViewRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: HomeView(),
      );
    case TempMovieRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: MovieView(),
      );
    case AddMovieRoute:
      return _getPageRoute(
        routeName: settings.name,
        viewToShow: AddMovie(),
      );
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ));
  }
}

PageRoute _getPageRoute({String routeName, Widget viewToShow}) {
  return MaterialPageRoute(
      settings: RouteSettings(
        name: routeName,
      ),
      builder: (_) => viewToShow);
}
