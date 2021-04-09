import 'package:flutter/material.dart';

class ChipsInput extends StatefulWidget {
  const ChipsInput({
    Key key,
    @required this.onChanged,
  }) : super(key: key);

  final ValueChanged<List<String>> onChanged;

  @override
  _ChipsInputState createState() => _ChipsInputState();
}

class _ChipsInputState extends State<ChipsInput> {
  final _textController = TextEditingController();
  final _roles = Set<String>();

  @override
  Widget build(BuildContext context) {
    var chipsChildren = _roles.map<Widget>((role) {
      return InputChip(
        backgroundColor: Color.fromRGBO(220, 220, 220, 1),
        deleteIconColor: Color.fromRGBO(150, 150, 150, 1),
        key: ObjectKey(role),
        label: Text(role),
        onDeleted: () => _onDeleteRole(role),
      );
    }).toList();

    chipsChildren.add(
      TextField(
        autofocus: true,
        controller: _textController,
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: _roles.length >= 1 ? "Magdagdag ng role" : "Role"),
        onSubmitted: (val) {
          if (val != '') {
            _textController.clear();
            setState(() {
              _roles.add(val);
            });
            widget.onChanged(_roles.toList(growable: false));
          }
        },
      ),
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
          child: Wrap(
            children: chipsChildren,
            spacing: 4.0,
            runSpacing: -8.0,
          ),
        ),
      ],
    );
  }

  void _onDeleteRole(String role) {
    setState(() => _roles.remove(role));
    widget.onChanged(_roles.toList(growable: false));
  }
}
