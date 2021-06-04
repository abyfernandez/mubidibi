// Line Class (iconic lines)

class Line {
  String line;
  String role;
  bool saved;

  Line({
    this.line,
    this.role,
    this.saved,
  });

  Map<String, dynamic> toJson() => {"line": line, "role": role};
}
