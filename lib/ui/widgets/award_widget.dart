import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/ui/widgets/input_chips.dart';

// Dynamic AwardWidget (Adding Awards)

class AwardWidget extends StatefulWidget {
  final List<Award> awardOptions;
  final Award item;
  final open;

  const AwardWidget({
    Key key,
    this.awardOptions,
    this.item,
    this.open,
  }) : super(key: key);

  @override
  AwardWidgetState createState() => AwardWidgetState();
}

class AwardWidgetState extends State<AwardWidget> {
  bool showError;
  // FocusNodes
  final typeNode = FocusNode();
  final yearNode = FocusNode();
  List<Award> awardId = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    showError = widget.item.awardId != null &&
            widget.item.type != null &&
            widget.item.type.trim() != ""
        ? false
        : true;

    widget.item.saved = widget.item.saved == null && widget.item.movieId == null
        ? false
        : widget.item.saved == null && widget.item.movieId != null
            ? true
            : false;

    if (widget.item.awardId != null) {
      // var award = widget.awardOptions
      //     .singleWhere((a) => a.awardId == widget.item.awardId);

      // if (award != null) awardId = [award];
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
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(240, 240, 240, 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ChipsInput(
                    initialValue: awardId,
                    maxChips: 1,
                    keyboardAppearance: Brightness.dark,
                    textCapitalization: TextCapitalization.words,
                    enabled: true,
                    textStyle:
                        const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Pumili ng Award *',
                      contentPadding: EdgeInsets.all(10),
                    ),
                    findSuggestions: (String query) {
                      if (query.isNotEmpty) {
                        var lowercaseQuery = query.toLowerCase();
                        return widget.awardOptions.where((item) {
                          return !awardId
                                  .map((d) => d.awardId)
                                  .toList()
                                  .contains(item.awardId) &&
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
                          widget.item.awardId = newList[0].id;
                          widget.item.name = newList[0].name;
                          widget.item.description = newList[0].description;
                          showError = widget.item.awardId != null &&
                                  (widget.item.type != null &&
                                      widget.item.type.trim() != "")
                              ? false
                              : true;
                          awardId = [newList[0]];
                        });
                      } else {
                        setState(() {
                          widget.item.awardId = null;
                          widget.item.name = null;
                          widget.item.description = null;
                          showError = widget.item.awardId != null &&
                                  (widget.item.type != null &&
                                      widget.item.type.trim() != "")
                              ? false
                              : true;
                          widget.item.saved = widget.item.awardId != null &&
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
                        label: Text(c != null ? c.name : ""),
                        onDeleted: () => {
                          state.deleteChip(c),
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                    suggestionBuilder: (context, state, c) {
                      return ListTile(
                        key: ObjectKey(c),
                        title: Text(c.name),
                        onTap: () => {state.selectSuggestion(c)},
                      );
                    },
                  ),
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
                            labelText: "Taon",
                            contentPadding: EdgeInsets.all(10),
                            filled: true,
                            fillColor: Color.fromRGBO(240, 240, 240, 1),
                          ),
                          validator: (value) {
                            // TO DO: accept only when it matches the range : e.g. 1900 - current year
                            var date = DateFormat("y").format(DateTime.now());
                            if ((value.length < 4 && value.length > 0) ||
                                (value.length > 4 ||
                                    int.parse(value) > int.parse(date))) {
                              return 'Mag-enter ng tamang taon.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.black54)),
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
                                child: Text("Nominado"), value: "nominated"),
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
                              print(widget.item.awardId);
                              print(widget.item.type);
                              showError = widget.item.awardId != null &&
                                      (widget.item.type != null &&
                                          widget.item.type.trim() != "")
                                  ? false
                                  : true;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                showError == true
                    ? Container(
                        alignment: Alignment.centerLeft,
                        child: Text('Required ang field ng Award at Type.',
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
                      if (_formKey.currentState.validate() &&
                          widget.item.awardId != null &&
                          (widget.item.type != null &&
                              widget.item.type.trim() != '')) {
                        setState(() {
                          widget.open.value = false;
                          widget.item.saved = true;
                        });
                      } else {
                        setState(() {
                          widget.item.saved = false;
                          showError = true;
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
