import 'package:mubidibi/viewmodels/crew_view_model.dart';
import 'package:flutter/material.dart';
import 'package:mubidibi/models/crew.dart';

// FILM GENRES
const genres = [
  'Romance',
  'Comedy',
  'Drama',
  'Horror',
  'Documentary',
  'Romantic-comedy'
];

final Map<int, String> _genre = {
  0: "Romance",
  1: "Comedy",
  2: "Drama",
  3: "Horror",
  4: "Documentary",
  5: "BL",
  6: "Romantic-comedy",
};

// FILM CREW
// var model = CrewViewModel();
// Future<dynamic> crewList = model.getAllCrew();

// final List<DropdownMenuItem> items =
//     genres.map<DropdownMenuItem<String>>((String value) {
//   return DropdownMenuItem<String>(
//     value: value,
//     child: Text(value),
//   );
// }).toList();

// Future<List<DropdownMenuItem>> getCrew() async {
//   final crewList = await model.getAllCrew();

//   final List<DropdownMenuItem> items =
//       await crewList.map<DropdownMenuItem<Crew>>((Crew value) {
//     return DropdownMenuItem<int>(
//       value: value.crewId,
//       child: Text('$value.firstName $value.middleName $value.lastName'),
//     );
//   }).toList();

//   return items;
// }
