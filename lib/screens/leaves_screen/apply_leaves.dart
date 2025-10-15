import 'dart:convert';
import 'dart:io';
import 'package:stelacom_check/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/leaves_screen/leaves.dart';
import 'package:stelacom_check/screens/leaves_screen/view_leave.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/providers/leavestate_provider.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/custom_success_dialog.dart';
import '../../components/utils/dialogs.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final int index3;
  final bool requestAvailable;

  ApplyLeaveScreen(
      {super.key, required this.index3, required this.requestAvailable});

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  bool isFullDay = true;
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController reasonController = TextEditingController();
  SharedPreferences? _storage;
  Map<String, dynamic>? userObj;
  File? imageFile;
  TextEditingController leaveStartController = TextEditingController();
  TextEditingController leaveEndController = TextEditingController();
  TextEditingController noOfDaysController = TextEditingController();
  TextEditingController fileController = TextEditingController();
  TextEditingController leaveDurationController = TextEditingController();
  FocusNode textFiled1 = FocusNode();
  FocusNode textFiled2 = FocusNode();
  FocusNode textFiled3 = FocusNode();
  FocusNode textFiled4 = FocusNode();
  FocusNode textFiled5 = FocusNode();
  FocusNode textFiled6 = FocusNode();
  FocusNode textFiled7 = FocusNode();
  FocusNode textFiled8 = FocusNode();
  bool _validate = false;
  List<bool> isSelected = [false, false];
  List<String> leaveDurationTypes = ["Half Day", "Full Day"];
  String leaveDuration = "";
  FilePickerResult? result;
  String? leaveTypeVal;
  String attachedFileBase64String = "";
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<DateTime> preAddedleavStartDays = [];
  List<DateTime> preAddedleavEndDays = [];
  List<Map<String, dynamic>> leaveTypes = [];
  List<Map<String, dynamic>> approvedLeaveHistory = [];
  LeaveState leaveState = LeaveState();
  bool isRequestAvailable = false;

  @override
  void initState() {
    super.initState();
    leaveState = Provider.of<LeaveState>(context, listen: false);
    getDropdwonData();
    getUserLeaves();
    fetchData();
  }

  @override
  void dispose() {
    leaveStartController.dispose();
    leaveEndController.dispose();
    leaveDurationController.dispose();
    reasonController.dispose();
    fileController.dispose();
    noOfDaysController.dispose();
    textFiled1.dispose();
    textFiled2.dispose();
    textFiled3.dispose();
    textFiled4.dispose();
    textFiled5.dispose();
    textFiled6.dispose();
    textFiled7.dispose();
    textFiled8.dispose();
    super.dispose();
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
          return HelpScreen( index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs( index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs( index3: widget.index3);
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions( index3: widget.index3);
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

  Future<void> getDropdwonData() async {
    _storage = await SharedPreferences.getInstance();
    String? userData = _storage!.getString('user_data');
    userObj = jsonDecode(userData!);

    var response = await ApiService.getLeaveTypes(userObj!["CustomerId"]);
    var listData = jsonDecode(response.body);
    leaveState.updateData(listData);

    print("list data $listData");
  }

  Future<void> getUserLeaves() async {
    _storage = await SharedPreferences.getInstance();
    String? userData = _storage!.getString('user_data');
    userObj = jsonDecode(userData!);
    showProgressDialog(context);

    String userId = userObj!["Id"];

    var response = await ApiService.getLeaves(
      userId,
      Jiffy.parseFromDateTime(DateTime(DateTime.now().year, 1, 1))
          .format(pattern: "yyyy-MM-dd"),
      Jiffy.parseFromDateTime(DateTime(DateTime.now().year, 12, 31))
          .format(pattern: "yyyy-MM-dd"),
    );

    if (response != null && response.statusCode == 200) {
      closeDialog(context);
      var allLeaveList = jsonDecode(response.body);
      leaveState.updateLeaveData(allLeaveList);
    }
  }

// ------------ CHAT GPT ---------------------
  Future<void> fetchData() async {
    _storage = await SharedPreferences.getInstance();
    String? userData = _storage!.getString('user_data');
    userObj = jsonDecode(userData!);

    String userId = userObj!["Id"];
    String customrId = userObj!["CustomerId"];

    final leaveTypesResponse = await ApiService.getLeaveTypes(customrId);

    final leaveHistoryResponse = await ApiService.getLeavesCategorizedWithTypes(
      userId,
      customrId,
      Jiffy.parseFromDateTime(DateTime(DateTime.now().year, 1, 1))
          .format(pattern: "yyyy-MM-dd"),
      Jiffy.parseFromDateTime(DateTime(DateTime.now().year, 12, 31))
          .format(pattern: "yyyy-MM-dd"),
    );

    if (leaveTypesResponse.statusCode == 200 &&
        leaveHistoryResponse.statusCode == 200) {
      var leaveTypesData = json.decode(leaveTypesResponse.body);
      var leaveHistoryData = json.decode(leaveHistoryResponse.body);

      setState(() {
        leaveTypes = List<Map<String, dynamic>>.from(leaveTypesData);
        for (var leaveTypeData in leaveHistoryData) {
          for (var leave in leaveTypeData['Leaves']) {
            if (leave['Status'] == 'Approved') {
              approvedLeaveHistory.add(leave);
            }
          }
        }
      });
    }
    print("approvedLeaveHistory $approvedLeaveHistory");
  }

  double calculateRemainingLeaves2(
    String leaveType1,
    bool isFullDay,
    double numbDays,
  ) {
    final assignedLeaves = leaveTypes
        .firstWhere((type) => type['Property'] == leaveType1)['Value'];

    double usedLeaves = approvedLeaveHistory.fold(0, (total, history) {
      final leaveType = history['Type'];
      final leaveStatus = history['Status'];
      int isFullD = history['IsFullday'];

      if (leaveType == leaveType1 &&
          leaveStatus == 'Approved' &&
          isFullD == 1) {
        final numOfDays = history['NumOfDays'] as int;
        return total + numOfDays;
      } else if (leaveType == leaveType1 &&
          leaveStatus == 'Approved' &&
          isFullD == 0) {
        final numOfDays = history['NumOfDays'] / 2;
        return total + numOfDays;
      }

      return total;
    });

    print(double.parse(assignedLeaves));

    print(usedLeaves);

    final numDays = numbDays; // Include both start and end dates
    final remainingLeaves = double.parse(assignedLeaves) - usedLeaves;

    print(remainingLeaves);

    return remainingLeaves - numDays;
  }

  bool willLeaveCountExceed(
    String leaveType1,
    bool isFullDay,
    double noOfDays,
  ) {
    double remainingLeaves = calculateRemainingLeaves2(
      leaveType1,
      isFullDay,
      noOfDays,
    );

    return remainingLeaves < 0;
  }

  void isLeaveAlreadyApplied(DateTime selectedDate1, DateTime selectedDate2) {
    var isPreLeaveApplieed = false;
    for (var x = 0; x < leaveState.allLeaveList.length; x++) {
      if ((DateTime.parse(leaveState.allLeaveList[x]["FromDate"]) == selectedDate1 || DateTime.parse(leaveState.allLeaveList[x]["ToDate"]) == selectedDate2) &&
          (leaveState.allLeaveList[x]['Status'] == "Approved" ||
              leaveState.allLeaveList[x]['Status'] == "Pending")) {
        isPreLeaveApplieed = true;
        break;
      } else if ((DateTime.parse(leaveState.allLeaveList[x]["FromDate"]) == selectedDate2 || DateTime.parse(leaveState.allLeaveList[x]["ToDate"]) == selectedDate1) &&
          (leaveState.allLeaveList[x]['Status'] == "Approved" ||
              leaveState.allLeaveList[x]['Status'] == "Pending")) {
        isPreLeaveApplieed = true;
        break;
      } else if ((selectedDate1.isAfter(DateTime.parse(leaveState.allLeaveList[x]["FromDate"])) && selectedDate2.isBefore(DateTime.parse(leaveState.allLeaveList[x]["ToDate"]))) &&
          (leaveState.allLeaveList[x]['Status'] == "Approved" ||
              leaveState.allLeaveList[x]['Status'] == "Pending")) {
        isPreLeaveApplieed = true;
        break;
      } else if ((selectedDate1.isAfter(DateTime.parse(leaveState.allLeaveList[x]["FromDate"])) && selectedDate1.isBefore(DateTime.parse(leaveState.allLeaveList[x]["ToDate"]))) ||
          (selectedDate2.isAfter(DateTime.parse(leaveState.allLeaveList[x]["FromDate"])) &&
                  selectedDate2.isBefore(
                      DateTime.parse(leaveState.allLeaveList[x]["ToDate"]))) &&
              (leaveState.allLeaveList[x]['Status'] == "Approved" ||
                  leaveState.allLeaveList[x]['Status'] == "Pending")) {
        isPreLeaveApplieed = true;
        break;
      } else if ((selectedDate1.isBefore(DateTime.parse(leaveState.allLeaveList[x]["FromDate"])) && selectedDate2.isBefore(DateTime.parse(leaveState.allLeaveList[x]["FromDate"]))) &&
              leaveState.allLeaveList[x]['Status'] == "Approved" ||
          leaveState.allLeaveList[x]['Status'] == "Pending") {
        isPreLeaveApplieed = false;
      } else if ((selectedDate1.isAfter(DateTime.parse(leaveState.allLeaveList[x]["ToDate"])) &&
                  selectedDate2.isAfter(DateTime.parse(leaveState.allLeaveList[x]["ToDate"]))) &&
              leaveState.allLeaveList[x]['Status'] == "Approved" ||
          leaveState.allLeaveList[x]['Status'] == "Pending") {
        isPreLeaveApplieed = false;
      }
    }

    if (isPreLeaveApplieed == false) {
      setState(() {
        if (leaveDuration != "Half Day") {
          if (leaveStartController.text.isEmpty ||
              leaveEndController.text.isEmpty ||
              // reasonController.text.isEmpty ||
              noOfDaysController.text.isEmpty) {
            _validate = true;
          } else if (selectedDate1.isAfter(selectedDate2)) {
            showDialog(
              context: context,
              builder: (context) => CustomErrorDialog(
                title: 'Leave Appplying Failed.',
                message:
                    'You should select the leave end date as a date after the leave start date.',
                onOkPressed: () => Navigator.of(context).pop(),
                iconData: Icons.error_outline,
              ),
            );
          } else {
            applyLeaves();
          }
        } else {
          if (leaveStartController.text.isEmpty ||
              noOfDaysController.text.isEmpty) {
            _validate = true;
          } else {
            applyLeaves();
          }
        }
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Leave Appplying Failed.',
          message:
              'You have already applied leave on these dates or within this date range.',
          onOkPressed: () => Navigator.of(context).pop(),
          iconData: Icons.error_outline,
        ),
      );
    }
  }

  int calculateDateDifference(DateTime start, DateTime end) {
    Duration difference = end.difference(start);
    return difference.inDays.abs() +
        1; // add 1 to include both start and end dates
  }

  void applyLeaves() async {
    showProgressDialog(context);

    String memberId = userObj!["Code"];
    String memberName = (userObj!["FirstName"] + " " + userObj!["LastName"]);
    String customerId = userObj!["CustomerId"];
    String leaveDate = leaveStartController.text;
    String fromDate = leaveStartController.text;
    String toDate = leaveDuration == "Half Day"
        ? leaveStartController.text
        : leaveEndController.text;
    String numOfDays = noOfDaysController.text;
    String lastModifiedDate = "";
    String createdBy = userObj!["Code"];
    String LastModifyBy = "";
    String type = leaveTypeVal!;
    String status = "Pending";
    bool isFullDay = leaveTypeVal == "Maternity"
        ? true
        : leaveDuration == "Half Day"
            ? false
            : true;
    String description =
        reasonController.text.isNotEmpty ? reasonController.text : "";
    String attachment = imageFile == null ? "" : attachedFileBase64String;

    var r = await ApiService.postApplyLeaves(
        memberId,
        memberName,
        customerId,
        leaveDate,
        fromDate,
        toDate,
        numOfDays,
        lastModifiedDate,
        createdBy,
        LastModifyBy,
        status,
        description,
        type,
        isFullDay,
        attachment);

    closeDialog(context);
    if (r.statusCode == 200) {
      setState(() {
        leaveTypeVal = null;
        leaveStartController.clear();
        leaveEndController.clear();
        noOfDaysController.clear();
        reasonController.clear();
        leaveDurationController.clear();
        fileController.clear();
        isSelected = [false, false];
        textFiled1.unfocus();
        textFiled2.unfocus();
        textFiled3.unfocus();
        textFiled4.unfocus();
        textFiled5.unfocus();
        textFiled6.unfocus();
        textFiled7.unfocus();
        textFiled8.unfocus();
      });
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => CustomSuccessDialog(
          message: 'Leave request submitted successfully.',
          onOkPressed: okHandler,
        ),
      );
    } else if (r.statusCode == 1001) {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Failed.',
          message: 'Error occured. Try again.',
          onOkPressed: () => Navigator.of(context).pop(),
          iconData: Icons.error_outline,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Failed.',
          message: 'Error occured. Could not add details.',
          onOkPressed: () => Navigator.of(context).pop(),
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
        builder: (context) => ViewLeaveScreen(
          index3: widget.index3,
          requestAvailable: widget.requestAvailable,
        ),
      ),
      (route) => false,
    );
  }

  void okButton() {
    closeDialog(context);
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 2, top: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 13
                : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 14.5
                    : Responsive.isTabletPortrait(context)
                        ? 18
                        : 20,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
    );
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
        resizeToAvoidBottomInset: false,
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
            PopupMenuButton<String>(                  color: Colors.white,

              onSelected: onSelect,
              itemBuilder: (BuildContext context) {
                return _menuOptions.map((String choice) {
                  return PopupMenuItem<String>( padding: EdgeInsets.symmetric(
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
                        "Apply Leave",
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
                padding: EdgeInsets.all(10),
                height: size.height * 0.75,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Leave Type Dropdown
                        _buildLabel('Leave Category'),
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                hint: Text(
                                  'Select Leave Category',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.normal,
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 14
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 15
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 18
                                                : 18,
                                  ),
                                ),
                                value: leaveTypeVal,
                                isExpanded: true,
                                items: leaveState.data.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['Property'].toString(),
                                    child: Text(
                                      item['Property'],
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: Responsive.isMobileSmall(
                                                context)
                                            ? 14
                                            : Responsive.isMobileMedium(
                                                        context) ||
                                                    Responsive.isMobileLarge(
                                                        context)
                                                ? 16
                                                : Responsive.isTabletPortrait(
                                                        context)
                                                    ? 18
                                                    : 18,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    leaveTypeVal = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Leave Duration Radio Buttons
                        _buildLabel('Leave Duration'),
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: Text(
                                          'Full Day',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: Responsive.isMobileSmall(
                                                    context)
                                                ? 13
                                                : Responsive.isMobileMedium(
                                                            context) ||
                                                        Responsive
                                                            .isMobileLarge(
                                                                context)
                                                    ? 14
                                                    : Responsive
                                                            .isTabletPortrait(
                                                                context)
                                                        ? 16
                                                        : 18,
                                          ),
                                        ),
                                        value: 'Full Day',
                                        groupValue: leaveDuration,
                                        onChanged: (String? value) {
                                          setState(() {
                                            leaveDuration = value!;
                                          });
                                          print(
                                              "leave duration is $leaveDuration");
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: iconColors,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: Text(
                                          'Half Day',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: Responsive.isMobileSmall(
                                                    context)
                                                ? 13
                                                : Responsive.isMobileMedium(
                                                            context) ||
                                                        Responsive
                                                            .isMobileLarge(
                                                                context)
                                                    ? 14
                                                    : Responsive
                                                            .isTabletPortrait(
                                                                context)
                                                        ? 16
                                                        : 18,
                                          ),
                                        ),
                                        value: 'Half Day',
                                        groupValue: leaveDuration,
                                        onChanged: (String? value) {
                                          setState(() {
                                            leaveDuration = value!;
                                          });
                                          if (leaveDuration == "Half Day" &&
                                              leaveStartController
                                                  .text.isNotEmpty) {
                                            noOfDaysController.text = "0.5";
                                          } else if (leaveDuration ==
                                                  "Full Day" &&
                                              endDate == null) {
                                            noOfDaysController.text = "";
                                          } else if (leaveDuration ==
                                                  "Full Day" &&
                                              endDate != null) {
                                            print(endDate);
                                            int difference =
                                                calculateDateDifference(
                                                    startDate!, endDate!);
                                            noOfDaysController.text =
                                                difference.toString();
                                          }
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: iconColors,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Date Selection

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLabel('Leave Start Date'),
                                  Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: TextFormField(
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked1 =
                                            await showDatePicker(
                                          builder: (context, child) {
                                            return MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                textScaler:
                                                    TextScaler.linear(1),
                                              ),
                                              child: Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  colorScheme:
                                                      ColorScheme.light(
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
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(Duration(days: 365)),
                                        );

                                        if (picked1 != null) {
                                          setState(() {
                                            startDate = picked1;
                                            leaveStartController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(startDate!);

                                            if (endDate != null) {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, endDate!);
                                              noOfDaysController.text =
                                                  difference.toString();
                                            }
                                            if (leaveDuration == "Half Day") {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, startDate!);
                                              noOfDaysController.text =
                                                  (difference / 2).toString();
                                            } else if (leaveDuration ==
                                                    "Full Day" &&
                                                endDate != null) {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, endDate!);
                                              noOfDaysController.text =
                                                  difference.toString();
                                            } else if (leaveDuration ==
                                                    "Full Day" &&
                                                endDate == null) {
                                              noOfDaysController.text = "";
                                            }
                                          });
                                        }
                                      },
                                      controller: leaveStartController,
                                      decoration: InputDecoration(
                                        errorMaxLines: 2,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        labelText: "Start Date",
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: Responsive.isMobileSmall(
                                                  context)
                                              ? 12
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
                                        errorText: _validate &&
                                                leaveStartController
                                                    .text.isEmpty
                                            ? 'Start date cannot be empty.'
                                            : null,
                                        prefixIcon: IconButton(
                                          icon: Icon(
                                            Icons.calendar_today,
                                            size: Responsive.isMobileSmall(
                                                    context)
                                                ? 18
                                                : Responsive.isMobileMedium(
                                                            context) ||
                                                        Responsive
                                                            .isMobileLarge(
                                                                context)
                                                    ? 21
                                                    : Responsive
                                                            .isTabletPortrait(
                                                                context)
                                                        ? 25
                                                        : 25,
                                          ),
                                          color: iconColors,
                                          onPressed: () {},
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLabel('Leave End Date'),
                                  Card(
                                    color: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: TextFormField(
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked2 =
                                            await showDatePicker(
                                          builder: (context, child) {
                                            return MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                textScaler:
                                                    TextScaler.linear(1),
                                              ),
                                              child: Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  colorScheme:
                                                      ColorScheme.light(
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
                                          initialDate:
                                              startDate ?? DateTime.now(),
                                          firstDate:
                                              startDate ?? DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(Duration(days: 365)),
                                        );
                                        if (picked2 != null) {
                                          setState(() {
                                            endDate = picked2;
                                            print(endDate);
                                            leaveEndController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(endDate!);
                                            if (startDate != null &&
                                                leaveDuration == "Full Day") {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, endDate!);
                                              noOfDaysController.text =
                                                  difference.toString();
                                            }
                                            if (leaveDuration == "Half Day") {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, startDate!);
                                              noOfDaysController.text =
                                                  (difference / 2).toString();
                                            }
                                            if (leaveTypeVal == "Maternity" &&
                                                startDate != null &&
                                                endDate != null) {
                                              int difference =
                                                  calculateDateDifference(
                                                      startDate!, endDate!);
                                              noOfDaysController.text =
                                                  difference.toString();
                                            }
                                          });
                                        }
                                      },
                                      controller: leaveDuration == "Half Day"
                                          ? leaveStartController
                                          : leaveEndController,
                                      decoration: InputDecoration(
                                        errorMaxLines: 2,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        labelText: "End Date",
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: Responsive.isMobileSmall(
                                                  context)
                                              ? 12
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
                                        errorText: _validate &&
                                                leaveStartController
                                                    .text.isEmpty
                                            ? 'End date cannot be empty.'
                                            : null,
                                        prefixIcon: IconButton(
                                          icon: Icon(
                                            Icons.calendar_today,
                                            size: Responsive.isMobileSmall(
                                                    context)
                                                ? 18
                                                : Responsive.isMobileMedium(
                                                            context) ||
                                                        Responsive
                                                            .isMobileLarge(
                                                                context)
                                                    ? 21
                                                    : Responsive
                                                            .isTabletPortrait(
                                                                context)
                                                        ? 25
                                                        : 25,
                                          ),
                                          color: iconColors,
                                          onPressed: () {},
                                        ),
                                      ),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        // Number of Days
                        _buildLabel('Number of Days'),
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: TextFormField(
                            style: TextStyle(fontWeight: FontWeight.w700),
                            controller: noOfDaysController,
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Number of Days',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.normal,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 14
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 15
                                        : Responsive.isTabletPortrait(context)
                                            ? 18
                                            : 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              enabled: false,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Reason
                        _buildLabel('Reason'),
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: TextFormField(
                            textInputAction: TextInputAction.next,
                            controller: reasonController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Leave Reason',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.normal,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 14
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 15
                                        : Responsive.isTabletPortrait(context)
                                            ? 18
                                            : 18,
                              ),
                              contentPadding: EdgeInsets.all(16),
                            ),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Attachment
                        _buildLabel('Attachment'),
                        Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: InkWell(
                            onTap: () async {
                              result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'gif'
                                ],
                              );
                              if (result != null) {
                                PlatformFile file = result!.files.first;
                                setState(() {
                                  fileController.text = file.name;
                                  imageFile = File(file.path!);
                                });
                                Uint8List _bytesOfImg =
                                    await imageFile!.readAsBytes();
                                setState(() {
                                  attachedFileBase64String =
                                      base64.encode(_bytesOfImg);
                                });
                              }
                            },
                            child: TextFormField(
                              style: TextStyle(fontWeight: FontWeight.w700),
                              controller: fileController,
                              readOnly: true,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Add Attachment',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.normal,
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 15
                                          : Responsive.isTabletPortrait(context)
                                              ? 18
                                              : 18,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                                enabled: false,
                                prefixIcon: Icon(
                                  Icons.attach_file,
                                  color: iconColors,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    color: iconColors,
                                  ),
                                  onPressed: () async {
                                    result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: [
                                        'jpg',
                                        'jpeg',
                                        'png',
                                        'gif'
                                      ],
                                    );
                                    if (result != null) {
                                      PlatformFile file = result!.files.first;
                                      setState(() {
                                        fileController.text = file.name;
                                        imageFile = File(file.path!);
                                      });
                                      Uint8List _bytesOfImg =
                                          await imageFile!.readAsBytes();
                                      setState(() {
                                        attachedFileBase64String =
                                            base64.encode(_bytesOfImg);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: actionBtnColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 15),
                                minimumSize: Size(double.infinity, 50)),
                            onPressed: () {
                              if (leaveTypeVal == null ||
                                  noOfDaysController.text.isEmpty ||
                                  leaveDuration == "") {
                                showDialog(
                                  context: context,
                                  builder: (context) => CustomErrorDialog(
                                    title: 'Leave Applying Failed.',
                                    message: leaveTypeVal == null &&
                                            leaveEndController
                                                .text.isNotEmpty &&
                                            leaveStartController
                                                .text.isNotEmpty &&
                                            leaveDuration != ""
                                        ? "Please select leave category of your leave."
                                        : leaveTypeVal == null &&
                                                leaveEndController
                                                    .text.isEmpty &&
                                                leaveStartController
                                                    .text.isEmpty &&
                                                leaveDuration == ""
                                            ? "Please select leave category, duration, start date and end date of your leave."
                                            : leaveTypeVal == null &&
                                                    leaveEndController
                                                        .text.isNotEmpty &&
                                                    leaveStartController
                                                        .text.isNotEmpty &&
                                                    leaveDuration == ""
                                                ? "Please select leave category and duration of your leave."
                                                : leaveTypeVal == null &&
                                                        leaveEndController
                                                            .text.isEmpty &&
                                                        leaveStartController
                                                            .text.isEmpty &&
                                                        leaveDuration != ""
                                                    ? "Please select leave category, start date and end date of your leave."
                                                    : leaveTypeVal == null &&
                                                            noOfDaysController
                                                                .text.isNotEmpty &&
                                                            leaveDuration == ""
                                                        ? "Please select leave category and duration of your leave."
                                                        : leaveTypeVal !=
                                                                    null &&
                                                                noOfDaysController
                                                                    .text
                                                                    .isNotEmpty &&
                                                                leaveDuration ==
                                                                    ""
                                                            ? "Please select leave duration of your leave."
                                                            : leaveTypeVal !=
                                                                        null &&
                                                                    leaveEndController
                                                                        .text
                                                                        .isEmpty &&
                                                                    leaveStartController
                                                                        .text
                                                                        .isEmpty &&
                                                                    leaveDuration ==
                                                                        ""
                                                                ? "Please select leave duration, start date and end date of your leave."
                                                                : leaveTypeVal !=
                                                                            null &&
                                                                        leaveDuration ==
                                                                            ""
                                                                    ? "Please select leave duration of your leave."
                                                                    : "Please select start date and end date of your leave.",
                                    onOkPressed: () =>
                                        Navigator.of(context).pop(),
                                    iconData: Icons.error_outline,
                                  ),
                                );
                              }
                              if (leaveTypeVal != null &&
                                  noOfDaysController.text.isNotEmpty) {
                                if (willLeaveCountExceed(
                                            leaveTypeVal!,
                                            leaveDuration == "Full Day"
                                                ? true
                                                : false,
                                            double.parse(
                                                noOfDaysController.text)) ==
                                        true &&
                                    !DateTime.parse(leaveStartController.text)
                                        .isAfter(DateTime.parse(
                                            leaveEndController.text))) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomErrorDialog(
                                      title: 'Leave Count Exceeds.',
                                      message:
                                          "You can't add this leave. If you add this leave, your assigned $leaveTypeVal leave count will reach to the limit.",
                                      onOkPressed: () =>
                                          Navigator.of(context).pop(),
                                      iconData: Icons.error_outline,
                                    ),
                                  );
                                } else {
                                  if (leaveDuration == "Full Day") {
                                    isLeaveAlreadyApplied(startDate!, endDate!);
                                  } else if (leaveDuration == "Half Day") {
                                    isLeaveAlreadyApplied(
                                        startDate!, startDate!);
                                  }
                                }
                              } else {}
                            },
                            child: Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 18
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
