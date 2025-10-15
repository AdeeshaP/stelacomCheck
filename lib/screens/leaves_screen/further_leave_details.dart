import 'dart:convert';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:flutter/material.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/leaves_screen/full_screen_view_attachmanet.dart';
import 'package:stelacom_check/screens/leaves_screen/view_leave.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveDetailsView extends StatefulWidget {
  LeaveDetailsView(
      {Key? key,
      required this.leaveId,
      required this.leaveType,
      required this.reason,
      required this.noOfDays,
      required this.fromDate,
      required this.toDate,
      required this.status,
      required this.duration,
      required this.attachments,
      this.user,
      required this.index3,
      required this.requestAvailable})
      : super(key: key);

  final String leaveId;
  final String leaveType;
  final String reason;
  final String noOfDays;
  final String fromDate;
  final String toDate;
  final String status;
  final String duration;
  final String attachments;
  final dynamic user;
  final int index3;
  final bool requestAvailable;

  State<LeaveDetailsView> createState() => _LeaveDetailsViewState();
}

class _LeaveDetailsViewState extends State<LeaveDetailsView> {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;

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
    String? userData = _storage.getString('user_data');
    userObj = jsonDecode(userData!);
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
  void onSelect(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return HelpScreen(index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs(index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs(index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions(index3: widget.index3);
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
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => ViewLeaveScreen(
                      index3: widget.index3,
                      requestAvailable: widget.requestAvailable,
                    )),
            (Route<dynamic> route) => false);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
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
              onSelected: onSelect,
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
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ViewLeaveScreen(
                            index3: 2,
                            requestAvailable: widget.requestAvailable,
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      " Leave Details",
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
            Container(
              height: size.height * 0.75,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),

                    // Details Cards
                    _buildDetailCard(
                        'Leave ID', '${widget.leaveId}', Icons.now_widgets),
                    _buildDetailCard(
                      'Leave Type',
                      '${widget.duration}  ${widget.leaveType} ',
                      Icons.lock_clock,
                    ),
                    _buildDetailCard(
                      'Leave Status',
                      '${widget.status}  ',
                      Icons.pending_actions,
                    ),
                    _buildDetailCard(
                      'Reason',
                      widget.reason == "" ? 'Not provided' : '${widget.reason}',
                      Icons.description,
                    ),
                    _buildDetailCard(
                      'No of Leave Days',
                      widget.duration != 'Half Day'
                          ? '${widget.noOfDays}'
                          : '1/2',
                      Icons.date_range,
                    ),
                    _buildDetailCard(
                      'Date',
                      widget.fromDate == widget.toDate
                          ? Jiffy.parse('${widget.fromDate}')
                              .format(pattern: "dd/MM/yyyy")
                          : Jiffy.parse(widget.fromDate)
                                  .format(pattern: "dd/MM/yyyy") +
                              " - " +
                              Jiffy.parse(widget.toDate)
                                  .format(pattern: "dd/MM/yyyy"),
                      Icons.calendar_today,
                    ),
                    widget.attachments == ""
                        ? _buildDetailCard(
                            'Attachments',
                            'No attachments',
                            Icons.attach_file,
                          )
                        : _withAttachmentCard(
                            'Attachments',
                            Icons.attach_file,
                            iconColors,
                          ),
                  ],
                ),
              ),
            ), // Status Card
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: iconColors,
                size: Responsive.isMobileSmall(context)
                    ? 20
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: Responsive.isMobileSmall(context)
                          ? 12
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 14
                              : 17),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.isMobileSmall(context)
                          ? 14
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 16
                              : 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _withAttachmentCard(
    String title,
    IconData icon,
    Color color, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 1),
      child: Container(
        height: Responsive.isMobileSmall(context) ||
                Responsive.isMobileMedium(context) ||
                Responsive.isMobileLarge(context)
            ? 200
            : Responsive.isTabletPortrait(context)
                ? 120
                : 120,
        margin: EdgeInsets.only(bottom: isLast ? 0 : 5),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.0, vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: boxBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: color,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 24
                                : 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 12
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 14
                                      : 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AttachmentFullScreenViewer(
                      attachments: widget.attachments,
                    ),
                  ),
                );
              },
              child: Container(
                height: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 100
                    : Responsive.isTabletPortrait(context)
                        ? 130
                        : 130,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.contain,
                    image: NetworkImage(
                      widget.attachments,
                    ),
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
