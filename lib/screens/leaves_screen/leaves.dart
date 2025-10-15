import 'package:stelacom_check/screens/leaves_screen/leave_request_screen_two.dart';
import 'package:stelacom_check/providers/appstate_provider.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/leaves_screen/apply_leaves.dart';
import 'package:stelacom_check/screens/leaves_screen/view_leave.dart';
import 'package:stelacom_check/providers/leavestate_provider.dart';
import '../../components/utils/custom_error_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:jiffy/jiffy.dart';
import '../enroll/code_verification.dart';

class LeaveType {
  final String type;
  final int totalLeaves;
  final int halfDayLeaves;
  final int fullDayLeaves;
  final double balanceLeaves;

  LeaveType({
    required this.type,
    required this.totalLeaves,
    required this.halfDayLeaves,
    required this.fullDayLeaves,
    required this.balanceLeaves,
  });
}

class Leaves extends StatefulWidget {
  Leaves({
    Key? key,
    this.user,
    required this.index3,
    required this.requestAvailable,
  }) : super(key: key);

  final dynamic user;
  final int index3;
  final bool requestAvailable;

  @override
  State<Leaves> createState() => _LeavesState();
}

class _LeavesState extends State<Leaves> {
  final primaryColor = Color(0xFFE64A19); // Deeper orange
  final secondaryColor = Color(0xFFFF7043); // Softer orange
  final backgroundColor = Color(0xFFFBE9E7); // Very light orange background
  final Color textColor = Color(0xFF424242); // Dark grey for text
  final Color baseColor = Color(0xFFFBE9E7);
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  final GlobalKey<NavigatorState> thirdTabNavKey = GlobalKey<NavigatorState>();
  List<dynamic> leaveCounts = [];
  DateTime fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime toDate = DateTime(DateTime.now().year, 12, 31);
  List<dynamic> leaveData = [];
  int OTRequestedCount = 0;
  int leaveRequestedCount = 0;
  late AppState appState;

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    getUserLeavesWithTypes();
    appState = Provider.of<AppState>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    String? userData = _storage.getString('user_data');
    userObj = jsonDecode(userData!);

