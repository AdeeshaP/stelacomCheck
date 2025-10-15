import 'package:stelacom_check/responsive.dart';
import 'package:flutter/material.dart';

class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onOkPressed;
  final IconData iconData;

  CustomErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onOkPressed,
    required this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 8.0,
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: Colors.red.shade700,
                size: Responsive.isMobileSmall(context)
                    ? 35
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 40
                        : Responsive.isTabletPortrait(context)
                            ? 50
                            : 50,
              ),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.isMobileSmall(context)
                    ? 22
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                            ? 28
                            : 30,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.0),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.isMobileSmall(context)
                    ? 15
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 17
                        : Responsive.isTabletPortrait(context)
                            ? 20
                            : 25,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24.0),

            // OK Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 14
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 16
                            : Responsive.isTabletPortrait(context)
                                ? 20
                                : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
