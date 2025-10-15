import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/leaves_screen/leave_approval_screen.dart';
import 'package:stelacom_check/screens/leaves_screen/leaves.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'dart:convert';
import 'package:stelacom_check/responsive.dart';
import '../../components/utils/dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequestScreenTwo extends StatefulWidget {
  final dynamic userobj;
  final bool requestAvailable;
  final int index3, leaveReqCount;

  LeaveRequestScreenTwo({
    super.key,
    required this.userobj,
    required this.requestAvailable,
    required this.index3,
    required this.leaveReqCount,
  });

  @override
  State<LeaveRequestScreenTwo> createState() => _LeaveRequestScreenTwoState();
}

class _LeaveRequestScreenTwoState extends State<LeaveRequestScreenTwo> {
  DateTime fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime toDate = DateTime(DateTime.now().year, 12, 31);
  SharedPreferences? _storage;
  Map<String, dynamic>? userObj;
  List<dynamic> responsedata = [];
  List individualReqLeaveList = [];
  List groupReqLeaveList = [];
  List allReqLeaveList = [];

  @override
  void initState() {
    super.initState();
    getUserLeaveRequests();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getUserLeaveRequests() async {
    _storage = await SharedPreferences.getInstance();

    showProgressDialog(context);
    String? userData = _storage!.getString('user_data');
    userObj = jsonDecode(userData!);

    String userId = userObj!["Id"];
    String custId = userObj!["CustomerId"];

    var response =
        await ApiService.getIndividualSupervisorLeaveRequests(custId, userId);
    var response2 =
        await ApiService.getGroupSupervisorLeaveRequests(custId, userId);

    if (response.statusCode == 200 &&
        response.body != null &&
        response2.statusCode == 200 &&
        response2.body != null) {
      setState(() {
        individualReqLeaveList = jsonDecode(response.body);
        groupReqLeaveList = jsonDecode(response2.body);
      });

      allReqLeaveList.addAll(individualReqLeaveList);
      allReqLeaveList.addAll(groupReqLeaveList);

      print("individualReqLeaveList list $individualReqLeaveList");
      print("groupReqLeaveList list $groupReqLeaveList");
      print("allReqLeaveList list $allReqLeaveList");
    }
    closeDialog(context);
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
    } else if (choice == _menuOptions[5]) {
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
                requestAvailable: allReqLeaveList.length > 0 ? true : false,
                index3: widget.index3,
              ),
            ),
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
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => Leaves(
                              requestAvailable:
                                  allReqLeaveList.length > 0 ? true : false,
                              index3: widget.index3,
                            ),
                          ),
                          (Route<dynamic> route) => false);
                    },
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      "Leave Requests",
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
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: size.height * 0.7,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allReqLeaveList.length,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              flex: 3,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: boxBgColor,
                                child: Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    color: iconColors,
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 15
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 17
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 18
                                                : 20,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 9,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    allReqLeaveList[index]["FromDate"] ==
                                            allReqLeaveList[index]["ToDate"]
                                        ? Jiffy.parse(allReqLeaveList[index]
                                                ["FromDate"])
                                            .format(pattern: "yyyy/MM/dd")
                                        : Jiffy.parse(allReqLeaveList[index]
                                                    ["FromDate"])
                                                .format(pattern: "yyyy/MM/dd") +
                                            " - " +
                                            Jiffy.parse(allReqLeaveList[index]
                                                    ["ToDate"])
                                                .format(pattern: "yyyy/MM/dd"),
                                    style: TextStyle(
                                      color: numberColors,
                                      fontWeight: FontWeight.w500,
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 13
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 15
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 19
                                                      : 17,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                      "Requested By ${allReqLeaveList[index]["MemberName"]}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: Responsive.isMobileSmall(
                                                context)
                                            ? 11
                                            : Responsive.isMobileMedium(
                                                        context) ||
                                                    Responsive.isMobileLarge(
                                                        context)
                                                ? 13
                                                : Responsive.isTabletPortrait(
                                                        context)
                                                    ? 17
                                                    : 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => leaveApprovalScreen(
                                        userobj: userObj,
                                        memberid: allReqLeaveList[index]
                                            ["MemberId"],
                                        memberName: allReqLeaveList[index]
                                            ["MemberName"],
                                        customerid: allReqLeaveList[index]
                                            ["CustomerId"],
                                        leaveDate: allReqLeaveList[index]
                                            ["LeaveDate"],
                                        leaveId: (index + 1).toString(),
                                        leaveId2: allReqLeaveList[index]["Id"]
                                            .toString(),
                                        leaveType: allReqLeaveList[index]
                                            ["Type"],
                                        reason: allReqLeaveList[index]
                                            ["Description"],
                                        noOfDays: allReqLeaveList[index]
                                                ["NumOfDays"]
                                            .toString(),
                                        status: allReqLeaveList[index]
                                            ["Status"],
                                        fromDate: allReqLeaveList[index]
                                            ["FromDate"],
                                        toDate: allReqLeaveList[index]
                                            ["ToDate"],
                                        createDate: allReqLeaveList[index]
                                            ["CreatedDate"],
                                        createdBy: allReqLeaveList[index]
                                            ["CreatedBy"],
                                        isFullDay: allReqLeaveList[index]
                                            ["IsFullday"],
                                        description: allReqLeaveList[index]
                                            ["Description"],
                                        duration: allReqLeaveList[index]
                                                    ["IsFullday"] ==
                                                0
                                            ? "Half Day"
                                            : "Full Day",
                                        attachments: allReqLeaveList[index]
                                            ["AttachmentUrl"],
                                        leaveRequestsAvailble:
                                            widget.requestAvailable,
                                        index3: widget.index3,
                                        leaveReqCount: widget.leaveReqCount,
                                      ),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.chevron_right,
                                  size: Responsive.isMobileSmall(context)
                                      ? 17
                                      : Responsive.isMobileMedium(context)
                                          ? 22
                                          : Responsive.isMobileLarge(context)
                                              ? 23
                                              : Responsive.isTabletPortrait(
                                                      context)
                                                  ? 30
                                                  : 30,
                                  color: iconColors,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
