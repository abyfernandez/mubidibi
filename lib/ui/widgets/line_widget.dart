import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mubidibi/models/line.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/ui/views/add_movie.dart';

// Dynamic LineWidget (Adding Iconic Lines)

class LineWidget extends StatefulWidget {
  final Line item;
  final open;
  // final List<String> roles;

  const LineWidget({
    Key key,
    this.item,
    this.open,
    // this.roles,
  }) : super(key: key);

  @override
  LineWidgetState createState() => LineWidgetState();
}

class LineWidgetState extends State<LineWidget> {
  bool showError = true;
  bool showRoleError = false;
  List<String> tempRole = [];

  bool showRoleErrorT() {
    return widget.item.role != null &&
            rolesFilter.value.contains(widget.item.role) == false
        ? true
        : false;
  }

  // FocusNodes and Controllers
  FocusNode descriptionNode = new FocusNode();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    widget.item.saved = widget.item.saved == null ? false : widget.item.saved;
    // test --- using list of value notifiers
    if (widget.item.role != null) {
      var chosen =
          rolesFilter.value.singleWhere((a) => a.value == widget.item.role);

      if (chosen != null) tempRole = [chosen.value];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.open.value == true
        ? Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                ValueListenableBuilder(
                  valueListenable: rolesFilter,
                  builder: (context, value, wid) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(240, 240, 240, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ChipsInput(
                        initialValue: tempRole,
                        maxChips: 1,
                        keyboardAppearance: Brightness.dark,
                        textCapitalization: TextCapitalization.words,
                        enabled: true,
                        textStyle: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Pumili ng Role *',
                          contentPadding: EdgeInsets.all(10),
                        ),
                        findSuggestions: (String query) {
                          List<dynamic> tempList = value;

                          if (query.isNotEmpty) {
                            var lowercaseQuery = query.toLowerCase();

                            return tempList.where((item) {
                              return item
                                  .toLowerCase()
                                  .contains(query.toLowerCase());
                            }).toList(growable: false)
                              ..sort((a, b) => a
                                  .toLowerCase()
                                  .indexOf(lowercaseQuery)
                                  .compareTo(
                                      b.toLowerCase().indexOf(lowercaseQuery)));
                          }
                          return tempList;
                        },
                        onChanged: (data) {
                          if (data.length != 0) {
                            setState(() {
                              widget.item.role = data[0];
                              showError = widget.item.role != null &&
                                      widget.item.line != null
                                  ? false
                                  : true;
                              showRoleError = showRoleErrorT();
                              tempRole = [data[0]];
                            });
                          } else {
                            setState(() {
                              widget.item.role = null;
                              showError = widget.item.role != null &&
                                      widget.item.line != null
                                  ? false
                                  : true;
                              showRoleError = showRoleErrorT();

                              widget.item.saved = widget.item.role != null &&
                                      widget.item.saved == true
                                  ? true
                                  : false;
                              tempRole = [];
                            });
                          }
                        },
                        chipBuilder: (context, state, c) {
                          showError = widget.item.role != null &&
                                  widget.item.line != null
                              ? false
                              : true;
                          showRoleError = showRoleErrorT();

                          return InputChip(
                            key: ObjectKey(c),
                            label: Text(c != null ? c : ""),
                            backgroundColor:
                                showRoleErrorT() == true ? Colors.red : null,
                            onDeleted: () => {
                              state.deleteChip(c),
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        },
                        suggestionBuilder: (context, state, c) {
                          return ListTile(
                            key: ObjectKey(c),
                            title: Text(c),
                            onTap: () => {state.selectSuggestion(c)},
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: TextFormField(
                    focusNode: descriptionNode,
                    initialValue: widget.item.line,
                    textCapitalization: TextCapitalization.sentences,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: "Linya *",
                      contentPadding: EdgeInsets.all(10),
                      filled: true,
                      fillColor: Color.fromRGBO(240, 240, 240, 1),
                    ),
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (val) {
                      setState(() {
                        widget.item.line = val;
                        showError =
                            widget.item.role != null && widget.item.line != null
                                ? false
                                : true;
                        showRoleError = showRoleErrorT();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                (showError == false && showRoleErrorT() == true) ||
                        (showError == true && showRoleErrorT() == true)
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            'Pumili ng bagong role o i-update ang mga aktor sa Step 3',
                            style: TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic)))
                    : SizedBox(),
                showError == true && showRoleErrorT() == false
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text('Required ang mga field ng Role at Linya.',
                            style: TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic)))
                    : SizedBox(),
                showError == true ? SizedBox(height: 15) : SizedBox(),
                Container(
                  child: OutlineButton(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    color: Colors.white,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      if (widget.item.role != null &&
                          widget.item.line != null &&
                          rolesFilter.value.contains(widget.item.role) ==
                              true) {
                        setState(() {
                          widget.open.value = false;
                          widget.item.saved = true;
                        });
                      } else {
                        setState(() {
                          widget.item.saved = false;
                          showError = true;
                          showRoleError = showRoleErrorT();
                        });
                      }
                    },
                    child: Text('Save'),
                  ),
                  alignment: Alignment.center,
                ),
              ],
            ),
          )
        : Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.zero,
            color: Color.fromRGBO(240, 240, 240, 1),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      widget.item.role != null &&
                              rolesFilter.value.contains(widget.item.role) ==
                                  false
                          ? MyTooltip(
                              child: Icon(Icons.report_problem_outlined,
                                  color: Colors.red),
                              message:
                                  "Pumili ng bagong role o i-update ang mga aktor sa Step 3",
                            )
                          : SizedBox(),
                      widget.item.role != null &&
                              rolesFilter.value.contains(widget.item.role) ==
                                  false
                          ? SizedBox(width: 5)
                          : SizedBox(),
                      GestureDetector(
                        child: Icon(Icons.edit_outlined),
                        onTap: () {
                          setState(() {
                            widget.open.value = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text('"' + widget.item.line.trim() + '"'),
                  subtitle: Text("- " + widget.item.role),
                ),
              ],
            ),
          );
  }
}
