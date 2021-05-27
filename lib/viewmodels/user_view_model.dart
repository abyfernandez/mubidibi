import 'base_model.dart';
import 'package:mubidibi/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:mubidibi/globals.dart' as Config;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserViewModel extends BaseModel {
  // Function: GET USERS
  Future<List<User>> getUsers({@required userId}) async {
    setBusy(true);

    var response = await http.post(
      Config.api + 'users/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return userFromJson(response.body);
    } else {
      throw Exception('Failed to get users');
    }
  }

  // Function: update admins
  Future<bool> updateAdmins({@required users, @required changed}) async {
    setBusy(true);

    var response = await http.post(
      Config.api + 'update-admins/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'users': users,
        'changed': changed,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
