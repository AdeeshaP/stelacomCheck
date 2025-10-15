import 'dart:convert';
import 'package:stelacom_check/components/utils/dialogs.dart';
import 'package:stelacom_check/screens/attendance-dashboard/flat_toggle_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/providers/appstate_provider.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendacneDashboardScreen extends StatefulWidget {
  final dynamic user;
  final int index3;

  AttendacneDashboardScreen({
    Key? key,
    required this.user,
    required this.index3,
  }) : super(key: key);

  @override
  State<AttendacneDashboardScreen> createState() =>
      _AttendacneDashboardScreenState();
}

class _AttendacneDashboardScreenState extends State<AttendacneDashboardScreen> {
  late SharedPreferences _storage;
  final GlobalKey<NavigatorState> forthTabNavKey = GlobalKey<NavigatorState>();
  DateTime from = DateTime.now().add(new Duration(days: -7));
  DateTime to = DateTime.now();
  bool visitShow = true;
  bool checkinShow = true;
  DateTime dashboardStartDate = DateTime.now().add(new Duration(days: -7));
  DateTime dashboardEndDate = DateTime.now();
  List<dynamic> userActions = [];
  int visitCount = 0;
  int workedDayCount = 0;
  double totalSecondsWorked = 0.0;
  String dashboardDateRange = "";
  List<dynamic> requestOTs = [];
  final GlobalKey<NavigatorState> secondTabNavKey = GlobalKey<NavigatorState>();
  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);

    getSharedPrefs();
    getWorkingHoursForUser();
    dashboardDateRange = Jiffy.parseFromDateTime(dashboardStartDate)
            .format(pattern: "yyyy/MM/dd") +
        " - " +
        Jiffy.parseFromDateTime(dashboardEndDate).format(pattern: "yyyy/MM/dd");
    Future.delayed(Duration.zero, () {
      getUserActivities(dashboardStartDate, dashboardEndDate);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
  }

  Future<void> getWorkingHoursForUser() async {
    _storage = await SharedPreferences.getInstance();

    String userData = _storage.getString('user_data') ?? "";
    if (userData != "") {
      Map<String, dynamic> userObj2 = jsonDecode(userData);

      var response2 = await ApiService.getWorkingHours(userObj2["CustomerId"]);
      if (response2 != null &&
          response2.statusCode == 200 &&
          response2.body != "null") {
        if (mounted) {
          appState.updateUserWorkingHrs(
            jsonDecode(response2.body),
          );
        }
      }
    }
  }

  Future<void> getUserActivities(DateTime from, DateTime to) async {
    showProgressDialog(context);
    print(Jiffy.parseFromDateTime(from).format(pattern: "yyyy-MM-dd"));
    print(Jiffy.parseFromDateTime(to).format(pattern: "yyyy-MM-dd"));

    from = from.add(new Duration(days: 0));
    var response = await ApiService.getActions(
        widget.user["Id"],
        widget.user["CustomerId"],
        Jiffy.parseFromDateTime(from).format(pattern: "yyyy-MM-dd"),
        Jiffy.parseFromDateTime(to).format(pattern: "yyyy-MM-dd"));

    print("response body ${response.body}");
    print("response  ${response}");
    if (response != null && response.statusCode == 200) {
      closeDialog(context);
      List<dynamic> list = jsonDecode(response.body);
      double secondsSum = 0;
      for (var item in list) {
        if (item['TotalSeconds'] != null)
          secondsSum = secondsSum + item['TotalSeconds'];
      }
      if (mounted)
        setState(() {
          userActions = list;
          visitCount = list
              .where((element) => element['AttType'] == 'visit')
              .toList()
              .length;

          final chekinDays = list
              .where((element) => element['AttType'] == 'checkin')
              .toList()
              .map((e) => e['InTimeDate']);
          final distinctChekinDays = [];
          chekinDays.forEach(
            (e) {
              if (!distinctChekinDays.contains(e)) {
                distinctChekinDays.add(e);
              }
            },
          );
          workedDayCount = distinctChekinDays.length;
          totalSecondsWorked = secondsSum;
        });
    } else {
      print("No Data");
      closeDialog(context);
    }
  }

  void toggled(bool value, String type) {
    if (type == 'checkin') {
      setState(() {
        checkinShow = value;
      });
    }
    if (type == 'visit') {
      setState(() {
        visitShow = value;
      });
    }
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

  String? getTotalHoursWorked(double totalSecondsWorked) {
    double remainder = totalSecondsWorked % 3600;
    double hours = (totalSecondsWorked - remainder) / 3600;
    double minute = remainder / 60;
    return hours.truncate().toString() +
        "h " +
        minute.truncate().toString() +
        "m ";
  }

  int getWorkingDays(DateTime from, DateTime to) {
    final workingDays = <DateTime>[];
    final currentDate = from;
    final orderDate = to;

    DateTime indexDate = currentDate;
    while (indexDate.difference(orderDate).inDays != 0) {
      final isWeekendDay = indexDate.weekday == DateTime.saturday ||
          indexDate.weekday == DateTime.sunday;
      if (!isWeekendDay) {
        workingDays.add(indexDate);
      }

      indexDate = indexDate.add(Duration(days: 1));
    }

    return workingDays.length;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Consumer<AppState>(builder: (context, appState, child) {
      return Scaffold(
          key: secondTabNavKey,
          backgroundColor: appBgColor,
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
          body: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                _buildDateSelectors(),
                SizedBox(height: 15),
                _buildSummaryCard(),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: size.width * 0.9,
                  child: SingleChildScrollView(
                    child: Column(
                      children: userActions
                          .where((i) =>
                              (i['AttType'] == 'checkin' && checkinShow) ||
                              (i['AttType'] == 'visit' && visitShow))
                          .toList()
                          .map(
                            (item) => Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 0),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Row(
                                      children: <Widget>[
                                        //--------- Day and Month-----------
            
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  item['MonthName'],
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: Responsive
                                                            .isMobileSmall(
                                                                context)
                                                        ? 10
                                                        : Responsive.isMobileMedium(
                                                                    context) ||
                                                                Responsive
                                                                    .isMobileLarge(
                                                                        context)
                                                            ? 14
                                                            : Responsive
                                                                    .isTabletPortrait(
                                                                        context)
                                                                ? 20
                                                                : 22,
                                                  ),
                                                ),
                                                Text(
                                                  item['Day'],
                                                  style: TextStyle(
                                                    fontSize: Responsive
                                                            .isMobileSmall(
                                                                context)
                                                        ? 16
                                                        : Responsive.isMobileMedium(
                                                                    context) ||
                                                                Responsive
                                                                    .isMobileLarge(
                                                                        context)
                                                            ? 18
                                                            : Responsive
                                                                    .isTabletPortrait(
                                                                        context)
                                                                ? 20
                                                                : 23,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.red[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
            
                                        Expanded(
                                          flex: 9,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              //------------- Checkin or Visit-------------
            
                                              Column(
                                                children: [
                                                  Text(
                                                    item['AttType'] == 'visit'
                                                        ? "Visit"
                                                        : "Check In",
                                                    style: TextStyle(
                                                      fontSize: item[
                                                                  'AttType'] ==
                                                              'visit'
                                                          ? Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 11
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 12
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 15
                                                                      : 20
                                                          : Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 11
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 12
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 16
                                                                      : 19,
                                                      // fontWeight:
                                                      //     FontWeight.w400,
                                                      color: Colors.grey[600],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  SizedBox(height: 3),
                                                  Container(
                                                      width: Responsive
                                                              .isMobileSmall(
                                                                  context)
                                                          ? 60
                                                          : Responsive.isMobileMedium(
                                                                      context) ||
                                                                  Responsive
                                                                      .isMobileLarge(
                                                                          context)
                                                              ? 70
                                                              : Responsive
                                                                      .isTabletPortrait(
                                                                          context)
                                                                  ? 90
                                                                  : 100,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFF4CAF50)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        item['InTimeValue'],
                                                        style: TextStyle(
                                                          fontSize: Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 11
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 15
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 18
                                                                      : 22,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Color(0xFF4CAF50),
                                                        ),
                                                      )),
                                                ],
                                              ),
                                              //------------- Checkout or Visit------------------
            
                                              item['AttType'] != 'visit'
                                                  ? Column(
                                                      children: [
                                                        Text(
                                                          "Check Out",
                                                          style: TextStyle(
                                                            fontSize: Responsive
                                                                    .isMobileSmall(
                                                                        context)
                                                                ? 11
                                                                : Responsive.isMobileMedium(
                                                                            context) ||
                                                                        Responsive.isMobileLarge(
                                                                            context)
                                                                    ? 12
                                                                    : Responsive.isTabletPortrait(
                                                                            context)
                                                                        ? 16
                                                                        : 19,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        SizedBox(height: 3),
                                                        Container(
                                                          width: Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 60
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 70
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 90
                                                                      : 100,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration: BoxDecoration(
                                                              color: item['OutTimeValue'] ==
                                                                      '-'
                                                                  ? Color(0xFFD32F2F)
                                                                      .withOpacity(
                                                                          0.1)
                                                                  : Color(0xFF4CAF50)
                                                                      .withOpacity(
                                                                          0.1),
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          8))),
                                                          child: Text(
                                                            item[
                                                                'OutTimeValue'],
                                                            style: TextStyle(
                                                              fontSize: Responsive
                                                                      .isMobileSmall(
                                                                          context)
                                                                  ? 11
                                                                  : Responsive.isMobileMedium(
                                                                              context) ||
                                                                          Responsive.isMobileLarge(
                                                                              context)
                                                                      ? 15
                                                                      : 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: item['OutTimeValue'] ==
                                                                      '-'
                                                                  ? Color(
                                                                      0xFFD32F2F)
                                                                  : Color(
                                                                      0xFF4CAF50),
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(
                                                      width: Responsive
                                                              .isMobileSmall(
                                                                  context)
                                                          ? 60
                                                          : Responsive.isMobileMedium(
                                                                      context) ||
                                                                  Responsive
                                                                      .isMobileLarge(
                                                                          context)
                                                              ? 70
                                                              : Responsive
                                                                      .isTabletPortrait(
                                                                          context)
                                                                  ? 90
                                                                  : 100,
                                                    ),
                                              item['AttType'] != 'visit'
                                                  //------------ Time Spent------------
                                                  ? Column(
                                                      children: [
                                                        Text(
                                                          "Time Spent",
                                                          style: TextStyle(
                                                            fontSize: Responsive
                                                                    .isMobileSmall(
                                                                        context)
                                                                ? 11
                                                                : Responsive.isMobileMedium(
                                                                            context) ||
                                                                        Responsive.isMobileLarge(
                                                                            context)
                                                                    ? 12
                                                                    : Responsive.isTabletPortrait(
                                                                            context)
                                                                        ? 16
                                                                        : 19,
                                                            // fontWeight:
                                                            //     FontWeight
                                                            //         .w400,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        SizedBox(height: 3),
                                                        Container(
                                                          width: Responsive
                                                                  .isMobileSmall(
                                                                      context)
                                                              ? 80
                                                              : Responsive.isMobileMedium(
                                                                          context) ||
                                                                      Responsive
                                                                          .isMobileLarge(
                                                                              context)
                                                                  ? 90
                                                                  : Responsive.isTabletPortrait(
                                                                          context)
                                                                      ? 100
                                                                      : 150,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: item['TimeSpent'] ==
                                                                    '-'
                                                                ? Color(0xFFD32F2F)
                                                                    .withOpacity(
                                                                        0.1)
                                                                : Color(0xFF4CAF50)
                                                                    .withOpacity(
                                                                        0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  8),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            item['TimeSpent'],
                                                            style: TextStyle(
                                                              fontSize: Responsive
                                                                      .isMobileSmall(
                                                                          context)
                                                                  ? 11
                                                                  : Responsive.isMobileMedium(
                                                                              context) ||
                                                                          Responsive.isMobileLarge(
                                                                              context)
                                                                      ? 15
                                                                      : Responsive.isTabletPortrait(
                                                                              context)
                                                                          ? 18
                                                                          : 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: item['TimeSpent'] ==
                                                                      '-'
                                                                  ? Color(
                                                                      0xFFD32F2F)
                                                                  : Color(
                                                                      0xFF4CAF50),
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(
                                                      width: Responsive
                                                              .isMobileSmall(
                                                                  context)
                                                          ? 80
                                                          : Responsive.isMobileMedium(
                                                                      context) ||
                                                                  Responsive
                                                                      .isMobileLarge(
                                                                          context)
                                                              ? 90
                                                              : Responsive
                                                                      .isTabletPortrait(
                                                                          context)
                                                                  ? 100
                                                                  : 150,
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10)
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ));
    });
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
                      from = picked1!;
                      getUserActivities(from, to);
                      print("from $from");
                      print("to $to");
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
                          Jiffy.parseFromDateTime(from)
                              .format(pattern: "yyyy/MM/dd"),
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 20
                                        : 21,
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
                      to = picked2!;
                      getUserActivities(from, to);

                      print("from $from");
                      print("to $to");
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
                          Jiffy.parseFromDateTime(to)
                              .format(pattern: "yyyy/MM/dd"),
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                        ? 20
                                        : 21,
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

  Widget _buildSummaryCard() {
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
        padding: EdgeInsets.symmetric(vertical: 11, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontSize: Responsive.isMobileSmall(context)
                    ? 18
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 20
                        : Responsive.isTabletPortrait(context)
                            ? 22
                            : 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem('Working Days',
                    '${getWorkingDays(from, to) + 1}', numberColors),
                _buildSummaryItemWithToggled(
                    'Days Present', '${workedDayCount}', 'checkin'),
                _buildSummaryItem(
                    'Hours Worked',
                    '${getTotalHoursWorked(totalSecondsWorked)!}',
                    numberColors),
              ],
            ),
            SizedBox(height: 18),
            Row(
              children: [
                _buildSummaryItemWithToggled(
                    'Visits', '${visitCount}', 'visit'),
                _buildSummaryItem(
                    'Days Absent',
                    '${(getWorkingDays(from, to) + 1 - workedDayCount).toString()}',
                    numberColors),
                _buildSummaryItem(
                    'Working Hours',
                    '${appState.propertyVariables.length > 0 ? appState.propertyVariables[0]["Value"] : ""}',
                    numberColors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.isMobileSmall(context)
                  ? 12
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 13
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItemWithToggled(String label, String value, String type) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.isMobileSmall(context)
                  ? 12
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 13
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
          ),
          SizedBox(height: 5),
          FlatToggleButton(
            buttonText: value,
            toggled: toggled,
            type: type,
          ),
        ],
      ),
    );
  }
}
