import 'package:stelacom_check/screens/profile/device_info.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/providers/device_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final dynamic user;
  final int index3;
  ProfileScreen({Key? key, required this.user, required this.index3})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late SharedPreferences _storage;
  final GlobalKey<NavigatorState> forthTabNavKey = GlobalKey<NavigatorState>();

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

    return Scaffold(
      key: forthTabNavKey,
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
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
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
                    child: Column(
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 22
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 26
                                      : Responsive.isTabletPortrait(context)
                                          ? 32
                                          : 32,
                              fontWeight: FontWeight.bold,
                              color: screenHeadingColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Stack(
                    children: [
                      Container(
                        width: Responsive.isMobileSmall(context)
                            ? 80
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 90
                                : Responsive.isTabletPortrait(context)
                                    ? 150
                                    : 150,
                        height: Responsive.isMobileSmall(context)
                            ? 80
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 90
                                : Responsive.isTabletPortrait(context)
                                    ? 150
                                    : 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            widget.user["ProfileImage"],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 20
                                : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.user['FirstName'] +
                        ' ' +
                        (widget.user['LastName'] != null
                            ? widget.user['LastName']
                            : ''),
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 21
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 24
                              : Responsive.isTabletPortrait(context)
                                  ? 32
                                  : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                      'Employee Code', widget.user["Code"], Icons.badge),
                  _buildDivider(),
                  _buildInfoTile('Email', widget.user["Email"], Icons.email),
                  _buildDivider(),
                  _buildInfoTile(
                      'Phone',
                      widget.user['MobilePhone'] != null
                          ? widget.user['MobilePhone']
                          : '',
                      Icons.phone),
                  _buildDivider(),
                  _buildInfoTile(
                    'Office Address',
                    widget.user["OfficeAddress"],
                    Icons.location_on,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return ChangeNotifierProvider(
                        create: (context) => DeviceState(),
                        child: DeviceInfoScreen(
                          user: widget.user,
                          index3: widget.index3,
                        ),
                      );
                    }),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionBtnColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Device Info',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 16
                        : Responsive.isMobileMedium(context)
                            ? 18
                            : Responsive.isMobileLarge(context)
                                ? 19
                                : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColors,
              size: Responsive.isMobileSmall(context)
                  ? 22
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 24
                      : Responsive.isTabletPortrait(context)
                          ? 35
                          : 35,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                                ? 22
                                : 22,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 14
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 16
                            : Responsive.isTabletPortrait(context)
                                ? 24
                                : 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
