import 'package:stelacom_check/screens/profile/profile_home.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoScreen extends StatefulWidget {
  final dynamic user;
  final int index3;

  DeviceInfoScreen({Key? key, required this.user, required this.index3})
      : super(key: key);
  @override
  _DeviceInfoScreenState createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  late SharedPreferences _storage;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    try {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      setState(() {
        _deviceData = _readAndroidGeneraldData(androidInfo);
      });
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  Map<String, dynamic> _readAndroidGeneraldData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'Device Id': build.id,
      'Device Brand': build.brand,
      'Device': build.device,
      'Device Model': build.model,
      'Product': build.product,
      'Android Version': build.version.release,
      'API Level': build.version.sdkInt,
      'Manufacturer': build.manufacturer,
    };
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
  }

  // SIDE MENU BAR UI
  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out'
  ];

  // --------- Side Menu Bar Navigation ---------- //
  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return HelpScreen(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == _menuOptions[4]) {
      if (!mounted)
        return;
      else {
        _storage.clear();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final mediaQuery = MediaQuery.of(context);
    final logicalWidth = mediaQuery.size.width;
    final logicalHeight = mediaQuery.size.height;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    final physicalWidth = logicalWidth * devicePixelRatio;
    final physicalHeight = logicalHeight * devicePixelRatio;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(user: widget.user, index3: widget.index3)),
            (Route<dynamic> route) => false);
      },
      child: Scaffold(
        backgroundColor: screenbgcolor,
        appBar: AppBar(
          backgroundColor: appbarBgColor,
          toolbarHeight: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 40
              : Responsive.isTabletPortrait(context)
                  ? 80
                  : 90,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --------- App Logo ---------- //
              SizedBox(
                width: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 90.0
                    : Responsive.isTabletPortrait(context)
                        ? 150
                        : 170,
                height: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 40.0
                    : Responsive.isTabletPortrait(context)
                        ? 120
                        : 100,
                child: Image.asset(
                  'assets/images/iCheck_logo_2024.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: size.width * 0.25),
              // --------- Company Logo ---------- //
              SizedBox(
                width: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 90.0
                    : Responsive.isTabletPortrait(context)
                        ? 150
                        : 170,
                height: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 40.0
                    : Responsive.isTabletPortrait(context)
                        ? 120
                        : 100,
                child: widget.user != null
                    ? CachedNetworkImage(
                        imageUrl: widget.user!['CompanyProfileImage'],
                        placeholder: (context, url) => Text("..."),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    : Text(""),
              ),
            ],
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              color: Colors.white,
              onSelected: choiceAction,
              itemBuilder: (BuildContext context) {
                return _menuOptions.map((String choice) {
                  return PopupMenuItem<String>(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 15
                            : 20,
                        vertical: Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 5
                            : 10),
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 15
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 17
                                : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 25,
                      ),
                    ),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: screenHeadingColor,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 24
                                : Responsive.isTabletPortrait(context)
                                    ? 31
                                    : 35,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                    user: widget.user, index3: widget.index3)),
                            (Route<dynamic> route) => false);
                      },
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        "Device Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: screenHeadingColor,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 22
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 25
                                  : Responsive.isTabletPortrait(context)
                                      ? 32
                                      : 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(""),
                    )
                  ],
                ),
              ),
              SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.smartphone,
                title: 'Hardware Information',
                items: {
                  'Device Id': _deviceData['Device Id'] ?? 'N/A',
                  'Device Brand': _deviceData['Device Brand'] ?? 'N/A',
                  'Device': _deviceData['Device'] ?? 'N/A',
                  'Device Model': _deviceData['Device Model'] ?? 'N/A',
                  'Product': _deviceData['Product'] ?? 'N/A',
                },
              ),
              SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.android,
                title: 'System Information',
                items: {
                  'Android Version': _deviceData['Android Version'] ?? 'N/A',
                  'API Level': _deviceData['API Level']?.toString() ?? 'N/A',
                },
              ),
              SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.cast,
                title: 'Display Information',
                items: {
                  'Device Width (px)': '${physicalWidth.toStringAsFixed(0)} px',
                  'Device Height (px)':
                      '${physicalHeight.toStringAsFixed(0)} px',
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Map<String, String> items,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Card(
        color: cardColros,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColors,
                    size: Responsive.isMobileSmall(context)
                        ? 22
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 25
                            : Responsive.isTabletPortrait(context)
                                ? 35
                                : 35,
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 16
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 18
                              : Responsive.isTabletPortrait(context)
                                  ? 25
                                  : 25,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...items.entries
                  .map((entry) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 14
                                        : Responsive.isTabletPortrait(context)
                                            ? 22
                                            : 22,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 14
                                        : Responsive.isTabletPortrait(context)
                                            ? 22
                                            : 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