    await getSupervisorLeaveRequests();
  }

  Future<void> getUserLeavesWithTypes() async {
    _storage = await SharedPreferences.getInstance();
    String? userData = _storage.getString('user_data');
    userObj = jsonDecode(userData!);
    // showProgressDialog(context);
    String userId = userObj!["Id"];
    String customerId = userObj!["CustomerId"];

    var response = await ApiService.getLeavesCategorizedWithTypes(
      userId,
      customerId,
      Jiffy.parseFromDateTime(fromDate).format(pattern: "yyyy-MM-dd"),
      Jiffy.parseFromDateTime(toDate).format(pattern: "yyyy-MM-dd"),
    );

    print('Response body: ${response.body.toString()}');
    if (response != null &&
        response.statusCode == 200 &&
        response.body != null) {
      setState(() {
        leaveData = jsonDecode(response.body);
        print("leaveData $leaveData");
        // closeDialog(context);
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

    var response2 = await ApiService.getLeaveTypes(userObj!["CustomerId"]);

    if (response2 != null &&
        response2.statusCode == 200 &&
        response2.body != null) {
      // var listData = jsonDecode(response2.body);

      if (mounted)
        setState(() {
          // leaveTypes = listData;
          leaveCounts = jsonDecode(response2.body);
        });

      print("leaveCounts $leaveCounts");
    }
  }

  List<LeaveType> getLeaveTypesWithCounts() {
    List<LeaveType> leaveTypes = [];
    for (var leaveCountData in leaveCounts) {
      String type = leaveCountData['Property'];
      int totalLeaves = int.parse(leaveCountData['Value']);
      int halfDayLeaves = 0;
      int fullDayLeaves = 0;

      for (var leaveTypeData in leaveData) {
        String leaveType = leaveTypeData['Type'];
        if (leaveType == type) {
          for (var leave in leaveTypeData['Leaves']) {
            int numDays = leave['NumOfDays'] == null ? 0 : leave['NumOfDays'];
            if (leave['IsFullday'] == 1 && leave['Status'] == "Approved") {
              fullDayLeaves += numDays;
            } else if (leave['IsFullday'] == 0 &&
                leave['Status'] == "Approved") {
              halfDayLeaves += numDays;
            }
          }
        }
      }

      double balanceLeaves =
          totalLeaves.toDouble() - (halfDayLeaves + fullDayLeaves);

      leaveTypes.add(LeaveType(
        type: type,
        totalLeaves: totalLeaves,
        halfDayLeaves: halfDayLeaves,
        fullDayLeaves: fullDayLeaves,
        balanceLeaves: balanceLeaves,
      ));
    }

    return leaveTypes;
  }

  // GET All the leave requests from supervisor

  Future<void> getSupervisorLeaveRequests() async {
    _storage = await SharedPreferences.getInstance();
    String? userData = _storage.getString('user_data');

    Map<String, dynamic> userObj3 = jsonDecode(userData!);
    var response = await ApiService.getIndividualSupervisorLeaveRequests(
        userObj3["CustomerId"], userObj3["Id"]);
    var response2 = await ApiService.getGroupSupervisorLeaveRequests(
        userObj3["CustomerId"], userObj3["Id"]);

    if (response.statusCode == 200 &&
        response.body != "null" &&
        response2.statusCode == 200 &&
        response2.body != "null") {
      if (mounted) {
        appState.updateSupervisorRequests(
          jsonDecode(response.body),
          jsonDecode(response2.body),
        );
      }

      leaveRequestedCount = appState.individualRequestLeaves.length +
          appState.groupRequestLeaves.length;
    }
  }

//   // SIDE MENU BAR UI
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

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
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
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      : Text(""),
                ),
              ],
            ),
            backgroundColor: appbarBgColor,
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: onSelect,
                color: Colors.white,
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        'Leave Management',
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
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your leaves efficiently',
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
                    ],
                  ),
                ),
                SizedBox(height: 24),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildActionButton(
                          icon: Icons.edit_calendar_outlined,
                          title: 'Apply Leave',
                          subtitle: 'Submit a new leave request',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return ChangeNotifierProvider(
                                  child: ApplyLeaveScreen(
                                    index3: widget.index3,
                                    requestAvailable: appState.requestAvailable,
                                  ),
                                  create: (context) => LeaveState(),
                                );
                              }),
                            );
                          }),
                      SizedBox(height: 12),
                      _buildActionButton(
                          icon: Icons.calendar_month,
                          title: 'View Leave',
                          subtitle: 'Check your leave history and status',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return ViewLeaveScreen(
                                  index3: widget.index3,
                                  requestAvailable: appState.requestAvailable,
                                );
                              }),
                            );
                          }),
                      SizedBox(height: 12),
                      _buildApprovalsSummaryCard(),
                      SizedBox(height: 12),
                      _buildLeaveBalanceContainer(size),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApprovalsSummaryCard() {
    return widget.user["IsSupervisor"] == 1
        ? Card(
            elevation: 1,
            margin: EdgeInsets.symmetric(horizontal: 10),
            color: cardColros,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Approvals',
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
                      color: textColor,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Leave Requested",
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 13
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 14
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 15
                                                      : 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  appState.individualRequestLeaves.length +
                                              appState
                                                  .groupRequestLeaves.length >
                                          0
                                      ? Badge(
                                          alignment:
                                              AlignmentDirectional.topEnd,
                                          backgroundColor: Colors.red,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      LeaveRequestScreenTwo(
                                                    userobj: widget.user,
                                                    requestAvailable:
                                                        widget.requestAvailable,
                                                    index3: widget.index3,
                                                    leaveReqCount: appState
                                                            .individualRequestLeaves
                                                            .length +
                                                        appState
                                                            .groupRequestLeaves
                                                            .length,
                                                  ),
                                                ),
                                                (route) => false,
                                              );
                                            },
                                            child: Container(
                                              decoration:
                                                  BoxDecoration(boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ]),
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 5),
                                              child: Text(
                                                leaveRequestedCount > 1
                                                    ? "${leaveRequestedCount} Requests"
                                                    : "${leaveRequestedCount} Request",
                                                style: TextStyle(
                                                    fontSize: Responsive
                                                            .isMobileSmall(
                                                                context)
                                                        ? 12
                                                        : Responsive.isMobileMedium(
                                                                    context) ||
                                                                Responsive
                                                                    .isMobileLarge(
                                                                        context)
                                                            ? 13
                                                            : Responsive
                                                                    .isTabletPortrait(
                                                                        context)
                                                                ? 14
                                                                : 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: numberColors),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade200,
                                            ),
                                          ]),
                                          margin: EdgeInsets.all(3),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          child: Text(
                                            "No Requests",
                                            style: TextStyle(
                                              fontSize: Responsive
                                                      .isMobileSmall(context)
                                                  ? 12
                                                  : Responsive.isMobileMedium(
                                                              context) ||
                                                          Responsive
                                                              .isMobileLarge(
                                                                  context)
                                                      ? 13
                                                      : Responsive
                                                              .isTabletPortrait(
                                                                  context)
                                                          ? 14
                                                          : 16,
                                              fontWeight: FontWeight.w500,
                                              color: numberColors,
                                            ),
                                          ),
                                        )
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "OTs Reqested",
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 13
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 14
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 15
                                                      : 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  OTRequestedCount > 0
                                      ? Badge(
                                          alignment:
                                              AlignmentDirectional.topEnd,
                                          backgroundColor: Colors.red,
                                          child: GestureDetector(
                                            onTap: () {},
                                            child: Container(
                                              decoration:
                                                  BoxDecoration(boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ]),
                                              margin: EdgeInsets.all(3),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 5),
                                              child: Text(
                                                OTRequestedCount > 1
                                                    ? "${OTRequestedCount} Requests"
                                                    : "${OTRequestedCount} Request",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: numberColors,
                                                  fontSize: Responsive
                                                          .isMobileSmall(
                                                              context)
                                                      ? 12
                                                      : Responsive.isMobileMedium(
                                                                  context) ||
                                                              Responsive
                                                                  .isMobileLarge(
                                                                      context)
                                                          ? 13
                                                          : Responsive
                                                                  .isTabletPortrait(
                                                                      context)
                                                              ? 14
                                                              : 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade200,
                                            ),
                                          ]),
                                          margin: EdgeInsets.all(3),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          child: Text(
                                            "No Requests",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: numberColors,
                                              fontSize: Responsive
                                                      .isMobileSmall(context)
                                                  ? 12
                                                  : Responsive.isMobileMedium(
                                                              context) ||
                                                          Responsive
                                                              .isMobileLarge(
                                                                  context)
                                                      ? 13
                                                      : Responsive
                                                              .isTabletPortrait(
                                                                  context)
                                                          ? 14
                                                          : 16,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardColros,
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
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
                          ? 25
                          : Responsive.isTabletPortrait(context)
                              ? 28
                              : 30,
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
                        color: textColor,
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
                    SizedBox(height: 4),
                    Text(
                      subtitle,
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
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColors,
                size: Responsive.isMobileSmall(context)
                    ? 22
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 25
                        : Responsive.isTabletPortrait(context)
                            ? 28
                            : 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceContainer(Size size) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Leave Balance',
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
              color: textColor,
            ),
          ),
          SizedBox(height: 15),
          Container(
            height: widget.user["IsSupervisor"] == 1
                ? size.height * 0.25
                : size.height * 0.35,
            child: SingleChildScrollView(
              child: getLeaveTypesWithCounts().length == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: screenHeadingColor),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (int x = 0;
                            x < getLeaveTypesWithCounts().length;
                            x++) ...[
                          _buildLeaveBalanceCard(
                            title:
                                '${getLeaveTypesWithCounts()[x].type} - ${getLeaveTypesWithCounts()[x].totalLeaves}',
                            fullDay: getLeaveTypesWithCounts()[x].fullDayLeaves,
                            halfDay: getLeaveTypesWithCounts()[x].halfDayLeaves,
                            remaining: formatLeavesCount(
                              getLeaveTypesWithCounts()[x].totalLeaves -
                                  (getLeaveTypesWithCounts()[x].halfDayLeaves /
                                          2 +
                                      getLeaveTypesWithCounts()[x]
                                          .fullDayLeaves),
                            ),
                          ),
                          SizedBox(height: 10),
                        ]
                      ],
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLeaveBalanceCard({
    required String title,
    required num fullDay,
    required num halfDay,
    required String remaining,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLeaveBalanceItem(
                  'Full Day\nLeave Taken', fullDay.toString()),
              _buildLeaveBalanceItem(
                  'Half Day\nLeave Taken', halfDay.toString()),
              _buildLeaveBalanceItem(
                'Remaining\nLeave',
                remaining.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 18
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : Responsive.isTabletPortrait(context)
                          ? 25
                          : 25,
              fontWeight: FontWeight.bold,
              color: numberColors,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 11
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 12
                      : Responsive.isTabletPortrait(context)
                          ? 15
                          : 20,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String formatLeavesCount(double leavesCount) {
    String leavesString = leavesCount.toString();
    List<String> parts = leavesString.split('.');

    int wholeNumber = int.parse(parts[0]);
    int decimal = int.parse(parts[1]);

    String fraction = '';

    if (decimal > 0) {
      int gcd = _calculateGCD(decimal, 10);
      fraction = '${decimal ~/ gcd}/${10 ~/ gcd}';
    }

    return (fraction.isNotEmpty && wholeNumber != 0)
        ? '$wholeNumber and $fraction'
        : (wholeNumber == 0 && fraction.isEmpty)
            ? "0"
            : (wholeNumber == 0)
                ? '$fraction'
                : '$wholeNumber';
  }

  int _calculateGCD(int a, int b) {
    if (b == 0) {
      return a;
    } else {
      return _calculateGCD(b, a % b);
    }
  }
}
