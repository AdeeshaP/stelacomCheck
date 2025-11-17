import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  final int index3;

  const ContactUs({super.key, required this.index3});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  late SharedPreferences _storage;
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  // Location coordinates for Sri Lanka address
  static LatLng _companyLocation = LatLng(6.896372574204375, 79.8576333140073);
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";

  @override
  void initState() {
    super.initState();

    getSharedPrefs();
    _markers.add(
      Marker(
        markerId: MarkerId('company_location'),
        position: _companyLocation,
        infoWindow: InfoWindow(
          title: 'Auradot (Pvt) Ltd.',
          snippet: '410/118 Bauddhaloka Mawatha, Colombo 00700',
        ),
      ),
    );
  }

  void _openMap() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_companyLocation.latitude},${_companyLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userData = _storage.getString('user_data')!;
    employeeCode = _storage.getString('employee_code') ?? "";

    userObj = jsonDecode(userData);
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
                child: userObj != null
                    ? CachedNetworkImage(
                        imageUrl: userObj!['CompanyProfileImage'],
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
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
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: IconButton(
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
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            'Contact Us',
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
                              color: screenHeadingColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(""),
                        )
                      ],
                    ),
                    // Text(
                    //   'Your feedback is very valuable to us!',
                    //   style: TextStyle(
                    //     fontSize: Responsive.isMobileSmall(context)
                    //         ? 14
                    //         : Responsive.isMobileMedium(context) ||
                    //                 Responsive.isMobileLarge(context)
                    //             ? 16
                    //             : Responsive.isTabletPortrait(context)
                    //                 ? 20
                    //                 : 20,
                    //     color: Colors.grey.shade600,
                    //   ),
                    // ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildContactCard(
                      icon: Icons.business,
                      title: 'Company',
                      children: [
                        _buildText('Stelacom (Pvt) Ltd,'),
                        _buildText('410/118 Bauddhaloka Mawatha,'),
                        _buildText('Colombo 00700, Sri Lanka'),
                      ],
                    ),
                    SizedBox(height: 10),

                    _buildContactCard(
                      icon: Icons.phone,
                      title: 'Phone Numbers',
                      children: [
                        // _buildClickableContact(
                        //   'Hotline',
                        //   '+94 773 420 983',
                        //   () => _makeHotLineCall(),
                        // ),
                        // SizedBox(height: 10),
                        _buildClickableContact(
                          'Landline',
                          '+94 114 385 380',
                          () => _makeLandLineCall(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildContactCard(
                      icon: Icons.email,
                      title: 'Email',
                      children: [
                        _buildClickableContact(
                          'Email Us',
                          'contact@icheck.ai',
                          () => _sendEmail(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Map
                    Container(
                      height: 150,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: GestureDetector(
                          onDoubleTap: _openMap,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _companyLocation,
                              zoom: 10,
                            ),
                            markers: _markers,
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _makeLandLineCall() async {
    String phoneNumber = "+94117109911";
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri, mode: LaunchMode.externalNonBrowserApplication);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contact@icheck.ai',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Add Subject',
        'body': 'Write something...!',
      }),
    );

    launchUrl(emailLaunchUri);
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
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
                              ? 28
                              : 30,
                ),
              ),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 16
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 18
                          : Responsive.isTabletPortrait(context)
                              ? 22
                              : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.isMobileSmall(context)
              ? 14
              : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 15.5
                  : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildClickableContact(
      String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              color: numberColors,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
