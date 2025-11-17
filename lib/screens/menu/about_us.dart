import 'dart:convert';
import 'package:get/get.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../responsive.dart';

class AboutUs extends StatefulWidget {
  final int index3;

  AboutUs({super.key, required this.index3});

  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";

  @override
  void initState() {
    super.initState();

    getSharedPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userData = _storage.getString('user_data')!;
    employeeCode = _storage.getString('employee_code') ?? "";

    userObj = jsonDecode(userData);
  }

  List<String> _getMenuOptions() {
    return ['Help', 'About Us', 'Contact Us', 'T & C', 'Log Out'];
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final options = _getMenuOptions();
    // Handle navigation using GetX
    if (choice == options[0]) {
      Get.to(() => HelpScreen(index3: widget.index3));
    } else if (choice == options[1]) {
      Get.to(() => AboutUs(index3: widget.index3));
    } else if (choice == options[2]) {
      Get.to(() => ContactUs(index3: widget.index3));
    } else if (choice == options[3]) {
      Get.to(() => TermsAndConditions(index3: widget.index3));
    } else if (choice == options[4]) {
      LogoutService.logoutWithOptions(context);
    }
  }

  YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'lNzZ-BshyTY',
    flags: YoutubePlayerFlags(autoPlay: false, mute: false),
  );

  Widget youtubeHierarchy() {
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fill,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        if (orientation == Orientation.landscape) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, dynamic) {
              if (didPop) {
                return;
              }

              Navigator.of(context).pop();
            },
            child: Scaffold(body: youtubeHierarchy()),
          );
        } else {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, dynamic) {
              if (didPop) {
                return;
              }

              Navigator.of(context).pop();
            },
            child: Scaffold(
              backgroundColor: screenbgcolor,
              appBar: AppBar(
                backgroundColor: appbarBgColor,
                toolbarHeight:
                    Responsive.isMobileSmall(context) ||
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
                      width:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 90.0
                          : Responsive.isTabletPortrait(context)
                          ? 150
                          : 170,
                      height:
                          Responsive.isMobileSmall(context) ||
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
                      width:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 90.0
                          : Responsive.isTabletPortrait(context)
                          ? 150
                          : 170,
                      height:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 40.0
                          : Responsive.isTabletPortrait(context)
                          ? 120
                          : 100,
                      child: userObj != null
                          ? CachedNetworkImage(
                              imageUrl: userObj!['CompanyProfileImage'],
                              placeholder: (context, url) => Text("..."),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            )
                          : Text(""),
                    ),
                  ],
                ),
                actions: <Widget>[
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (choice) => _handleMenuAction(choice, context),
                    itemBuilder: (BuildContext context) {
                      return _getMenuOptions().map((String choice) {
                        return PopupMenuItem<String>(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 15
                                : 20,
                            vertical:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 5
                                : 10,
                          ),
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
                  ),
                ],
              ),
              body: Column(
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
                            Navigator.of(context).pop();
                          },
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            "About StelacomCheck",
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
                        Expanded(flex: 1, child: Text("")),
                      ],
                    ),
                  ),

                  // Company Description Card
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to StelacomCheck',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 20
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 22
                                    : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 28,
                                fontWeight: FontWeight.bold,
                                // color: Color(0xFF1976D2),
                                color: screenHeadingColor.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'StelacomCheck is focused on non-contact AI driven biometric facial recognition for people management and inventory management. Our comprehensive suite of products combines facial recognition and thermographic imaging together with Artificial Intelligence, Cloud Computing and Geo Fencing.',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 15
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 20,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5.0,
                    ),
                    child: youtubeHierarchy(),
                  ),
                  // Version Info Card
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5.0,
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Version',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 18
                                    : Responsive.isTabletPortrait(context)
                                    ? 20
                                    : 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                // color: Color(0xFF1976D2),
                                color: iconColors,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '1.0.0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 13
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 15
                                      : Responsive.isTabletPortrait(context)
                                      ? 18
                                      : 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
