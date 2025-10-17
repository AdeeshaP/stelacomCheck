import 'dart:async';
import 'package:stelacom_check/screens/Inventory-Recall/recall_orders_screen.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/main.dart';
import 'package:stelacom_check/screens/Inventory-Scan/netsuite_device_verification.dart';
import 'package:stelacom_check/screens/Visits/capture_screen.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkin_capture_screen.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkout_capture_screen.dart';
import 'package:stelacom_check/app-services/location_service.dart';
import 'package:stelacom_check/screens/Inventory-GRN/transfer_orders_screen.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/location_restrictions/location_restrictions.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/providers/appstate_provider.dart';
import 'package:stelacom_check/providers/loxcation_provider.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/dialogs.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_version_update/app_version_update.dart';

class ModifiedDashboard extends StatefulWidget {
  ModifiedDashboard({super.key, required this.index3});

  final int index3;
  @override
  State<ModifiedDashboard> createState() => _ModifiedDashboardState();
}

class _ModifiedDashboardState extends State<ModifiedDashboard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  Map<String, dynamic>? lastCheckIn;
  String workedTime = "";
  late DateTime? lastCheckInTime;
  String employeeCode = "";
  VersionStatus? versionstatus;
  DateTime? NOTIFCATION_POPUP_DISPLAY_TIME;
  String inTime = "";
  String outTime = "";
  String attendanceId = "";
  final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
  late AppState appState;
  String formattedDuration = "";
  String formattedDate = "";
  String formattedInTime = "";
  String formattedOutTime = "";
  late AnimationController _pulseController;
  late AnimationController _buttonController;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);

    WidgetsBinding.instance.addObserver(this);
    getSharedPrefs();

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      appState.updateOfficeDate(
        Jiffy.now().format(pattern: "EEEE") + ", " + Jiffy.now().yMMMMd,
      );
      appState.updateOfficeTime(Jiffy.now().format(pattern: "hh:mm:ss a"));
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      updateWorkTime();
    });

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    // await getVersionStatus();

    _storage = await SharedPreferences.getInstance();
    String? userData = await _storage.getString('user_data');
    employeeCode = await _storage.getString('employee_code') ?? "";

    userObj = jsonDecode(userData!);

    LocationValidationResult result =
        await LocationValidationService.validateLocationForInventoryScan(
          context,
        );

    print(
      "Location Validation Result: isValid=${result.isValid}, description=${result.description}",
    );

    if (mounted) appState.updateOfficeAddress(userObj!["OfficeAddress"]);

    if (mounted) {
      appState.checkIsDeleted(userData);
    }

    await loadLastCheckIn();

    // if (versionstatus != null) {
    //   Future.delayed(Duration(seconds: 2), () async {
    //     _verifyVersion();
    //   });
    // }
  }

  // --------GET App Version Status--------------//
  Future<VersionStatus> getVersionStatus() async {
    NewVersionPlus? newVersion = NewVersionPlus(
      androidId: "com.aura.icheckapp",
    );

    VersionStatus? status = await newVersion.getVersionStatus();
    setState(() {
      versionstatus = status;
    });
    print(newVersion);

    // if (versionstatus != null) {
    return versionstatus!;
    // }
  }

  // SIDE MENU BAR UI
  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out',
  ];

  // --------- Side Menu Bar Navigation ---------- //
  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HelpScreen(index3: 0);
          },
        ),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AboutUs(index3: 0);
          },
        ),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ContactUs(index3: 0);
          },
        ),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return TermsAndConditions(index3: 0);
          },
        ),
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

  // VERSION UPDATE

  Future<void> _verifyVersion() async {
    AppVersionUpdate.checkForUpdates(
      appleId: '1581265618',
      playStoreId: 'com.stelacom.icheck',
      country: 'us',
    ).then((result) async {
      if (result.canUpdate!) {
        await AppVersionUpdate.showAlertUpdate(
          appVersionResult: result,
          context: context,
          backgroundColor: Colors.grey[100],
          title: '      Update Available',
          titleTextStyle: TextStyle(
            color: normalTextColor,
            fontWeight: FontWeight.w600,
            fontSize:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 24
                : Responsive.isTabletPortrait(context)
                ? 28
                : 27,
          ),
          content:
              "You're currently using iCheck ${versionstatus!.localVersion}, but new version ${result.storeVersion} is now available on the Play Store. Update now for the latest features!",
          contentTextStyle: TextStyle(
            color: normalTextColor,
            fontWeight: FontWeight.w400,
            fontSize:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 16
                : Responsive.isTabletPortrait(context)
                ? 25
                : 24,
            height: 1.5,
          ),
          updateButtonText: 'UPDATE',
          updateTextStyle: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 14
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 16
                : Responsive.isTabletPortrait(context)
                ? 18
                : 18,
          ),
          updateButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
            backgroundColor: WidgetStateProperty.all(Colors.green[800]),
            minimumSize: Responsive.isMobileSmall(context)
                ? WidgetStateProperty.all(Size(90, 40))
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? WidgetStateProperty.all(Size(100, 45))
                : Responsive.isTabletPortrait(context)
                ? WidgetStateProperty.all(Size(160, 60))
                : WidgetStateProperty.all(Size(140, 50)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            ),
          ),
          cancelButtonText: 'NO THANKS',
          cancelButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(actionBtnTextColor),
            backgroundColor: WidgetStateProperty.all(Colors.red[800]),
            minimumSize: Responsive.isMobileSmall(context)
                ? WidgetStateProperty.all(Size(90, 40))
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? WidgetStateProperty.all(Size(100, 45))
                : Responsive.isTabletPortrait(context)
                ? WidgetStateProperty.all(Size(160, 60))
                : WidgetStateProperty.all(Size(140, 50)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            ),
          ),
          cancelTextStyle: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 14
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 16
                : Responsive.isTabletPortrait(context)
                ? 18
                : 18,
          ),
        );
      }
    });
  }

  // MOVE TO TURN ON DEVICE LOCATION

  void switchOnLocation() async {
    closeDialog(context);
    bool ison = await Geolocator.isLocationServiceEnabled();
    if (!ison) {
      await Geolocator.openLocationSettings();
    }
  }

  bool get isCheckedIn =>
      lastCheckIn != null && lastCheckIn!["OutTime"] == null;

  // Update your main build method to use the new widgets:
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        SystemNavigator.pop();
      },
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Scaffold(
            key: firstTabNavKey,
            backgroundColor: screenbgcolor,
            appBar: AppBar(
              // Your existing AppBar code
              backgroundColor: appbarBgColor,
              shadowColor: Colors.grey[100],
              toolbarHeight:
                  Responsive.isMobileSmall(context) ||
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
                  // Your existing title row code
                  SizedBox(
                    width:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 90.0
                        : Responsive.isTabletPortrait(context)
                        ? 150
                        : 170,
                    height:
                        Responsive.isMobileSmall(context) ||
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
                  SizedBox(
                    width:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 90.0
                        : Responsive.isTabletPortrait(context)
                        ? 150
                        : 170,
                    height:
                        Responsive.isMobileSmall(context) ||
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
                          horizontal:
                              Responsive.isMobileSmall(context) ||
                                  Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 15
                              : 20,
                          vertical:
                              Responsive.isMobileSmall(context) ||
                                  Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 5
                              : 10,
                        ),
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
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 2
                        : Responsive.isTabletPortrait(context)
                        ? 20
                        : 20,
                  ),
                  _buildWelcomeSection(size), // New welcome section
                  SizedBox(
                    height:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                        ? 40
                        : 40,
                  ),
                  _buildActionButtons(size), // Redesigned action buttons
                  SizedBox(
                    height:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                        ? 40
                        : 40,
                  ),
                  _buildWorkTimeCard(size), // Keep existing work time card
                  SizedBox(
                    height:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                        ? 40
                        : 40,
                  ),
                  _buildProfileCard(size, isCheckedIn),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Remove the time card entirely and replace with a cleaner welcome section
  Widget _buildWelcomeSection(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        margin: EdgeInsets.only(top: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C00).withOpacity(0.1),
              Color(0xFFFF8C00).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFFFF8C00).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width:
                  Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 60
                  : 90,
              height:
                  Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 60
                  : 90,
              decoration: BoxDecoration(
                color: Color(0xFFFF8C00),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF8C00).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.business_center,
                color: Colors.white,
                size: Responsive.isMobileSmall(context)
                    ? 30
                    : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                    ? 30
                    : Responsive.isTabletPortrait(context)
                    ? 45
                    : 45,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userObj != null
                        ? userObj!['LastName'] != null
                              ? 'Welcome, ${userObj!["FirstName"]}!'
                              : 'Welcome!'
                        : "Welcome!",
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 20
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 22
                          : Responsive.isTabletPortrait(context)
                          ? 30
                          : 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ready to manage your work day?',
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 14
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 16
                          : Responsive.isTabletPortrait(context)
                          ? 25
                          : 25,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
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

  // Redesigned action buttons with better layout (2x2 grid + 1 bottom button)
  Widget _buildActionButtons(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Top row - Main actions (Check In/Out)
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Check In',
                  icon: Icons.login_outlined,
                  isEnabled:
                      (lastCheckIn == null || lastCheckIn!["OutTime"] != null),
                  onPressed: () {
                    if (lastCheckIn == null ||
                        lastCheckIn!["OutTime"] != null) {
                      _handleCheckIn();
                    }
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Check Out',
                  icon: Icons.logout_outlined,
                  isEnabled:
                      (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
                  onPressed: () {
                    if (lastCheckIn != null &&
                        lastCheckIn!["OutTime"] == null) {
                      _handleCheckOut();
                    }
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Middle row - Secondary actions
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Visit',
                  icon: Icons.location_on_outlined,
                  isEnabled:
                      (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
                  onPressed: () {
                    if (lastCheckIn != null &&
                        lastCheckIn!["OutTime"] == null) {
                      _handleVisit();
                    }
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Inventory Scan',
                  icon: Icons.qr_code_scanner_outlined,
                  isEnabled:
                      (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
                  onPressed: () {
                    if (lastCheckIn != null &&
                        lastCheckIn!["OutTime"] == null) {
                      _handleInventoryScan();
                    }
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Bottom row - Additional action (centered, smaller width)
          // Container(
          //   width: size.width * 0.6,
          //   child: _buildSecondaryActionButton(
          //     context: context,
          //     size: size,
          //     label: 'Inventory GRN',
          //     icon: Icons.inventory_outlined,
          //     isEnabled:
          //         (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
          //     onPressed: () {
          //       // Handle GRN action
          //       _handleInventoryGRN();
          //     },
          //   ),
          // ),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Inventory GRN',
                  icon: Icons.inventory_outlined,
                  isEnabled:
                      (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
                  onPressed: () {
                    _handleInventoryGRN();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSecondaryActionButton(
                  context: context,
                  size: size,
                  label: 'Inventory Recall',
                  icon: Icons.inventory_2_outlined,
                  isEnabled:
                      (lastCheckIn != null && lastCheckIn!["OutTime"] == null),
                  onPressed: () {
                    _handleInventoryRecall();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Secondary action buttons with lighter design
  Widget _buildSecondaryActionButton({
    required BuildContext context,
    required Size size,
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      height: Responsive.isMobileSmall(context)
          ? 60
          : Responsive.isMobileMedium(context) ||
                Responsive.isMobileLarge(context)
          ? 65
          : Responsive.isTabletPortrait(context)
          ? 100
          : 100,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          icon,
          size: Responsive.isMobileSmall(context)
              ? 20
              : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
              ? 22
              : Responsive.isTabletPortrait(context)
              ? 45
              : 45,
          color: isEnabled ? Colors.white : Colors.grey[400],
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 14
                : Responsive.isMobileMedium(context)
                ? 16
                : Responsive.isMobileLarge(context)
                ? 16
                : Responsive.isTabletPortrait(context)
                ? 25
                : 25,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.white : Colors.grey[400],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Color(0xFFFF8C00) : Colors.grey[300],
          foregroundColor: isEnabled ? Colors.white : Colors.grey[400],
          elevation: 0,
          side: BorderSide(
            color: isEnabled
                ? Color(0xFFFF8C00).withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Extract your existing logic into these helper methods for cleaner code
  void _handleCheckIn() {
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          if (userObj!['EnableLocation'] > 0) {
            if (userObj!['EnableLocationRestriction'] == 1) {
              _storage.setString('Action', 'checkin');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => LocationRestrictionState(),
                    child: ValidateLocation(widget.index3),
                  ),
                ),
              );
            } else {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => AppState(),
                    child: CheckInCapture(),
                  ),
                ),
              );
            }
          } else {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => AppState(),
                  child: CheckInCapture(),
                ),
              ),
            );
          }
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleCheckOut() {
    // Your existing check out logic here
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          if (userObj!['EnableLocation'] > 0) {
            if (userObj!['EnableLocationRestriction'] == 1) {
              _storage.setString('Action', 'checkout');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => LocationRestrictionState(),
                    child: ValidateLocation(widget.index3),
                  ),
                ),
              );
            } else {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (context) => AppState(),
                    child: CheckoutCapture(),
                  ),
                ),
              );
            }
          } else {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => AppState(),
                  child: CheckoutCapture(),
                ),
              ),
            );
          }
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleVisit() {
    // Your existing visit logic here
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (context) => AppState(),
                child: VisitCapture(),
              ),
            ),
          );
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleInventoryScan() {
    // Your existing inventory scan logic here
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) async {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          LocationValidationResult result =
              await LocationValidationService.validateLocationForInventoryScan(
                context,
              );
          if (result.isValid) {
            // Navigator.of(context, rootNavigator: true).push(
            //   MaterialPageRoute(
            //     builder: (context) => EnhancedBarcodeScannerScreen(
            //       index: widget.index3,
            //       locationDescription: result.description!,
            //     ),
            //   ),
            // );
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => NetsuiteDeviceItemScanScreen(
                  locationDescription: result.description!,
                  index: widget.index3,
                ),
              ),
            );
          }
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleInventoryGRN() {
    // Your existing inventory scan logic here
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) async {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => TransferOrdersScreen(index: widget.index3),
            ),
          );
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleInventoryRecall() {
    // Your existing inventory scan logic here
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) async {
      if (userObj!['Deleted'] == 0) {
        if (serviceEnabled) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) =>
                  RecallTransferOrdersScreen(index: widget.index3),
            ),
          );
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomErrorDialog(
        title: 'Location Service Disabled',
        message: 'Please enable location service before continuing.',
        onOkPressed: switchOnLocation,
        iconData: Icons.error_outline,
      ),
    );
  }

  void _showInactiveUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomErrorDialog(
        title: 'Inactive User',
        message:
            'This user has been deactivated and access is restricted. Please contact the system administrator.',
        onOkPressed: () => Navigator.of(context).pop(),
        iconData: Icons.no_accounts_sharp,
      ),
    );
  }

  Widget _buildWorkTimeCard(Size size) {
    return Container(
      width: isCheckedIn ? size.width * 0.6 : size.width * 0.75,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Work Time Icon - Changed to a more neutral color
          Expanded(
            flex: 3,
            child: Container(
              height:
                  Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 50
                  : 80,
              width:
                  Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 50
                  : 80,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCheckedIn
                    ? Color(0xFFFF8C00).withOpacity(0.1)
                    : Color(0xFF9CA3AF).withOpacity(
                        0.2,
                      ), // Green when active, gray when inactive
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time,
                color: isCheckedIn ? Color(0xFFFF8C00) : Color(0xFF9CA3AF),
                size: Responsive.isMobileSmall(context)
                    ? 24
                    : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                    ? 25
                    : Responsive.isTabletPortrait(context)
                    ? 45
                    : 45,
              ),
            ),
          ),

          Expanded(child: SizedBox(), flex: 1),
          // Work Time Info
          Expanded(
            flex: isCheckedIn ? 7 : 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Time',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 17
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 19
                        : Responsive.isTabletPortrait(context)
                        ? 30
                        : 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? workedTime == "Not checked in yet"
                              ? 16
                              : 20
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? workedTime == "Not checked in yet"
                              ? 19
                              : 23
                        : Responsive.isTabletPortrait(context)
                        ? workedTime == "Not checked in yet"
                              ? 22
                              : 30
                        : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: workedTime == "Not checked in yet" ? 0 : 1,
                  ),
                  child: Text(
                    workedTime,
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? workedTime == "Not checked in yet"
                                ? 16
                                : 20
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? workedTime == "Not checked in yet"
                                ? 19
                                : 23
                          : Responsive.isTabletPortrait(context)
                          ? workedTime == "Not checked in yet"
                                ? 22
                                : 30
                          : 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Removed the duplicate "Active" status badge from here
        ],
      ),
    );
  }

  Widget _buildProfileCard(Size size, bool isCheckedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image with Status Ring
            Stack(
              children: [
                Container(
                  width:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 80
                      : Responsive.isTabletPortrait(context)
                      ? 100
                      : 100,
                  height:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 80
                      : Responsive.isTabletPortrait(context)
                      ? 100
                      : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appState.isDeactivated
                          ? Colors.red
                          : isCheckedIn
                          ? Colors.green
                          : Color(0xFF9CA3AF),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (appState.isDeactivated
                                    ? Colors.red
                                    : isCheckedIn
                                    ? Color(0xFF10B981)
                                    : Color(0xFF9CA3AF))
                                .withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: userObj != null && userObj!["ProfileImage"] != null
                        ? userObj!["ProfileImage"] !=
                                  "https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=None"
                              ? Image.network(
                                  userObj!["ProfileImage"],
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF6B7280),
                                            Color(0xFF9CA3AF),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6B7280),
                                        Color(0xFF9CA3AF),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                )
                        : Image.network(
                            "https://www.pngall.com/wp-content/uploads/5/User-Profile-PNG.png",
                          ),
                  ),
                ),

                // Status indicator dot
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: appState.isDeactivated
                          ? Colors.red
                          : isCheckedIn
                          ? Colors.green
                          : Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: size.width * 0.1),

            // User Info - Keep only this status indicator
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userObj != null
                        ? userObj!['LastName'] != null
                              ? userObj!["FirstName"] +
                                    " " +
                                    userObj!["LastName"]
                              : userObj!['LastName']
                        : "",
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 18
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 20
                          : Responsive.isTabletPortrait(context)
                          ? 30
                          : 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: appState.isDeactivated
                              ? Colors.red
                              : isCheckedIn
                              ? Color(0xFF10B981)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        appState.isDeactivated
                            ? 'Inactive'
                            : isCheckedIn
                            ? 'Available'
                            : 'Not Available',
                        style: TextStyle(
                          fontSize: Responsive.isMobileSmall(context)
                              ? 14
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 16
                              : Responsive.isTabletPortrait(context)
                              ? 25
                              : 25,
                          color: appState.isDeactivated
                              ? Colors.red
                              : isCheckedIn
                              ? Color(0xFF10B981)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GET the status of  the last event type (checkin or CheckoutCapture)

  void updateWorkTime() {
    if (lastCheckIn != null && lastCheckIn!["OutTime"] == null) {
      lastCheckInTime = DateTime.parse(lastCheckIn!["InTime"]);
      Duration duration = DateTime.now().difference(lastCheckInTime!);
      if (!mounted) return;

      setState(() {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
        workedTime =
            "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      });
    } else {
      workedTime = "Not checked in yet";
    }
  }

  // LOAD LAST CHECKIN

  Future<void> loadLastCheckIn() async {
    showProgressDialog(context);
    String userId = userObj!['Id'];
    String customerId = userObj!['CustomerId'];

    var response = await ApiService.getTodayCheckInCheckOut(userId, customerId);
    closeDialog(context);
    if (response != null && response.statusCode == 200) {
      dynamic item = jsonDecode(response.body);
      print("item $item");

      if (item != null) {
        if (item["enrolled"] == 'pending' || item["enrolled"] == null) {
          await _storage.clear();
          while (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MyApp(_storage);
              },
            ),
          );
        } else if (item["Data"] == 'Yes') {
          lastCheckIn = item;
          _storage.setString('last_check_in', jsonEncode(item));
        }
      }
    }
  }

  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = (duration.inMinutes % 60);
    int seconds = (duration.inSeconds % 60);

    String formattedDuration = '';

    if (hours > 0) {
      formattedDuration += '${hours.toString().padLeft(2, '0')} hr ';
    }

    if (minutes > 0) {
      formattedDuration += '${minutes.toString().padLeft(2, '0')} min ';
    }

    if (seconds > 0 || (hours == 0 && minutes == 0)) {
      formattedDuration += '${seconds.toString().padLeft(2, '0')} sec';
    }

    return formattedDuration.trim();
  }

  void noHandler() {
    closeDialog(context);
  }

  // LOAD USER DATA

  Future<void> loadUserData() async {
    showProgressDialog(context);
    var response = await ApiService.verifyUserWithEmpCode(employeeCode);
    closeDialog(context);
    if (response != null &&
        response.statusCode == 200 &&
        response.body == "NoRecordsFound") {
      await _storage.clear();
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MyApp(_storage);
          },
        ),
      );
    } else if (response != null && response.statusCode == 200) {
      userObj = jsonDecode(response.body);

      _storage.setString('user_data', response.body);
      String? lastCheckInData = _storage.getString('last_check_in');
      if (lastCheckInData == null) {
        await loadLastCheckIn();
      } else {
        lastCheckIn = jsonDecode(lastCheckInData);
      }
    }
  }

  int calculateDayDifference(DateTime date) {
    DateTime now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
