import 'dart:convert';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/leaves_screen/full_screen_view_attachmanet.dart';
import 'package:stelacom_check/screens/leaves_screen/leave_request_screen_two.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/responsive.dart';
import '../../components/utils/custom_dialog.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class leaveApprovalScreen extends StatefulWidget {
  final String memberid;
  final String memberName;
  final String customerid;
  final String leaveId;
  final String leaveId2;
  final String leaveType;
  final String reason;
  final String noOfDays;
  final String createdBy;
  final String leaveDate;
  final String createDate;
  final String fromDate;
  final String toDate;
  final String status;
  final String duration;
  final String attachments;
  final String description;
  final int isFullDay;
  final bool leaveRequestsAvailble;
  final dynamic userobj;
  final int index3, leaveReqCount;

  leaveApprovalScreen({
    super.key,
    required this.leaveId,
    required this.leaveId2,
    required this.memberid,
    required this.memberName,
    required this.customerid,
    required this.leaveType,
    required this.userobj,
    required this.createdBy,
    required this.reason,
    required this.noOfDays,
    required this.createDate,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.duration,
    required this.attachments,
    required this.description,
    required this.isFullDay,
    required this.leaveRequestsAvailble,
    required this.index3,
    required this.leaveReqCount,
    required this.leaveDate,
    // required this.actions,
    // required this.checkCount,
    // required this.visitCount,
    // required this.totalSecondsWorked,
    // required this.getUserActivities,
    // required this.workingHrs,
  });

  @override
  State<leaveApprovalScreen> createState() => _leaveApprovalScreenState();
}

