import 'package:stelacom_check/constants.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/responsive.dart';

showProgressDialog(BuildContext context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: <Widget>[
        CircularProgressIndicator(
          color: screenHeadingColor,
        ),
        SizedBox(
          width: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 1
              : 10,
        ),
        Container(
          margin: EdgeInsets.only(left: 5),
          child: Text(
            "Loading",
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 15
                  : Responsive.isTabletPortrait(context)
                      ? 24
                      : 20,
            ),
          ),
        ),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

closeDialog(context) {
  Navigator.of(context, rootNavigator: true).pop('dialog');
}
