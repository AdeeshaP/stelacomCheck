// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:stelacom_check/constants.dart';
// import 'package:stelacom_check/controllers/appstate_controller.dart';
// import 'package:stelacom_check/responsive.dart';
// import 'package:stelacom_check/screens/attendance-dashboard/attendance_dashboard.dart';
// import 'dart:convert';
// import 'package:stelacom_check/screens/home/dashboard.dart';
// import 'package:stelacom_check/screens/profile/profile_home.dart';

// class HomeScreen extends StatefulWidget {
//   HomeScreen({Key? key, required this.index2}) : super(key: key);

//   final int index2;

//   @override
//   _HomeScreen createState() => _HomeScreen();
// }

// class _HomeScreen extends State<HomeScreen>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   late SharedPreferences _storage;
//   Map<String, dynamic>? userObj;
//   String employeeCode = "";
//   final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
//   final GlobalKey<NavigatorState> secondTabNavKey = GlobalKey<NavigatorState>();
//   // final GlobalKey<NavigatorState> thirdTabNavKey = GlobalKey<NavigatorState>();
//   final GlobalKey<NavigatorState> forthTabNavKey = GlobalKey<NavigatorState>();
//   CupertinoTabController? tabController;
//   int ix = 0;
//   String userData = "";
//   late AppStateController appState;

//   @override
//   void setState(fn) {
//     if (mounted) {
//       super.setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     appState = Get.put(AppStateController());
//     getSharedPrefs();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> getSharedPrefs() async {
//     _storage = await SharedPreferences.getInstance();

//     _storage.setBool('userInHomeScreen', true);

//     userData = _storage.getString('user_data')!;
//     employeeCode = _storage.getString('employee_code') ?? "";

//     userObj = jsonDecode(userData);

//     setState(() {
//       ix = widget.index2;
//     });

//     if (mounted) {
//       appState.checkIsSupervsor(userData);
//     }

//     tabController = CupertinoTabController(initialIndex: ix);

//     // getSupervisorLeaveRequests();
//   }

//   // ----------------ADD HERE THE FACE LIVENESS DETECTION KBY-AI PLUGIIN init() method---------------

//   // GET All the leave requests from supervisor

//   // Future<void> getSupervisorLeaveRequests() async {
//   //   Map<String, dynamic> userObj3 = jsonDecode(userData);
//   //   var response = await ApiService.getIndividualSupervisorLeaveRequests(
//   //       userObj3["CustomerId"], userObj3["Id"]);
//   //   var response2 = await ApiService.getGroupSupervisorLeaveRequests(
//   //       userObj3["CustomerId"], userObj3["Id"]);

