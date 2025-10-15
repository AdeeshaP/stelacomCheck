import 'package:stelacom_check/constants.dart';
import 'package:flutter/material.dart';
import '../../../responsive.dart';

class FlatToggleButton extends StatefulWidget {
  final String buttonText;
  final Function toggled;
  final String type;
  FlatToggleButton(
      {Key? key,
      required this.buttonText,
      required this.toggled,
      required this.type})
      : super(key: key);

  @override
  _FlatToggleButtonState createState() => new _FlatToggleButtonState();
}

class _FlatToggleButtonState extends State<FlatToggleButton> {
  var pressed = false; // This is the press variable

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          pressed = !pressed;
        });
        widget.toggled(!pressed, widget.type);
      },
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.orange[50]!,
          ),
        ]),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            widget.buttonText,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              fontWeight: FontWeight.bold,
              color: pressed ? Colors.grey[400] : numberColors,
            ),
          ),
        ),
        height: Responsive.isMobileSmall(context)
            ? 26
            : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 24
                : Responsive.isTabletPortrait(context)
                    ? 34
                    : 32,
        width: 75,
      ),
    );
  }
}
