import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:flutter/material.dart';

class StyledCheckInPopup extends StatelessWidget {
  final String name;
  final String date;
  final String time;
  final String event;
  // final File imageUrl;
  final String imageUrl;
  final VoidCallback onClose;

  StyledCheckInPopup({
    Key? key,
    required this.name,
    required this.date,
    required this.time,
    required this.event,
    required this.imageUrl,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          width: 320,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with Animation
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Success Text
              Text(
                'Successful',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 22
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 25
                          : Responsive.isTabletPortrait(context)
                              ? 28
                              : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),

              // Profile Image
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColors, width: 2),
                  image: DecorationImage(
                    // image: FileImage(imageUrl),
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 15),

              // Name
              Text(
                name,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 18
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 20
                          : Responsive.isTabletPortrait(context)
                              ? 25
                              : 25,
                  fontWeight: FontWeight.bold,
                  color: screenHeadingColor.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 15),

              // Details Container
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Date', date),
                    SizedBox(height: 8),
                    _buildDetailRow('Time', time),
                    SizedBox(height: 8),
                    _buildDetailRow('Event', event),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
