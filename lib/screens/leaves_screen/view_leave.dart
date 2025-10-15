import 'dart:convert';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/leaves_screen/further_leave_details.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/leaves_screen/leaves.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/responsive.dart';
import '../../components/utils/custom_error_dialog.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewLeaveScreen extends StatefulWidget {
  ViewLeaveScreen(
      {Key? key, required this.index3, required this.requestAvailable})
      : super(key: key);

  final int index3;
  final bool requestAvailable;

  @override
  State<ViewLeaveScreen> createState() => _ViewLeaveScreenState();
}

class _ViewLeaveScreenState extends State<ViewLeaveScreen> {
  final textController = TextEditingController();
  List allLeaveList = [];
  SharedPreferences? _storage;
  Map<String, dynamic>? userObj;
  List<dynamic> responsedata = [];
  DateTime fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime toDate = DateTime(DateTime.now().year, 12, 31);
  List<dynamic> leaveData = [];
  bool isLoading = true;
  final yourScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getUserLeaves(fromDate, toDate);
  }

  Future<void> getUserLeaves(DateTime startDay, DateTime endDay) async {
    _storage = await SharedPreferences.getInstance();

    String? userData = _storage!.getString('user_data');
    userObj = jsonDecode(userData!);
    // showProgressDialog(context);

    String userId = userObj!["Id"];
    startDay = fromDate;
    endDay = toDate;

    var response = await ApiService.getLeaves(
      userId,
      Jiffy.parseFromDateTime(startDay).format(pattern: "yyyy-MM-dd"),
      Jiffy.parseFromDateTime(endDay).format(pattern: "yyyy-MM-dd"),
    );

    print('Response body: ${response.body.toString()}');
    if (response != null &&
        response.statusCode == 200 &&
        response.body != null) {
      // closeDialog(context);
      setState(() {
        allLeaveList = jsonDecode(response.body);
        allLeaveList.sort((a, b) => a["Id"].compareTo(
              b["Id"],
            ));
        isLoading = false;
      });
    } else {
      // closeDialog(context);
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error occured.!',
          message:
              'Loading actions failed. Please contact system administrator',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
          iconData: Icons.error_outline,
        ),
      );
    }
    // closeDialog(context);
  }

  // SIDE MENU BAR UI
  List<String> myMenuItems = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out'
  ];

  // --------- Side Menu Bar Navigation ---------- //
  void onSelect(String choice) {
    if (choice == myMenuItems[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return HelpScreen(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == myMenuItems[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == myMenuItems[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == myMenuItems[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions(
            index3: widget.index3,
          );
        }),
      );
    } else if (choice == myMenuItems[4]) {
      if (!mounted)
        return;
      else {
        _storage!.clear();
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
                builder: (context) => Leaves(
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
            Theme(
                data: Theme.of(context).copyWith(
                  cardColor: actionBtnTextColor,
                ),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  onSelected: onSelect,
                  itemBuilder: (BuildContext context) {
                    return myMenuItems.map((String choice) {
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
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
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
                ))
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => Leaves(
                                    index3: widget.index3,
                                    requestAvailable: widget.requestAvailable,
                                  )),
                          (Route<dynamic> route) => false);
                    },
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      "View Leave",
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  // Date Range Section
                  Align(
                    child: Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 17
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 19
                                : Responsive.isTabletPortrait(context)
                                    ? 22
                                    : 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  SizedBox(height: 5),

                  // Date Range Picker Cards
                  _buildDateSelectors(),
                  SizedBox(height: 10),

                  // Leave List
                  isLoading
                      ? Padding(
                          padding: EdgeInsets.all(100),
                          child: CircularProgressIndicator(
                              color: screenHeadingColor),
                        ) // Show loading indicator.
                      : allLeaveList.length == 0 || allLeaveList.isEmpty
                          ? Column(
                              children: [
                                SizedBox(height: 90),
                                Icon(
                                  Icons.calendar_month,
                                  size: Responsive.isMobileSmall(context)
                                      ? 40
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 50
                                          : Responsive.isTabletPortrait(context)
                                              ? 60
                                              : 70,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "You have not applied for any leave yet.",
                                  style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 20
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 23
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 30
                                                      : 35,
                                      color: Colors.grey),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            )
                          : Container(
                              height: size.height * 0.55,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: allLeaveList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: InkWell(
                                          onTap: () {},
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            child: Row(
                                              children: [
                                                // Index Circle
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: boxBgColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      (index + 1).toString(),
                                                      style: TextStyle(
                                                        color: iconColors,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: Responsive
                                                                .isMobileSmall(
                                                                    context)
                                                            ? 15
                                                            : Responsive.isMobileMedium(
                                                                        context) ||
                                                                    Responsive
                                                                        .isMobileLarge(
                                                                            context)
                                                                ? 18
                                                                : Responsive.isTabletPortrait(
                                                                        context)
                                                                    ? 20
                                                                    : 25,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                // Leave Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 2),
                                                      Text(
                                                        allLeaveList[index][
                                                                    "FromDate"] ==
                                                                allLeaveList[index]
                                                                    ["ToDate"]
                                                            ? Jiffy.parse(
                                                                    allLeaveList[index][
                                                                        "FromDate"])
                                                                .format(
                                                                    pattern:
                                                                        "yyyy/MM/dd")
                                                            : Jiffy.parse(allLeaveList[index]["FromDate"])
                                                                    .format(
                                                                        pattern:
                                                                            "yyyy/MM/dd") +
                                                                " - " +
                                                                Jiffy.parse(allLeaveList[index]["ToDate"])
                                                                    .format(
                                                                        pattern: "yyyy/MM/dd"),
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 14
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 16
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 18
                                                                      : 22,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        allLeaveList[index][
                                                                    "IsFullday"] ==
                                                                1
                                                            ? "Full Day Leave"
                                                            : "Half Day Leave",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontSize: Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 12
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 14
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 17
                                                                      : 20,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      allLeaveList[index][
                                                                      "Status"] ==
                                                                  "Rejected" ||
                                                              allLeaveList[
                                                                          index]
                                                                      [
                                                                      "Status"] ==
                                                                  "0"
                                                          ? Text(
                                                              "Leave rejected.",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: Responsive
                                                                        .isMobileSmall(
                                                                            context)
                                                                    ? 13
                                                                    : Responsive.isMobileMedium(context) ||
                                                                            Responsive.isMobileLarge(context)
                                                                        ? 14
                                                                        : Responsive.isTabletPortrait(context)
                                                                            ? 17
                                                                            : 17,
                                                              ),
                                                            )
                                                          : allLeaveList[index][
                                                                          "Status"] ==
                                                                      "Approved" ||
                                                                  allLeaveList[
                                                                              index]
                                                                          [
                                                                          "Status"] ==
                                                                      "1"
                                                              ? Text(
                                                                  "Leave approved.",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .green,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize: Responsive.isMobileSmall(
                                                                            context)
                                                                        ? 13
                                                                        : Responsive.isMobileMedium(context) ||
                                                                                Responsive.isMobileLarge(context)
                                                                            ? 14
                                                                            : Responsive.isTabletPortrait(context)
                                                                                ? 17
                                                                                : 17,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "Leave approval is pending.",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .amber
                                                                        .shade500,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize: Responsive.isMobileSmall(
                                                                            context)
                                                                        ? 13
                                                                        : Responsive.isMobileMedium(context) ||
                                                                                Responsive.isMobileLarge(context)
                                                                            ? 14
                                                                            : Responsive.isTabletPortrait(context)
                                                                                ? 17
                                                                                : 17,
                                                                  ),
                                                                ),
                                                      SizedBox(height: 4)
                                                    ],
                                                  ),
                                                ),
                                                // View Icon
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            LeaveDetailsView(
                                                          leaveId: (index + 1)
                                                              .toString(),
                                                          leaveType:
                                                              allLeaveList[
                                                                      index]
                                                                  ["Type"],
                                                          reason: allLeaveList[
                                                                  index]
                                                              ["Description"],
                                                          noOfDays: allLeaveList[
                                                                      index]
                                                                  ["NumOfDays"]
                                                              .toString(),
                                                          status: allLeaveList[
                                                              index]["Status"],
                                                          fromDate:
                                                              allLeaveList[
                                                                      index]
                                                                  ["FromDate"],
                                                          toDate: allLeaveList[
                                                              index]["ToDate"],
                                                          duration: allLeaveList[
                                                                          index]
                                                                      [
                                                                      "IsFullday"] ==
                                                                  0
                                                              ? "Half Day"
                                                              : "Full Day",
                                                          attachments:
                                                              allLeaveList[
                                                                      index][
                                                                  "AttachmentUrl"],
                                                          index3: widget.index3,
                                                          requestAvailable: widget
                                                              .requestAvailable,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Icon(Icons.visibility,
                                                      color: Colors.grey[400]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "From Date",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                                ? 18
                                : 20,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked1 = await showDatePicker(
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(1),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: screenHeadingColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                      },
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2101),
                    );

                    setState(() {
                      fromDate = picked1!;
                      getUserLeaves(fromDate, toDate);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: Responsive.isMobileSmall(context)
                                ? 16
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 18
                                    : Responsive.isTabletPortrait(context)
                                        ? 22
                                        : 25,
                            color: iconColors),
                        SizedBox(width: 8),
                        Text(
                          Jiffy.parseFromDateTime(fromDate)
                              .format(pattern: "yyyy/MM/dd"),
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 20
                                        : 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "To Date",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                                ? 18
                                : 20,
                  ),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked2 = await showDatePicker(
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(1),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: screenHeadingColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                      },
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2101),
                    );
                    setState(() {
                      toDate = picked2!;
                      getUserLeaves(fromDate, toDate);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: Responsive.isMobileSmall(context)
                                ? 16
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 18
                                    : Responsive.isTabletPortrait(context)
                                        ? 22
                                        : 25,
                            color: iconColors),
                        SizedBox(width: 8),
                        Text(
                          Jiffy.parseFromDateTime(toDate)
                              .format(pattern: "yyyy/MM/dd"),
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 20
                                        : 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
