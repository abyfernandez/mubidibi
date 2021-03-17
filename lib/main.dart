import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/ui/views/startup_view.dart';
import 'managers/dialog_manager.dart';
import 'ui/router.dart';
import 'locator.dart';

void main() {
  // Register all the models and services before the app starts
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mubidibi',
      builder: (context, child) => Navigator(
        key: locator<DialogService>().dialogNavigationKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => DialogManager(child: child)),
      ),
      navigatorKey: locator<NavigationService>().navigationKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 9, 202, 172),
        backgroundColor: Color.fromARGB(255, 26, 27, 30),
        textTheme:
            GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.apply()),

        // textTheme:
        // GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.apply(
        //       bodyColor: Colors.white,
        //     )),
      ),
      home: StartUpView(),
      onGenerateRoute: generateRoute,
    );
  }
}