class _leaveApprovalScreenState extends State<leaveApprovalScreen> {
  SharedPreferences? _storage;
  Map<String, dynamic>? userObj;
  List<dynamic> responsedata = [];
  List allLeaveList = [];
  List<dynamic> leaveData = [];

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
    String? userData = _storage!.getString('user_data');
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
        _storage!.clear();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> approveOrRejectLeaveBYSuperisor(String newStatus) async {
    showProgressDialog(context);
    String leaveId2 = widget.leaveId2;
    String memberId = widget.memberid;
    String memberName = widget.memberName;
    String customerId = widget.customerid;
    String leaveDate = widget.fromDate;
    String createdDate = widget.createDate;
    String fromDate = widget.fromDate;
    String toDate = widget.toDate;
    String numOfDays = widget.noOfDays;
    String lastModifiedDate = "";
    String createdBy = widget.createdBy;
    String approvdby = userObj!["FirstName"] + " " + userObj!["LastName"];
    String LastModifyBy = "";
    String type = widget.leaveType;
    String status = newStatus;
    int isFullDay = widget.isFullDay;
    String description = widget.description;
    String attachment = widget.attachments;

    var r = await ApiService.approveRejectLeaveBySupervisor(
      leaveId2,
      memberId,
      memberName,
      customerId,
      leaveDate,
      fromDate,
      toDate,
      numOfDays,
      createdDate,
      lastModifiedDate,
      approvdby,
      createdBy,
      LastModifyBy,
      status,
      description,
      type,
      isFullDay,
      attachment,
    );

    closeDialog(context);
    print("status Code x : ${r.statusCode}");
    if (r.statusCode == 200) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialogGenerate(
          title: 'Succesful!',
          message: newStatus == "Approved"
              ? "Leave request was approved."
              : "Leave request was rejected.",
          onOkPressed: okHandler,
          iconData: newStatus == "Approved" ? Icons.check : Icons.close,
          btnColor:
              newStatus == "Approved" ? Colors.green[800]! : Colors.red[800]!,
          titleColor:
              newStatus == "Approved" ? Colors.green[800]! : Colors.red[800]!,
          iConColor: newStatus == "Approved" ? Colors.green : Colors.red,
          IconBgColor: newStatus == "Approved"
              ? Colors.green.shade50
              : Colors.red.shade50,
        ),
      );
    } else if (r.statusCode == 1001) {
      await showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error occured.!',
          message: 'Failed Accepttion or rejection.',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
          iconData: Icons.error_outline,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error occured.!',
          message: 'Could not add details.',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
          iconData: Icons.error_outline,
        ),
      );
    }
  }

  void okHandler() {
    closeDialog(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LeaveRequestScreenTwo(
          userobj: userObj,
          requestAvailable: widget.leaveRequestsAvailble,
          index3: widget.index3,
          leaveReqCount: widget.leaveReqCount,
        ),
      ),
      (route) => false,
    );
  }

  void okButton() {
    closeDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LeaveRequestScreenTwo(
                userobj: widget.userobj,
                requestAvailable: widget.leaveRequestsAvailble,
                index3: widget.index3,
                leaveReqCount: widget.leaveReqCount,
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
        body: Container(
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
                              builder: (context) => LeaveRequestScreenTwo(
                                userobj: widget.userobj,
                                requestAvailable: widget.leaveRequestsAvailble,
                                index3: widget.index3,
                                leaveReqCount: widget.leaveReqCount,
                              ),
                            ),
                            (Route<dynamic> route) => false);
                      },
                    ),
                    Expanded(
                      flex: 9,
                      child: Text(
                        "Leave Request Approval",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: screenHeadingColor,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 22
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 23
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
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5),
                      Icon(
                        Icons.now_widgets,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : size.width * 0.05,
                        color: iconColors,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Leave Id : ${widget.leaveId}',
                        style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : 20),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5),
                      Icon(
                        Icons.lock_clock,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : size.width * 0.05,
                        color: iconColors,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Leave Type : ${widget.duration}  ${widget.leaveType} ",
                        style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : 20),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5),
                      Icon(
                        // Icons.drive_file_rename_outline_rounded,
                        Icons.description,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : size.width * 0.05,
                        color: iconColors,
                      ),
                      SizedBox(width: 10),
                      widget.reason == ""
                          ? Text(
                              "Reason : Not provided",
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                          : Text(
                              "Reason : ${widget.reason}",
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5),
                      Icon(
                        Icons.date_range,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : size.width * 0.05,
                        color: iconColors,
                      ),
                      SizedBox(width: 10),
                      widget.duration != 'Half Day'
                          ? Text(
                              "No of Leave Days :  ${widget.noOfDays}",
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                          : Text("No of Leave Days :  1/2",
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5),
                      Icon(
                        Icons.calendar_month_sharp,
                        size: Responsive.isMobileSmall(context)
                            ? 20
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 25
                                : size.width * 0.05,
                        color: iconColors,
                      ),
                      SizedBox(width: 10),
                      widget.fromDate == widget.toDate
                          ? Text(
                              "Date : " +
                                  Jiffy.parse('${widget.fromDate}')
                                      .format(pattern: "dd/MM/yyyy"),
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                          : Text(
                              "Date : " +
                                  Jiffy.parse(widget.fromDate)
                                      .format(pattern: "dd/MM/yyyy") +
                                  " - " +
                                  Jiffy.parse(widget.toDate)
                                      .format(pattern: "dd/MM/yyyy"),
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                    ],
                  ),
                ),
              ),
              widget.attachments == ""
                  ? Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 5),
                            Icon(
                              Icons.attach_file,
                              size: Responsive.isMobileSmall(context)
                                  ? 20
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 25
                                      : size.width * 0.05,
                              color: iconColors,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Attachments : No attachments",
                              style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 16
                                          : 20),
                            )
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                      child: Container(
                        height: Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? size.width * 0.45
                            : Responsive.isTabletPortrait(context)
                                ? size.width * 0.47
                                : size.width * 0.33,
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.file_copy_sharp,
                                    size: Responsive.isMobileSmall(context)
                                        ? 20
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 25
                                            : size.width * 0.05,
                                    color: iconColors,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Attachments : ",
                                    style: TextStyle(
                                        fontSize:
                                            Responsive.isMobileSmall(context) ||
                                                    Responsive.isMobileMedium(
                                                        context) ||
                                                    Responsive.isMobileLarge(
                                                        context)
                                                ? 16
                                                : 20),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttachmentFullScreenViewer(
                                      attachments: widget.attachments,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: Responsive.isMobileSmall(context) ||
                                        Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 120
                                    : Responsive.isTabletPortrait(context)
                                        ? size.width * 0.4
                                        : size.width * 0.24,
                                width: Responsive.isMobileSmall(context) ||
                                        Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 120
                                    : Responsive.isTabletPortrait(context)
                                        ? size.width * 0.5
                                        : size.width * 0.35,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.fill,
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
                    ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          approveOrRejectLeaveBYSuperisor("Approved");
                        },
                        child: Text(
                          "Approve",
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 18
                                        : 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                            fixedSize: Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            foregroundColor: actionBtnTextColor,
                            backgroundColor: actionBtnColor),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          approveOrRejectLeaveBYSuperisor("Rejected");
                        },
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 18
                                        : 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(120, 40),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          foregroundColor: actionBtnTextColor,
                        ),
                      )
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
