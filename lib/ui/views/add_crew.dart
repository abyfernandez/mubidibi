// FORM VIEW: CREW (DIRECTORS, WRITERS, ACTORS)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/crew.dart';
import 'package:mubidibi/models/movie.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/ui/views/movie_view.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/viewmodels/movie_view_model.dart';
import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:mubidibi/ui/shared/list_items.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';

class AddCrew extends StatefulWidget {
  final Crew crew;

  AddCrew({Key key, this.crew}) : super(key: key);

  @override
  _AddCrewState createState() => _AddCrewState(crew);
}

// ADD MOVIE FIRST PAGE
class _AddCrewState extends State<AddCrew> {
  final Crew crew;

  _AddCrewState(this.crew);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Add Crew"),
      ),
    );
  }
}
