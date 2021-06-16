import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType textInputType;
  final Function onTap;
  final String hintText;
  final bool password;
  final bool isReadOnly;
  final String placeholder;
  final String validationMessage;
  final Function enterPressed;
  final bool smallVersion;
  final FocusNode fieldFocusNode;
  final FocusNode nextFocusNode;
  final TextInputAction textInputAction;
  final String additionalNote;
  final Function(String) onChanged;
  final TextInputFormatter formatter;

  InputField(
      {@required this.controller,
      @required this.placeholder,
      this.hintText,
      this.onTap,
      this.enterPressed,
      this.fieldFocusNode,
      this.nextFocusNode,
      this.additionalNote,
      this.onChanged,
      this.formatter,
      this.validationMessage,
      this.textInputAction = TextInputAction.next,
      this.textInputType = TextInputType.text,
      this.password = false,
      this.isReadOnly = false,
      this.smallVersion = false});

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool isPassword;
  double fieldHeight = 55;

  @override
  void initState() {
    super.initState();
    isPassword = widget.password;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Colors.black,
                ),
                controller: widget.controller,
                keyboardType: widget.textInputType,
                focusNode: widget.fieldFocusNode,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                inputFormatters:
                    widget.formatter != null ? [widget.formatter] : null,
                onEditingComplete: () {
                  if (widget.enterPressed != null) {
                    FocusScope.of(context).requestFocus(FocusNode());
                    widget.enterPressed();
                  }
                },
                onFieldSubmitted: (value) {
                  if (widget.nextFocusNode != null) {
                    widget.nextFocusNode.requestFocus();
                  }
                },
                obscureText:
                    widget.placeholder == "Password *" ? isPassword : false,
                readOnly: widget.isReadOnly,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromRGBO(240, 240, 240, 1),
                  border: InputBorder.none,
                  labelText: widget.placeholder,
                  labelStyle: TextStyle(
                    color: Colors.black54,
                  ),
                  contentPadding: EdgeInsets.all(10),
                ),
                validator: (value) {
                  if (widget.placeholder == "Password *" &&
                      value != null &&
                      value.length < 6) {
                    return 'Anim na character o higit pa ang kailangan.';
                  }
                  if (value.isEmpty || value == null) {
                    return 'Required ang field na ito.';
                  }
                  return null;
                },
              ),
              Positioned(
                right: 10,
                child: GestureDetector(
                  onTap: () => setState(() {
                    isPassword = !isPassword;
                  }),
                  child: widget.password
                      ? Container(
                          height: 55,
                          width: 55,
                          alignment: Alignment.center,
                          child: Text(isPassword ? "SHOW" : "HIDE",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 15)))
                      : SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
