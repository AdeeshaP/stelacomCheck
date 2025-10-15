import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/main.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoPermissionGranted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height + 24,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text(
                'Welcome to iCheck\nAttendance Management System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 20
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 22
                          : Responsive.isTabletPortrait(context)
                              ? 25
                              : 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 60),
              // OTP Icon
              Container(
                height: 150,
                child: Center(
                  child: Image.asset(
                    'assets/images/iCheck_logo_2024.png',
                    fit: BoxFit.fill,
                    scale: 2,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                "This application need all asked permissions granted to function properly. So please grant the permission before start it again.",
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 17
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 20
                          : Responsive.isTabletPortrait(context)
                              ? 22
                              : 25,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Container(
                height: 60,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: actionBtnTextColor,
                    backgroundColor: actionBtnColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: actionBtnTextColor)),
                  ),
                  onPressed: () async {
                    Map<Permission, PermissionStatus> permissions = await [
                      Permission.camera,
                      Permission.location,
                      // Permission.speech,
                      // Permission.locationAlways,
                      // Permission.storage
                    ].request();

                    if ((permissions[Permission.camera] ==
                                PermissionStatus.granted ||
                            permissions[Permission.camera] ==
                                PermissionStatus.restricted ||
                            permissions[Permission.camera] ==
                                PermissionStatus.permanentlyDenied) &&
                        (permissions[Permission.location] ==
                                PermissionStatus.granted ||
                            permissions[Permission.location] ==
                                PermissionStatus.restricted ||
                            permissions[Permission.location] ==
                                PermissionStatus.permanentlyDenied)) //&&
                    // permissions[Permission.microphone] ==
                    //     PermissionStatus.granted &&
                    // permissions[Permission.speech] ==
                    //     PermissionStatus.granted &&
                    // permissions[Permission.storage] ==
                    //     PermissionStatus.granted)
                    {
                      SharedPreferences storage =
                          await SharedPreferences.getInstance();
                      runApp(
                        MaterialApp(
                          debugShowCheckedModeBanner: false,
                          theme: ThemeData(primarySwatch: Colors.pink),
                          home: MyApp(storage),
                        ),
                      );
                    }
                  },
                  label: Text(
                    "Try Permission Again",
                    style: TextStyle(fontSize: 20.0),
                  ),
                  icon: Icon(Icons.security, size: 50.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