//   //   if (response.statusCode == 200 &&
//   //       response.body != "null" &&
//   //       response2.statusCode == 200 &&
//   //       response2.body != "null") {
//   //     if (mounted) {
//   //       appState.updateSupervisorRequests(
//   //         jsonDecode(response.body),
//   //         jsonDecode(response2.body),
//   //       );
//   //     }
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final listOfKeys = [
//       firstTabNavKey,
//       secondTabNavKey,
//       // thirdTabNavKey,
//       forthTabNavKey,
//     ];

//     List homeScreenList = [
//       DashboardScreen(index3: widget.index2),
//       AttendanceDashboardScreen(user: userObj, index3: widget.index2),
//       ProfileScreen(user: userObj, index3: widget.index2),
//     ];

//     // ignore: deprecated_member_use
//     return WillPopScope(
//       onWillPop: () async {
//         return !await listOfKeys[tabController!.index].currentState!.maybePop();
//       },
//       child: CupertinoTabScaffold(
//         controller: tabController,
//         tabBar: CupertinoTabBar(
//           backgroundColor: Colors.red.shade50,
//           height: Responsive.isMobileSmall(context)
//               ? 45
//               : Responsive.isMobileMedium(context)
//               ? 50
//               : Responsive.isMobileLarge(context)
//               ? 60
//               : Responsive.isTabletPortrait(context)
//               ? 65
//               : 70,
//           activeColor: numberColors,
//           items: <BottomNavigationBarItem>[
//             BottomNavigationBarItem(
//               activeIcon: Icon(
//                 Icons.window,
//                 size: Responsive.isMobileSmall(context)
//                     ? 30
//                     : Responsive.isMobileMedium(context)
//                     ? 32
//                     : Responsive.isMobileLarge(context)
//                     ? 35
//                     : Responsive.isTabletPortrait(context)
//                     ? 40
//                     : 40,
//                 color: iconColors,
//               ),
//               icon: Icon(
//                 Icons.window,
//                 size: Responsive.isMobileSmall(context)
//                     ? 23
//                     : Responsive.isMobileMedium(context)
//                     ? 25
//                     : Responsive.isMobileLarge(context)
//                     ? 29
//                     : Responsive.isTabletPortrait(context)
//                     ? 35
//                     : 35,
//                 color: Colors.grey[700],
//               ),
//               label: "Dashboard",
//             ),
//             BottomNavigationBarItem(
//               activeIcon: Icon(
//                 Icons.people,
//                 size: Responsive.isMobileSmall(context)
//                     ? 30
//                     : Responsive.isMobileMedium(context)
//                     ? 32
//                     : Responsive.isMobileLarge(context)
//                     ? 35
//                     : Responsive.isTabletPortrait(context)
//                     ? 40
//                     : 40,
//                 color: iconColors,
//               ),
//               icon: Icon(
//                 Icons.people,
//                 size: Responsive.isMobileSmall(context)
//                     ? 23
//                     : Responsive.isMobileMedium(context)
//                     ? 25
//                     : Responsive.isMobileLarge(context)
//                     ? 29
//                     : Responsive.isTabletPortrait(context)
//                     ? 35
//                     : 35,
//                 color: Colors.grey[700],
//               ),
//               label: "Attendance",
//             ),
//             BottomNavigationBarItem(
//               activeIcon: Icon(
//                 Icons.person,
//                 size: Responsive.isMobileSmall(context)
//                     ? 30
//                     : Responsive.isMobileMedium(context)
//                     ? 32
//                     : Responsive.isMobileLarge(context)
//                     ? 35
//                     : Responsive.isTabletPortrait(context)
//                     ? 40
//                     : 40,
//                 color: iconColors,
//               ),
//               icon: Icon(
//                 Icons.person,
//                 size: Responsive.isMobileSmall(context)
//                     ? 23
//                     : Responsive.isMobileMedium(context)
//                     ? 25
//                     : Responsive.isMobileLarge(context)
//                     ? 29
//                     : Responsive.isTabletPortrait(context)
//                     ? 35
//                     : 35,
//                 color: Colors.grey[700],
//               ),
//               label: "Profile",
//             ),
//           ],
//         ),
//         tabBuilder: (context, index) {
//           return CupertinoTabView(
//             navigatorKey: listOfKeys[index],
//             builder: (context) {
//               return homeScreenList[index];
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/controllers/appstate_controller.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/attendance-dashboard/attendance_dashboard.dart';
import 'dart:convert';
import 'package:stelacom_check/screens/home/dashboard.dart';
import 'package:stelacom_check/screens/profile/profile_home.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.index2}) : super(key: key);

  final int index2;

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late SharedPreferences _storage;
  final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> secondTabNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> forthTabNavKey = GlobalKey<NavigatorState>();
  CupertinoTabController? tabController;
  int ix = 0;
  late AppStateController appState;

  @override
  void initState() {
    super.initState();
    // Use Get.find since controller is already initialized in main.dart
    appState = Get.find<AppStateController>();
    getSharedPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    _storage.setBool('userInHomeScreen', true);

    String? userData = _storage.getString('user_data');
    String employeeCode = _storage.getString('employee_code') ?? "";

    if (userData != null) {
      Map<String, dynamic> userObj = jsonDecode(userData);
      
      // Update controller state
      appState.setUserObj(userObj);
      appState.setEmployeeCode(employeeCode);
      appState.checkIsSupervsor(userData);
    }

    // Set initial tab index
    ix = widget.index2;
    tabController = CupertinoTabController(initialIndex: ix);
  }

  @override
  Widget build(BuildContext context) {
    final listOfKeys = [
      firstTabNavKey,
      secondTabNavKey,
      forthTabNavKey,
    ];

    return WillPopScope(
      onWillPop: () async {
        return !await listOfKeys[tabController!.index].currentState!.maybePop();
      },
      child: Obx(() {
        // Only rebuild when userObj changes
        final user = appState.userObj.value;
        
        List homeScreenList = [
          DashboardScreen(index3: widget.index2),
          AttendanceDashboardScreen(user: user, index3: widget.index2),
          ProfileScreen(user: user, index3: widget.index2),
        ];
        
        return CupertinoTabScaffold(
          controller: tabController,
          tabBar: CupertinoTabBar(
            backgroundColor: Colors.red.shade50,
            height: Responsive.isMobileSmall(context)
                ? 45
                : Responsive.isMobileMedium(context)
                    ? 50
                    : Responsive.isMobileLarge(context)
                        ? 60
                        : Responsive.isTabletPortrait(context)
                            ? 65
                            : 70,
            activeColor: numberColors,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.window,
                  size: Responsive.isMobileSmall(context)
                      ? 30
                      : Responsive.isMobileMedium(context)
                          ? 32
                          : Responsive.isMobileLarge(context)
                              ? 35
                              : Responsive.isTabletPortrait(context)
                                  ? 40
                                  : 40,
                  color: iconColors,
                ),
                icon: Icon(
                  Icons.window,
                  size: Responsive.isMobileSmall(context)
                      ? 23
                      : Responsive.isMobileMedium(context)
                          ? 25
                          : Responsive.isMobileLarge(context)
                              ? 29
                              : Responsive.isTabletPortrait(context)
                                  ? 35
                                  : 35,
                  color: Colors.grey[700],
                ),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.people,
                  size: Responsive.isMobileSmall(context)
                      ? 30
                      : Responsive.isMobileMedium(context)
                          ? 32
                          : Responsive.isMobileLarge(context)
                              ? 35
                              : Responsive.isTabletPortrait(context)
                                  ? 40
                                  : 40,
                  color: iconColors,
                ),
                icon: Icon(
                  Icons.people,
                  size: Responsive.isMobileSmall(context)
                      ? 23
                      : Responsive.isMobileMedium(context)
                          ? 25
                          : Responsive.isMobileLarge(context)
                              ? 29
                              : Responsive.isTabletPortrait(context)
                                  ? 35
                                  : 35,
                  color: Colors.grey[700],
                ),
                label: "Attendance",
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(
                  Icons.person,
                  size: Responsive.isMobileSmall(context)
                      ? 30
                      : Responsive.isMobileMedium(context)
                          ? 32
                          : Responsive.isMobileLarge(context)
                              ? 35
                              : Responsive.isTabletPortrait(context)
                                  ? 40
                                  : 40,
                  color: iconColors,
                ),
                icon: Icon(
                  Icons.person,
                  size: Responsive.isMobileSmall(context)
                      ? 23
                      : Responsive.isMobileMedium(context)
                          ? 25
                          : Responsive.isMobileLarge(context)
                              ? 29
                              : Responsive.isTabletPortrait(context)
                                  ? 35
                                  : 35,
                  color: Colors.grey[700],
                ),
                label: "Profile",
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              navigatorKey: listOfKeys[index],
              builder: (context) {
                return homeScreenList[index];
              },
            );
          },
        );
      }),
    );
  }
}
