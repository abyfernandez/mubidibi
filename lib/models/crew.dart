import 'dart:convert';

List<Crew> crewFromJson(String str) =>
    List<Crew>.from(json.decode(str).map((x) => Crew.fromJson(x)));

String crewToJson(List<Crew> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Crew {
  final int crewId;
  final String firstName;
  final String middleName;
  final String lastName;

  Crew({
    this.crewId,
    this.firstName,
    this.middleName,
    this.lastName,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      crewId: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": crewId,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
      };
}
