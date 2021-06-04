import 'package:flutter/material.dart';

// Box Decorations

BoxDecoration fieldDecortaion = BoxDecoration(
    borderRadius: BorderRadius.circular(5), color: Colors.grey[200]);

BoxDecoration disabledFieldDecortaion = BoxDecoration(
    borderRadius: BorderRadius.circular(5), color: Colors.grey[100]);

// Field Variables

const double fieldHeight = 55;
const double smallFieldHeight = 40;
const double inputFieldBottomMargin = 30;
const double inputFieldSmallBottomMargin = 0;
const EdgeInsets fieldPadding = const EdgeInsets.symmetric(horizontal: 15);
const EdgeInsets largeFieldPadding =
    const EdgeInsets.symmetric(horizontal: 15, vertical: 15);

// Text Variables
const TextStyle buttonTitleTextStyle =
    const TextStyle(fontWeight: FontWeight.w700, color: Colors.white);

// Snackbar
Widget mySnackBar(
  BuildContext context,
  String message,
  Color bgColor,
) {
  return SnackBar(
    content: Text(message,
        style:
            Theme.of(context).textTheme.subtitle1.apply(color: Colors.white)),
    backgroundColor: bgColor,
    duration: Duration(seconds: 2),
  );
}

class MyTooltip extends StatelessWidget {
  final Widget child;
  final String message;

  MyTooltip({@required this.message, @required this.child});

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<State<Tooltip>>();
    return Tooltip(
      margin: EdgeInsets.all(10),
      key: key,
      message: message,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(key),
        child: child,
      ),
    );
  }

  void _onTap(GlobalKey key) {
    final dynamic tooltip = key.currentState;
    tooltip?.ensureTooltipVisible();
  }
}

Color trackColor(num rating) {
  if (rating >= 1 && rating <= 2) {
    // 1-2
    return Colors.red[400];
  } else if (rating > 2 && rating <= 3.5) {
    // 2.5 - 3.5
    return Colors.orange[400];
  } else if (rating == null) {
    return Colors.grey[400];
  } else {
    return Colors.yellow[400];
  }
}

Color sliderColor(num rating) {
  if (rating >= 1 && rating <= 2) {
    // 1-2
    return Colors.red[100];
  } else if (rating > 2 && rating <= 3.5) {
    // 2.5 - 3.5
    return Colors.orange[100];
  } else if (rating == null) {
    return Colors.grey[100];
  } else {
    return Colors.yellow[100];
  }
}
