import 'dart:async';
import 'package:get/get.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/controllers/appstate_controller.dart';
import 'package:stelacom_check/main.dart';
import 'package:stelacom_check/screens/Inventory-Scan/netsuite_device_barcodes_scan.dart';
import 'package:stelacom_check/screens/Visits/capture_screen.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkin_capture_screen.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkout_capture_screen.dart';
import 'package:stelacom_check/app-services/location_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/location_restrictions/location_restrictions.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/dialogs.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key, required this.index3});

  final int index3;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late SharedPreferences _storage;
  VersionStatus? versionstatus;
  DateTime? NOTIFCATION_POPUP_DISPLAY_TIME;
  String inTime = "";
  String outTime = "";
  String attendanceId = "";
  final GlobalKey<NavigatorState> firstTabNavKey = GlobalKey<NavigatorState>();
  late AppStateController appState;
  late AnimationController _pulseController;
  late AnimationController _buttonController;
  late LocationValidationResult result;
  DateTime? lastCheckInTime;

  @override
  void initState() {
    super.initState();
    appState = Get.find<AppStateController>();

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
    _storage = await SharedPreferences.getInstance();
    String? userData = await _storage.getString('user_data');
    String empCode = await _storage.getString('employee_code') ?? "";

    appState.setEmployeeCode(empCode);

    if (userData != null) {
      Map<String, dynamic> userObj = jsonDecode(userData);
      appState.setUserObj(userObj);
      appState.updateOfficeAddress(userObj["OfficeAddress"]);
      appState.checkIsDeleted(userData);
    }

    await loadLastCheckIn();
  }

  Future<VersionStatus> getVersionStatus() async {
    NewVersionPlus? newVersion = NewVersionPlus(
      androidId: "com.aura.icheckapp",
    );

    VersionStatus? status = await newVersion.getVersionStatus();
    versionstatus = status;
    print(newVersion);
    return versionstatus!;
  }

  List<String> _getMenuOptions() {
    return ['Help', 'About Us', 'Contact Us', 'T & C', 'Log Out'];
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final options = _getMenuOptions();
    // Handle navigation using GetX
    if (choice == options[0]) {
      Get.to(() => HelpScreen(index3: widget.index3));
    } else if (choice == options[1]) {
      Get.to(() => AboutUs(index3: widget.index3));
    } else if (choice == options[2]) {
      Get.to(() => ContactUs(index3: widget.index3));
    } else if (choice == options[3]) {
      Get.to(() => TermsAndConditions(index3: widget.index3));
    } else if (choice == options[4]) {
      LogoutService.logoutWithOptions(context);
    }
  }

  void switchOnLocation() async {
    closeDialog(context);
    bool ison = await Geolocator.isLocationServiceEnabled();
    if (!ison) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: firstTabNavKey,
        backgroundColor: screenbgcolor,
        appBar: AppBar(
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
          title: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  child: appState.userObj.value != null
                      ? CachedNetworkImage(
                          imageUrl:
                              appState.userObj.value!['CompanyProfileImage'],
                          placeholder: (context, url) => Text("..."),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      : Text(""),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (choice) => _handleMenuAction(choice, context),
              itemBuilder: (BuildContext context) {
                return _getMenuOptions().map((String choice) {
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
              _buildWelcomeSection(size),
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
              _buildActionButtons(size),
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
              _buildWorkTimeCard(size),
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
              _buildProfileCard(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Size size) {
    return Obx(
      () => Padding(
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
                      appState.userObj.value != null
                          ? appState.userObj.value!['LastName'] != null
                                ? 'Welcome, ${appState.userObj.value!["FirstName"]}!'
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
      ),
    );
  }

  Widget _buildActionButtons(Size size) {
    return Obx(
      () => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryActionButton(
                    context: context,
                    size: size,
                    label: 'Check In',
                    icon: Icons.login_outlined,
                    isEnabled:
                        (appState.lastCheckIn.value == null ||
                        appState.lastCheckIn.value!["OutTime"] != null),
                    onPressed: () {
                      if (appState.lastCheckIn.value == null ||
                          appState.lastCheckIn.value!["OutTime"] != null) {
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
                        (appState.lastCheckIn.value != null &&
                        appState.lastCheckIn.value!["OutTime"] == null),
                    onPressed: () {
                      if (appState.lastCheckIn.value != null &&
                          appState.lastCheckIn.value!["OutTime"] == null) {
                        _handleCheckOut();
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryActionButton(
                    context: context,
                    size: size,
                    label: 'Visit',
                    icon: Icons.location_on_outlined,
                    isEnabled:
                        (appState.lastCheckIn.value != null &&
                        appState.lastCheckIn.value!["OutTime"] == null),
                    onPressed: () {
                      if (appState.lastCheckIn.value != null &&
                          appState.lastCheckIn.value!["OutTime"] == null) {
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
                        (appState.lastCheckIn.value != null &&
                        appState.lastCheckIn.value!["OutTime"] == null),
                    onPressed: () {
                      if (appState.lastCheckIn.value != null &&
                          appState.lastCheckIn.value!["OutTime"] == null) {
                        _handleInventoryScan();
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryActionButton(
                    context: context,
                    size: size,
                    label: 'Inventory GRN',
                    icon: Icons.inventory_outlined,
                    isEnabled: false,
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
                    isEnabled: false,
                    onPressed: () {
                      _handleInventoryRecall();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  void _handleCheckIn() {
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (appState.userObj.value!['Deleted'] == 0) {
        if (serviceEnabled) {
          if (appState.userObj.value!['EnableLocation'] > 0) {
            if (appState.userObj.value!['EnableLocationRestriction'] == 1) {
              _storage.setString('Action', 'checkin');
              Get.to(() => ValidateLocationRestrictionsScreen(widget.index3));
            } else {
              Get.to(() => CheckInCapture());
            }
          } else {
            Get.to(() => CheckInCapture());
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
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (appState.userObj.value!['Deleted'] == 0) {
        if (serviceEnabled) {
          if (appState.userObj.value!['EnableLocation'] > 0) {
            if (appState.userObj.value!['EnableLocationRestriction'] == 1) {
              _storage.setString('Action', 'checkout');
              Get.to(() => ValidateLocationRestrictionsScreen(widget.index3));
            } else {
              Get.to(() => CheckoutCapture());
            }
          } else {
            Get.to(() => CheckoutCapture());
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
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) {
      if (appState.userObj.value!['Deleted'] == 0) {
        if (serviceEnabled) {
          Get.to(() => VisitCapture());
        } else {
          _showLocationServiceDialog();
        }
      } else {
        _showInactiveUserDialog();
      }
    });
  }

  void _handleInventoryScan() {
    Geolocator.isLocationServiceEnabled().then((bool serviceEnabled) async {
      if (appState.userObj.value!['Deleted'] == 0) {
        if (serviceEnabled) {
          result =
              await LocationValidationService.validateLocationForInventoryScan(
                context,
              );

          print(
            "Location Validation Result: isValid=${result.isValid}, description=${result.description}",
          );

          if (result.isValid) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => NetsuiteDeviceItemScanScreen(
                  locationId: result.description!,
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

  void _handleInventoryGRN() {}

  void _handleInventoryRecall() {}

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
    return Obx(
      () => Container(
        width: appState.isCheckedIn ? size.width * 0.6 : size.width * 0.75,
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
                  color: appState.isCheckedIn
                      ? Color(0xFFFF8C00).withOpacity(0.1)
                      : Color(0xFF9CA3AF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time,
                  color: appState.isCheckedIn
                      ? Color(0xFFFF8C00)
                      : Color(0xFF9CA3AF),
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
            Expanded(
              flex: appState.isCheckedIn ? 7 : 8,
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
                          ? appState.workedTimeValue == "Not checked in yet"
                                ? 16
                                : 20
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? appState.workedTimeValue == "Not checked in yet"
                                ? 19
                                : 23
                          : Responsive.isTabletPortrait(context)
                          ? appState.workedTimeValue == "Not checked in yet"
                                ? 22
                                : 30
                          : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing:
                          appState.workedTimeValue == "Not checked in yet"
                          ? 0
                          : 1,
                    ),
                    child: Text(appState.workedTimeValue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Size size) {
    return Obx(
      () => Padding(
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
                        color: appState.isDeactivatedValue
                            ? Colors.red
                            : appState.isCheckedIn
                            ? Colors.green
                            : Color(0xFF9CA3AF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (appState.isDeactivatedValue
                                      ? Colors.red
                                      : appState.isCheckedIn
                                      ? Color(0xFF10B981)
                                      : Color(0xFF9CA3AF))
                                  .withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          appState.userObj.value != null &&
                              appState.userObj.value!["ProfileImage"] != null
                          ? appState.userObj.value!["ProfileImage"] !=
                                    "https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=None"
                                ? Image.network(
                                    appState.userObj.value!["ProfileImage"],
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
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: appState.isDeactivatedValue
                            ? Colors.red
                            : appState.isCheckedIn
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.userObj.value != null
                          ? appState.userObj.value!['LastName'] != null
                                ? appState.userObj.value!["FirstName"] +
                                      " " +
                                      appState.userObj.value!["LastName"]
                                : appState.userObj.value!['FirstName']
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
                            color: appState.isDeactivatedValue
                                ? Colors.red
                                : appState.isCheckedIn
                                ? Color(0xFF10B981)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          appState.isDeactivatedValue
                              ? 'Inactive'
                              : appState.isCheckedIn
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
                            color: appState.isDeactivatedValue
                                ? Colors.red
                                : appState.isCheckedIn
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
      ),
    );
  }

  void updateWorkTime() {
    if (appState.lastCheckIn.value != null &&
        appState.lastCheckIn.value!["OutTime"] == null) {
      lastCheckInTime = DateTime.parse(appState.lastCheckIn.value!["InTime"]);
      Duration duration = DateTime.now().difference(lastCheckInTime!);

      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

      appState.updateWorkedTime(
        "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds",
      );
    } else {
      appState.updateWorkedTime("Not checked in yet");
    }
  }

  Future<void> loadLastCheckIn() async {
    showProgressDialog(context);
    String userId = appState.userObj.value!['Id'];
    String customerId = appState.userObj.value!['CustomerId'];

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
          appState.setLastCheckIn(item);
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

  Future<void> loadUserData() async {
    showProgressDialog(context);
    var response = await ApiService.verifyUserWithEmpCode(
      appState.employeeCode.value,
    );
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
      Map<String, dynamic> userObj = jsonDecode(response.body);
      appState.setUserObj(userObj);

      _storage.setString('user_data', response.body);
      String? lastCheckInData = _storage.getString('last_check_in');

      if (lastCheckInData == null) {
        await loadLastCheckIn();
      } else {
        appState.setLastCheckIn(jsonDecode(lastCheckInData));
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
