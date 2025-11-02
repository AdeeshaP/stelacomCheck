import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/app-services/stelacom_api_service.dart';
import 'package:stelacom_check/app-services/submitted_device_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/netsuite_device_item.dart';
import 'package:stelacom_check/models/scanned_item2.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventory-Scan/netsuite_verification_results.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';

class NetsuiteDeviceItemScanScreen extends StatefulWidget {
  final int index;
  final String locationId;

  const NetsuiteDeviceItemScanScreen({
    super.key,
    required this.index,
    required this.locationId,
  });

  @override
  _NetsuiteDeviceItemScanScreenState createState() =>
      _NetsuiteDeviceItemScanScreenState();
}

class _NetsuiteDeviceItemScanScreenState
    extends State<NetsuiteDeviceItemScanScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  Set<String> submittedDeviceIdentifiers = {};
  List<NetsuiteDeviceItem> deviceList = [];
  List<ScannedItem> scannedItems = [];
  Set<String> scannedBarcodes = {};
  bool isScanning = true;
  bool flashEnabled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  String? lastScannedBarcode;
  DateTime? lastScanTime;
  Timer? _scanCooldownTimer;
  bool _isProcessing = false;
  bool isLoading = true;
  String? errorMessage;
  String deviceLocation = "";

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initializeAnimations();
    _loadUserPreferences();
    _loadSubmittedDevices(); // Add this line
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ----------- Load previously submitted devices -------------

  Future<void> _loadSubmittedDevices() async {
    submittedDeviceIdentifiers =
        await SubmittedDevicesService.getSubmittedDeviceIdentifiers(
          locationId: widget.locationId,
          userId: userObj != null && userObj!['id'] != null
              ? userObj!['id'].toString()
              : '',
        );
    print(
      '📋 Loaded ${submittedDeviceIdentifiers.length} previously submitted devices',
    );
  }

  // ----------- Load user preferences -------------

  Future<void> _loadUserPreferences() async {
    _storage = await SharedPreferences.getInstance();
    userData = await _storage.getString('user_data') ?? "";
    employeeCode = await _storage.getString('employee_code') ?? "";

    if (userData.isNotEmpty) {
      try {
        userObj = jsonDecode(userData);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    print("Location description ID: ${widget.locationId}");

    await loadDevicesFromAPI();
  }

  // ----------- Load devices from API -------------

  Future<void> loadDevicesFromAPI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await StelacomApiService.loadDeviceListOfLocation(
        int.parse(widget.locationId),
      );

      // final response = await _loadFromLocalJSON();

      setState(() {
        List<dynamic> resultsArray = [];

        // Handle device_list2.json format: data.results
        if (response.containsKey('data') &&
            response['data'] is Map &&
            response['data']['results'] is List) {
          resultsArray = response['data']['results'] as List<dynamic>;
        }
        // Fallback for other formats
        else if (response.containsKey('results') &&
            response['results'] is List) {
          resultsArray = response['results'] as List<dynamic>;
        } else if (response.isNotEmpty) {
          resultsArray = [response];
        }

        // CHECK IF RESULTS ARE EMPTY - Show dialog and navigate back
        if (resultsArray.isEmpty) {
          deviceList = [];
          scannedItems.clear();
          scannedBarcodes.clear();
          isLoading = false;
          deviceLocation = "Unknown Location";

          // Show dialog after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showEmptyLocationDialog();
            }
          });
          return;
        }

        // Convert to NetsuiteDeviceItem list using updated model
        deviceList = resultsArray
            .map(
              (item) => NetsuiteDeviceItem.fromNetSuiteJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

        // Reset scan tracking
        scannedItems.clear();
        scannedBarcodes.clear();

        isLoading = false;
        deviceLocation = deviceList.isNotEmpty
            ? deviceList[0].location
            : "Unknown Location";
      });

      print('Loaded ${deviceList.length} devices from API');
      print(
        'Scannable devices: ${deviceList.where((d) => d.scannableIdentifier != null).length}',
      );
      if (deviceList.isNotEmpty) {
        print("Item Location: ${deviceList[0].location}");
      }
    } catch (e) {
      print('Error loading devices: $e');
      setState(() {
        errorMessage = 'Failed to load devices: $e';
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load device list');
    }
  }

  // Helper method to load from local JSON for testing
  Future<Map<String, dynamic>> _loadFromLocalJSON() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/json/device_list2.json', // Updated to use device_list2.json
      );
      Map<String, dynamic> jsonData =
          jsonDecode(jsonString) as Map<String, dynamic>;
      print('Loaded local JSON successfully');
      return jsonData;
    } catch (e) {
      print('Error loading local JSON: $e');
      rethrow;
    }
  }

  //-------- Dialog to show when location has no items----------------

  void _showEmptyLocationDialog() {
    showDialog(
      barrierColor: Colors.black87,
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with circular background
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.orange[700],
                  size: 60,
                ),
              ),
              SizedBox(height: 25),

              // Title
              Text(
                'No Items in Location',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 22
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 24
                      : Responsive.isTabletPortrait(context)
                      ? 30
                      : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),

              // Message
              Text(
                'There are currently no items assigned to this location that require verification.',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 15
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                      ? 22
                      : 22,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _stopCamera(); // Stop camera
                    Navigator.pop(context); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 17
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 18
                          : Responsive.isTabletPortrait(context)
                          ? 25
                          : 25,
                      fontWeight: FontWeight.bold,
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

  // ----------- Show error snackbar -------------

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
              size:
                  Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 24
                  : Responsive.isTabletPortrait(context)
                  ? 30
                  : 30,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
  // --------- Side menu options ---------------

  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out',
  ];

  // ------Handle menu option selection-----------------

  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HelpScreen(index3: widget.index),
        ),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AboutUs(index3: widget.index)),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContactUs(index3: widget.index),
        ),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TermsAndConditions(index3: widget.index),
        ),
      );
    } else if (choice == _menuOptions[4]) {
      if (!mounted) return;
      // _storage.clear();
      // Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
      //   (route) => false,
      // );
      LogoutService.logoutWithOptions(context);
    }
  }

  // --------- Barcode scanning and processing logic -------------

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  //-------------- Request camera permission ---------------

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

  // ------------- Show camera permission dialog ---------------

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text('This app needs camera access to scan barcodes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  // ------------- Main barcode detection handler -------------

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (!isScanning || _isProcessing || deviceList.isEmpty) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    _isProcessing = true;

    bool foundMatch = false;
    String scannedCode = '';

    for (final barcode in barcodes) {
      final String code = barcode.rawValue ?? '';
      scannedCode = code;

      if (_isDuplicateBarcode(code) || !_isValidBarcode(code)) {
        continue;
      }

      // NEW: Check if this device was already submitted
      if (submittedDeviceIdentifiers.contains(code)) {
        _showAlreadySubmittedMessage(code);
        foundMatch = true;
        break;
      }

      // Find matching device by Serial Number
      NetsuiteDeviceItem? matchedDevice = _findMatchingDevice(code);

      if (matchedDevice != null) {
        // Check if device is serialized
        if (!matchedDevice.isSerialized) {
          _showNonSerializedDeviceMessage(matchedDevice);
          break;
        }

        if (!matchedDevice.isVerified) {
          // Mark as verified
          setState(() {
            matchedDevice.isVerified = true;
            matchedDevice.verificationTime = DateTime.now();
          });

          // Add to scanned items
          _addScannedItem(code, matchedDevice);

          // Show success message
          _showVerificationSuccess(matchedDevice);

          foundMatch = true;
          print(
            'Device verified: ${matchedDevice.item} (Serial: ${matchedDevice.serialNumber})',
          );
          break;
        } else {
          _showAlreadyVerifiedMessage(matchedDevice);
          foundMatch = true;
          break;
        }
      }
    }

    if (!foundMatch && scannedCode.isNotEmpty) {
      _showNoMatchFound(scannedCode);
    }

    _provideFeedback(foundMatch);
    lastScanTime = DateTime.now();

    setState(() => isScanning = false);
    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isScanning = true);
        _isProcessing = false;
      }
    });
  }

  // ------------- Method to show already submitted message-------------

  void _showAlreadySubmittedMessage(String scannedCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This device was already verified.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 13
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 18,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'View History',
          textColor: Colors.white,
          onPressed: () {
            _showSubmissionHistoryDialog();
          },
        ),
      ),
    );
  }

  // ---------- Method to show submission history Dialog------------------

  void _showSubmissionHistoryDialog() async {
    List<SubmissionHistoryItem> history =
        await SubmittedDevicesService.getLocationSubmissionHistory(
          locationId: widget.locationId,
          userId: userObj != null && userObj!['id'] != null
              ? userObj!['id'].toString()
              : '',
        );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          constraints: BoxConstraints(maxHeight: 600, maxWidth: 400),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with circular background - orange like empty location dialog
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  history.isEmpty ? Icons.history_outlined : Icons.history,
                  color: Colors.orange[700],
                  size: 60,
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                history.isEmpty
                    ? 'No Submission History'
                    : 'Submission History',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 22
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 24
                      : Responsive.isTabletPortrait(context)
                      ? 30
                      : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Content Section
              if (history.isEmpty)
                // Empty state message
                Text(
                  'There are currently no previous submissions for this location. All scanned devices can be submitted.',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 15
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 16
                        : Responsive.isTabletPortrait(context)
                        ? 22
                        : 22,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                // History list
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Summary badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${history.length} submission${history.length > 1 ? 's' : ''} found',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 14
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 18,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),

                      // Scrollable list
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxHeight: 300),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: history.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              SubmissionHistoryItem item = history[index];

                              return Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.grey[600],
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(item.submittedAt),
                                            style: TextStyle(
                                              fontSize:
                                                  Responsive.isMobileSmall(
                                                    context,
                                                  )
                                                  ? 14
                                                  : Responsive.isMobileMedium(
                                                          context,
                                                        ) ||
                                                        Responsive.isMobileLarge(
                                                          context,
                                                        )
                                                  ? 15
                                                  : Responsive.isTabletPortrait(
                                                      context,
                                                    )
                                                  ? 20
                                                  : 20,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size:
                                                    Responsive.isMobileSmall(
                                                          context,
                                                        ) ||
                                                        Responsive.isMobileMedium(
                                                          context,
                                                        ) ||
                                                        Responsive.isMobileLarge(
                                                          context,
                                                        )
                                                    ? 13
                                                    : Responsive.isTabletPortrait(
                                                        context,
                                                      )
                                                    ? 20
                                                    : 20,
                                                color: Colors.grey[500],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                  'hh:mm a',
                                                ).format(item.submittedAt),
                                                style: TextStyle(
                                                  fontSize:
                                                      Responsive.isMobileSmall(
                                                        context,
                                                      )
                                                      ? 12
                                                      : Responsive.isMobileMedium(
                                                              context,
                                                            ) ||
                                                            Responsive.isMobileLarge(
                                                              context,
                                                            )
                                                      ? 13
                                                      : Responsive.isTabletPortrait(
                                                          context,
                                                        )
                                                      ? 18
                                                      : 18,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(
                                                Icons.inventory_2,
                                                size: 13,
                                                color: Colors.grey[500],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${item.deviceCount} device${item.deviceCount > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize:
                                                      Responsive.isMobileSmall(
                                                        context,
                                                      )
                                                      ? 12
                                                      : Responsive.isMobileMedium(
                                                              context,
                                                            ) ||
                                                            Responsive.isMobileLarge(
                                                              context,
                                                            )
                                                      ? 13
                                                      : Responsive.isTabletPortrait(
                                                          context,
                                                        )
                                                      ? 18
                                                      : 18,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 16
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 18
                          : Responsive.isTabletPortrait(context)
                          ? 24
                          : 24,
                      fontWeight: FontWeight.bold,
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

  // ------------ Find matching device by scanned code -------------

  NetsuiteDeviceItem? _findMatchingDevice(String scannedCode) {
    for (NetsuiteDeviceItem item in deviceList) {
      String? identifier = item.scannableIdentifier;
      if (identifier != null && identifier == scannedCode) {
        return item;
      }
    }

    for (NetsuiteDeviceItem item in deviceList) {
      String? identifier = item.scannableIdentifier;
      if (identifier != null &&
          (scannedCode.contains(identifier) ||
              identifier.contains(scannedCode))) {
        return item;
      }
    }

    return null;
  }

  // ------------ UI verification success feedback methods -------------

  void _showVerificationSuccess(NetsuiteDeviceItem device) {
    String deviceInfo =
        device.serialNumber != null && device.serialNumber!.isNotEmpty
        ? 'Serial: ${device.serialNumber}'
        : 'Item verified';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Device verified successfully!\n${device.item}\n$deviceInfo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ------------ UI messages for special cases -------------

  void _showNonSerializedDeviceMessage(NetsuiteDeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This item cannot be scanned individually:\n${device.item}',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 13
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 18,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ------------ UI message for already verified device -------------

  void _showAlreadyVerifiedMessage(NetsuiteDeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.done_all, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Device already verified: ${device.item}'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ------------ UI message for no match found -------------

  void _showNoMatchFound(String scannedCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No matching device found in inventory.',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 13
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 18,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ------------ Handle back navigation with unsaved progress -------------

  Future<bool> _onWillPop() async {
    // Check if there's any verification progress
    if (_hasVerificationProgress()) {
      // Calculate total verified count (both serialized and non-serialized)
      int totalVerified = deviceList.where((item) => item.isVerified).length;

      // Show SnackBar with action buttons
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                        ? 30
                        : 30,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Warning!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 16
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 18
                            : Responsive.isTabletPortrait(context)
                            ? 24
                            : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'You have verified $totalVerified device(s). Going back will clear your verification history and progress will be lost.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 13
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: actionBtnColor,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 14
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 15
                            : Responsive.isTabletPortrait(context)
                            ? 20
                            : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _stopCamera();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: actionBtnColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      ' Leave ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 14
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 15
                            : Responsive.isTabletPortrait(context)
                            ? 20
                            : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // backgroundColor: Colors.red.shade700,
        ),
      );

      // Return false to prevent navigation (SnackBar buttons handle navigation)
      return false;
    } else {
      // No verification progress, allow back navigation
      _stopCamera();
      return true;
    }
  }

  // ------------ Duplicate and validity checks -------------

  bool _isDuplicateBarcode(String code) {
    if (scannedBarcodes.contains(code)) return true;

    if (lastScannedBarcode == code && lastScanTime != null) {
      final timeDifference = DateTime.now().difference(lastScanTime!);
      if (timeDifference.inSeconds < 3) return true;
    }

    return false;
  }

  // ------------ Basic barcode validity check -------------

  bool _isValidBarcode(String code) {
    if (code.trim().isEmpty) return false;
    // Accept various formats for flexibility
    if (code.length >= 8 && code.length <= 25) return true;
    return false;
  }

  // ----------- Add scanned item to list -------------

  void _addScannedItem(String barcode, NetsuiteDeviceItem device) {
    final ScannedItem item = ScannedItem(
      barcode: barcode,
      identifier: device.scannableIdentifier ?? '',
      timestamp: DateTime.now(),
      deviceModel: device.item,
      deviceType: device.isSerialized ? 'Serialized' : 'Non-Serialized',
    );

    setState(() {
      scannedItems.add(item);
      scannedBarcodes.add(barcode);
    });
  }

  void _provideFeedback(bool success) {
    Vibration.vibrate(duration: success ? 100 : 200);
    if (success) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  // ------------ Flash toggle and camera stop -------------

  void _toggleFlash() {
    setState(() => flashEnabled = !flashEnabled);
    cameraController.toggleTorch();
  }

  void _stopCamera() {
    try {
      if (flashEnabled) {
        cameraController.toggleTorch();
        flashEnabled = false;
      }
      cameraController.stop();
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  get verifiedCount =>
      deviceList.where((item) => item.isSerialized && item.isVerified).length;
  get scannableDeviceCount =>
      deviceList.where((item) => item.scannableIdentifier != null).length;
  get totalCount => deviceList.length;

  // Add this helper method to check if there's any verification progress
  bool _hasVerificationProgress() {
    // Check scanned items from scanner
    if (scannedItems.isNotEmpty) return true;

    // Check verified serialized items
    if (verifiedCount > 0) return true;

    // Check verified non-serialized items (items without serial numbers but marked as verified)
    bool hasVerifiedNonSerialized = deviceList.any(
      (item) => !item.isSerialized && item.isVerified,
    );

    if (hasVerifiedNonSerialized) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appbarBgColor,
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
                child:
                    userObj != null && userObj!['CompanyProfileImage'] != null
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
        backgroundColor: Colors.grey[50],
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: actionBtnColor),
                    SizedBox(height: 20),
                    Text(
                      'Loading devices from NetSuite...',
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 13
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 18
                            : 18,
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 13
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 18
                            : 18,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loadDevicesFromAPI,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
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
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              child: Icon(
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
                              onTap: () async {
                                _stopCamera(); // Stop camera before popping
                                // Navigator.of(context).pop();
                                final shouldPop = await _onWillPop();
                                if (shouldPop) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              "Device Verification",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: screenHeadingColor,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 22
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 26
                                    : Responsive.isTabletPortrait(context)
                                    ? 32
                                    : 32,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(child: SizedBox(), flex: 1),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // Camera Scanner View
                    Expanded(
                      flex: 8,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: cameraController,
                                onDetect: _handleBarcodeDetection,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.transparent),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ),
                                    Center(
                                      child: AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Container(
                                              width: 300,
                                              height: 250,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: _isProcessing
                                                      ? Colors.orange
                                                      : isScanning
                                                      ? Colors.green
                                                      : Colors.red,
                                                  width: 3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isProcessing
                                        ? Colors.orange
                                        : isScanning
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isProcessing
                                            ? Icons.hourglass_empty
                                            : isScanning
                                            ? Icons.camera_alt
                                            : Icons.pause,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _isProcessing
                                            ? 'Processing...'
                                            : isScanning
                                            ? 'Scanning...'
                                            : 'Cooldown',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              Responsive.isMobileSmall(
                                                    context,
                                                  ) ||
                                                  Responsive.isMobileMedium(
                                                    context,
                                                  ) ||
                                                  Responsive.isMobileLarge(
                                                    context,
                                                  )
                                              ? 12
                                              : Responsive.isTabletPortrait(
                                                  context,
                                                )
                                              ? 18
                                              : 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 20,
                                child: IconButton(
                                  onPressed: _toggleFlash,
                                  icon: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      flashEnabled
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                      color: flashEnabled
                                          ? Colors.yellow
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Instruction Text
                    Text(
                      'Point camera at device Serial Number to verify',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: Responsive.isMobileSmall(context)
                            ? 13
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 18
                            : 18,
                      ),
                    ),
                    SizedBox(height: 10),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Serialized: $scannableDeviceCount',
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.isMobileSmall(context)
                                            ? 15
                                            : Responsive.isMobileMedium(
                                                    context,
                                                  ) ||
                                                  Responsive.isMobileLarge(
                                                    context,
                                                  )
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                context,
                                              )
                                            ? 22
                                            : 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Verified: $verifiedCount / $scannableDeviceCount',
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.isMobileSmall(context)
                                            ? 15
                                            : Responsive.isMobileMedium(
                                                    context,
                                                  ) ||
                                                  Responsive.isMobileLarge(
                                                    context,
                                                  )
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                context,
                                              )
                                            ? 22
                                            : 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Total Items in Location: $totalCount',
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.isMobileSmall(context)
                                            ? 13
                                            : Responsive.isMobileMedium(
                                                    context,
                                                  ) ||
                                                  Responsive.isMobileLarge(
                                                    context,
                                                  )
                                            ? 14
                                            : Responsive.isTabletPortrait(
                                                context,
                                              )
                                            ? 18
                                            : 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: scannableDeviceCount > 0
                                ? verifiedCount / scannableDeviceCount
                                : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                            minHeight: 8,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${scannableDeviceCount - verifiedCount} items remaining',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 11
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 12
                                  : Responsive.isTabletPortrait(context)
                                  ? 17
                                  : 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Action Buttons
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildButton(
                            'View Verification Results',
                            actionBtnColor,
                            deviceList.isNotEmpty
                                ? () async {
                                    _stopCamera();

                                    final result =
                                        await Navigator.push<
                                          List<NetsuiteDeviceItem>
                                        >(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NetsuiteVerificationResultsScreen(
                                                  index: widget.index,
                                                  deviceList: deviceList,
                                                  locationId: widget.locationId,
                                                  location: deviceLocation,
                                                ),
                                          ),
                                        );

                                    // RESTART CAMERA WHEN COMING BACK
                                    if (mounted) {
                                      try {
                                        await cameraController.start();
                                      } catch (e) {
                                        print('Error restarting camera: $e');
                                      }
                                    }

                                    if (result != null) {
                                      setState(() {
                                        deviceList = result;
                                      });
                                      print(
                                        'Updated device list: ${deviceList.where((item) => item.isVerified).length}/${deviceList.length}',
                                      );
                                    }
                                  }
                                : null,
                          ),
                          SizedBox(height: 15),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  // ----------- Button builder -------------

  Widget _buildButton(String text, Color color, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey[300],
          foregroundColor: onPressed != null
              ? (color == Colors.grey ? Colors.grey[600] : Colors.white)
              : Colors.grey[600],
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 15
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 16
                : Responsive.isTabletPortrait(context)
                ? 22
                : 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
