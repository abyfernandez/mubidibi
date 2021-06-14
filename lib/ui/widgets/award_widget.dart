import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/ui/views/add_crew.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';
import 'package:mubidibi/ui/views/add_movie.dart';

// Dynamic AwardWidget (Adding Awards)

class AwardWidget extends StatefulWidget {
  final List<Award> awardOptions;
  final Award item;
  final open;
  final ValueNotifier<int> prevId;
  final type;

  const AwardWidget({
    Key key,
    this.awardOptions,
    this.item,
    this.open,
    this.prevId,
    this.type,
  }) : super(key: key);

  @override
  AwardWidgetState createState() => AwardWidgetState();
}

class AwardWidgetState extends State<AwardWidget> {
  // FocusNodes
  final typeNode = FocusNode();
  final yearNode = FocusNode();
  List<Award> awardId = [];

  bool showErrorVar = false; // for type dropdown button
  bool showError = false; // for inputchip

  final _formKey = GlobalKey<FormState>();

  bool showTypeError() {
    return showErrorVar == false
        ? false
        : widget.item.type == null || widget.item.type.isEmpty
            ? true
            : false;
  }

  bool showChipError() {
    return showError == false
        ? false
        : widget.item.id == null
            ? true
            : false;
  }

  @override
  void initState() {
    widget.item.saved = widget.item.saved == null && widget.item.awardId == null
        ? false
        : widget.item.saved == null && widget.item.awardId != null
            ? true
            : false;

    if (widget.item.awardId != null) {
      awardId = [widget.item];
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
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(240, 240, 240, 1),
                          borderRadius: BorderRadius.circular(5)),
                      child: Container(
                        decoration: BoxDecoration(
                          border: showChipError()
                              ? Border(
                                  bottom: BorderSide(color: Colors.red[600]),
                                )
                              : null,
                        ),
                        child: ChipsInput(
                          initialValue: awardId,
                          maxChips: 1,
                          keyboardAppearance: Brightness.dark,
                          textCapitalization: TextCapitalization.words,
                          enabled: true,
                          textStyle: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'Pumili ng Award *',
                            contentPadding: EdgeInsets.all(10),
                          ),
                          findSuggestions: (String query) {
                            var filteredList = [];
                            if (widget.type == "movie") {
                              filteredList = awardsFilter.length != 0
                                  ? widget.awardOptions
                                      .where(
                                          (r) => !awardsFilter.contains(r.id))
                                      .toList()
                                  : widget.awardOptions;
                            } else if (widget.type == "crew") {
                              filteredList = crewAwardsFilter.length != 0
                                  ? widget.awardOptions
                                      .where((r) =>
                                          !crewAwardsFilter.contains(r.id))
                                      .toList()
                                  : widget.awardOptions;
                            }

                            if (query.isNotEmpty) {
                              var lowercaseQuery = query.toLowerCase();
                              return filteredList.where((item) {
                                return !awardId
                                        .map((d) => d.id)
                                        .toList()
                                        .contains(item.id) &&
                                    item.name
                                        .toLowerCase()
                                        .contains(query.toLowerCase());
                              }).toList(growable: false)
                                ..sort((a, b) => a.name
                                    .toLowerCase()
                                    .indexOf(lowercaseQuery)
                                    .compareTo(b.name
                                        .toLowerCase()
                                        .indexOf(lowercaseQuery)));
                            }
                            return [];
                          },
                          onChanged: (data) {
                            var newList = List<Award>.from(data);
                            if (newList.length != 0) {
                              setState(() {
                                widget.item.id = newList[0].id;
                                widget.item.name = newList[0].name;
                                awardId = [newList[0]];
                                showError = false;

                                if (widget.type == "movie") {
                                  if (!awardsFilter.contains(newList[0].id)) {
                                    awardsFilter.add(newList[0].id);
                                  }
                                } else if (widget.type == "crew") {
                                  if (!crewAwardsFilter
                                      .contains(newList[0].id)) {
                                    crewAwardsFilter.add(newList[0].id);
                                  }
                                }
                              });
                            } else {
                              setState(() {
                                widget.item.id = null;
                                widget.item.name = null;
                                showError = true;
                                widget.item.saved = widget.item.id != null &&
                                        widget.item.type != null &&
                                        widget.item.type.isNotEmpty &&
                                        (widget.item.type != null &&
                                            widget.item.type.trim() != "") &&
                                        widget.item.saved == true
                                    ? true
                                    : false;
                                awardId = [];
                              });
                            }
                          },
                          chipBuilder: (context, state, c) {
                            return InputChip(
                              key: ObjectKey(c),
                              label: Text(c.name +
                                  (c.event != null &&
                                          c.event.isNotEmpty &&
                                          c.event.trim() != ""
                                      ? " (" + c.event + ")"
                                      : "")),
                              onDeleted: () {
                                setState(() {
                                  widget.type == "movie"
                                      ? awardsFilter.remove(c.id)
                                      : crewAwardsFilter.remove(c.id);
                                  widget.prevId.value = c.id;
                                });
                                return state.deleteChip(c);
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          },
                          suggestionBuilder: (context, state, c) {
                            return ListTile(
                              key: ObjectKey(c),
                              title: Text(c.name +
                                  (c.event != null &&
                                          c.event.isNotEmpty &&
                                          c.event.trim() != ""
                                      ? " (" + c.event + ")"
                                      : "")),
                              onTap: () {
                                if (widget.type == "movie") {
                                  if (!awardsFilter.contains(c.id)) {
                                    setState(() {
                                      awardsFilter.add(c.id);
                                    });
                                  }
                                } else if (widget.type == "crew") {
                                  if (!crewAwardsFilter.contains(c.id)) {
                                    setState(() {
                                      crewAwardsFilter.add(c.id);
                                    });
                                  }
                                }

                                return state.selectSuggestion(c);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    showChipError()
                        ? Container(
                            padding: EdgeInsets.only(left: 10, top: 10),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Required ang field na ito.',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.normal,
                                color: Colors.red[700],
                              ),
                            ),
                          )
                        : SizedBox()
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        child: TextFormField(
                          initialValue: widget.item.year,
                          focusNode: yearNode,
                          keyboardType: TextInputType.number,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          onFieldSubmitted: (val) {
                            typeNode.requestFocus();
                          },
                          onChanged: (val) {
                            setState(() {
                              widget.item.year = val;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "Taon *",
                            contentPadding: EdgeInsets.all(10),
                            filled: true,
                            fillColor: Color.fromRGBO(240, 240, 240, 1),
                          ),
                          validator: (value) {
                            var date = DateFormat("y").format(DateTime.now());
                            if (value == null ||
                                value.trim() == "" ||
                                (value.length < 4 && value.length > 0) ||
                                (value.length > 4 ||
                                    int.parse(value) > int.parse(date))) {
                              return 'Mali ang iyong input';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: !showTypeError()
                                        ? Colors.black38
                                        : Colors.red[600]),
                              ),
                              color: Color.fromRGBO(240, 240, 240, 1),
                            ),
                            child: DropdownButton(
                              autofocus: false,
                              focusNode: typeNode,
                              value: widget.item.type,
                              items: [
                                DropdownMenuItem(
                                    child: Text("Pumili ng isa",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true),
                                    value: ""),
                                DropdownMenuItem(
                                    child: Text("Nominado"),
                                    value: "nominated"),
                                DropdownMenuItem(
                                    child: Text("Panalo"), value: "panalo"),
                              ],
                              hint: Text('Type *'),
                              elevation: 0,
                              isDense: false,
                              underline: Container(),
                              onChanged: (val) {
                                setState(() {
                                  widget.item.type = val;
                                  showTypeError();
                                });
                              },
                            ),
                          ),
                          showTypeError()
                              ? Container(
                                  padding: EdgeInsets.only(left: 10, top: 10),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Required ang field na ito.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.normal,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  child: OutlineButton(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    color: Colors.white,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      if (_formKey.currentState.validate() &&
                          widget.item.id != null &&
                          (widget.item.type != null &&
                              widget.item.type.trim() != '')) {
                        setState(() {
                          widget.open.value = false;
                          widget.item.saved = true;
                        });
                      } else {
                        setState(() {
                          if (widget.item.id == null) showError = true;
                          if (widget.item.type == null ||
                              widget.item.type.trim() == '')
                            showErrorVar = true;
                          widget.item.saved = false;
                        });
                      }
                    },
                    child: Text('Save'),
                  ),
                  alignment: Alignment.center,
                ),
              ],
            ))
        : Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              contentPadding:
                  EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
              tileColor: Color.fromRGBO(240, 240, 240, 1),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
                    child: Text(
                        (widget.item.name != null ? widget.item.name : '') +
                            (widget.item.year != null
                                ? " (" + widget.item.year + ") "
                                : ''),
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.clip),
                  ),
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
              subtitle: Container(
                child: Text(
                  widget.item.type != null
                      ? widget.item.type == "nominated"
                          ? "Nominado"
                          : "Panalo"
                      : '[Walang ibang impormasyon]',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
  }
}
