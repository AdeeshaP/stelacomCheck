import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/device_item.dart';
import 'package:stelacom_check/models/scanned_item2.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventroy-Scan/verifcaiton_resuts.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class EnhancedBarcodeScannerScreen extends StatefulWidget {
  final int index;
  final String locationDescription;

  const EnhancedBarcodeScannerScreen({
    super.key,
    required this.index,
    required this.locationDescription,
  });

  @override
  _EnhancedBarcodeScannerScreenState createState() =>
      _EnhancedBarcodeScannerScreenState();
}

class _EnhancedBarcodeScannerScreenState
    extends State<EnhancedBarcodeScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Updated device verification system
  List<DeviceItem> deviceList = [];
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

  // Only keep user-related SharedPreferences keys
  static const String STORAGE_KEY_USER_DATA = 'user_data';
  static const String STORAGE_KEY_EMPLOYEE_CODE = 'employee_code';

  // Duplicate prevention
  String? lastScannedBarcode;
  DateTime? lastScanTime;
  Timer? _scanCooldownTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initializeAnimations();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    _storage = await SharedPreferences.getInstance();
    userData = _storage.getString(STORAGE_KEY_USER_DATA) ?? "";
    employeeCode = _storage.getString(STORAGE_KEY_EMPLOYEE_CODE) ?? "";

    if (userData.isNotEmpty) {
      try {
        userObj = jsonDecode(userData);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    print("location desctiption ID ${widget.locationDescription}");

    await _loadDevicesFromJSON(); // Load fresh from JSON
  }

  // Updated method to load devices from JSON
  Future<void> _loadDevicesFromJSON() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/json/device_list3.json',
      );

      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> devices = jsonData['devices'];

      setState(() {
        // Convert to new DeviceItem model
        deviceList = devices.map((device) {
          return DeviceItem(
            model: device['model'].toString(),
            imei: device['imei']?.toString(),
            serialNo: device['serial_no']?.toString(),
            serialized:
                device['serialized'] ??
                (device['imei'] != null || device['serial_no'] != null),
            quantity: device['quantity'],
            isVerified: false,
            verificationTime: null,
          );
        }).toList();

        // Reset scan tracking
        scannedItems.clear();
        scannedBarcodes.clear();
      });

      print('Loaded ${deviceList.length} devices from JSON');
      print(
        'Scannable devices: ${deviceList.where((d) => d.scannableIdentifier != null).length}',
      );
      print(
        'Non-serialized devices: ${deviceList.where((d) => !d.serialized).length}',
      );
    } catch (e) {
      print('Error loading devices from JSON: $e');
      _showErrorSnackBar('Failed to load device list from file');
    }
  }

  // Get today's date as string (YYYY-MM-DD format)
  // String _getTodayDateString() {
  //   DateTime now = DateTime.now();
  //   return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  // }

  // Show error message to user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  // SIDE MENU BAR UI
  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out',
  ];

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
      _storage.clear();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
        (route) => false,
      );
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

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

  // Updated barcode detection with new logic
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

      if (_isDuplicateBarcode(code) || !_isValidDeviceBarcode(code)) {
        continue;
      }

      // Check if this barcode matches any device in the list
      DeviceItem? matchedDevice = _findMatchingDevice(code);

      if (matchedDevice != null) {
        if (!matchedDevice.serialized) {
          // This shouldn't happen as non-serialized items don't have scannable identifiers
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
            'Device verified: ${matchedDevice.model} (${matchedDevice.deviceType})',
          );
          break;
        } else {
          // Device already verified
          _showAlreadyVerifiedMessage(matchedDevice);
          foundMatch = true;
          break;
        }
      }
    }

    if (!foundMatch && scannedCode.isNotEmpty) {
      // No matching device found
      _showNoMatchFound(scannedCode);
    }

    // Provide feedback and set cooldown
    _provideFeedback(foundMatch);

    // Update last scan info
    lastScanTime = DateTime.now();

    // Set cooldown
    setState(() => isScanning = false);
    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isScanning = true);
        _isProcessing = false;
      }
    });
  }

  // Updated device matching logic
  DeviceItem? _findMatchingDevice(String scannedCode) {
    // First, try exact matches
    for (DeviceItem item in deviceList) {
      String? identifier = item.scannableIdentifier;
      if (identifier != null && identifier == scannedCode) {
        return item;
      }
    }

    // Then, try partial matches (for cases where barcode contains the identifier)
    for (DeviceItem item in deviceList) {
      String? identifier = item.scannableIdentifier;
      if (identifier != null &&
          (scannedCode.contains(identifier) ||
              identifier.contains(scannedCode))) {
        return item;
      }
    }

    return null;
  }

  // Updated success message to show device type
  void _showVerificationSuccess(DeviceItem device) {
    String deviceInfo = device.deviceType == 'IMEI Device'
        ? 'IMEI: ${device.imei}'
        : 'Serial: ${device.serialNo}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Device verified successfully!\n${device.model}\n$deviceInfo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  // New message for non-serialized devices
  void _showNonSerializedDeviceMessage(DeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This item cannot be scanned individually:\n${device.model}\n(Non-serialized item)',
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // New message for already verified devices
  void _showAlreadyVerifiedMessage(DeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.done_all, color: Colors.white),
            SizedBox(width: 8),
            Text('Device already verified: ${device.model}'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Updated no match message with more detail
  void _showNoMatchFound(String scannedCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('No matching device found in inventory.')),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _isDuplicateBarcode(String code) {
    if (scannedBarcodes.contains(code)) return true;

    if (lastScannedBarcode == code && lastScanTime != null) {
      final timeDifference = DateTime.now().difference(lastScanTime!);
      if (timeDifference.inSeconds < 3) return true;
    }

    return false;
  }

  bool _isValidDeviceBarcode(String code) {
    if (code.trim().isEmpty) return false;
    if (code.length == 15 && RegExp(r'^\d{15}$').hasMatch(code)) return true;
    if (code.length >= 8 &&
        code.length <= 20 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase()))
      return true;
    return false;
  }

  // Updated method to add scanned items
  void _addScannedItem(String barcode, DeviceItem device) {
    final ScannedItem item = ScannedItem(
      barcode: barcode,
      identifier: device.scannableIdentifier ?? '',
      timestamp: DateTime.now(),
      deviceModel: device.model,
      deviceType: device.deviceType,
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

  void _toggleFlash() {
    setState(() => flashEnabled = !flashEnabled);
    cameraController.toggleTorch();
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Updated progress calculation
  get verifiedCount =>
      deviceList.where((item) => item.serialized && item.isVerified).length;
  get scannableDeviceCount =>
      deviceList.where((item) => item.scannableIdentifier != null).length;
  get totalCount => deviceList.length;

  void _turnOffFlash() {
    if (flashEnabled) {
      setState(() => flashEnabled = false);
      cameraController.toggleTorch();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
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
              child: userObj != null && userObj!['CompanyProfileImage'] != null
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
      body: SafeArea(
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
                    onPressed: () => Navigator.of(context).pop(),
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
                                        borderRadius: BorderRadius.circular(12),
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
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 11
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 12
                                      : Responsive.isTabletPortrait(context)
                                      ? 16
                                      : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Flash toggle
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
                              flashEnabled ? Icons.flash_on : Icons.flash_off,
                              color: flashEnabled
                                  ? Colors.yellow
                                  : Colors.white,
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
              'Point camera at device barcode/IMEI to verify against inventory',
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

            // Updated Verification Progress
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
                              'Scannable Devices: $verifiedCount / $scannableDeviceCount',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 15
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                    ? 21
                                    : 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Total Items: $totalCount',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 14
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                      // Row(
                      //   children: [
                      //     IconButton(
                      //       onPressed: _toggleFlash,
                      //       icon: Icon(
                      //         flashEnabled ? Icons.flash_on : Icons.flash_off,
                      //         color: flashEnabled ? Colors.orange : Colors.grey,
                      //       ),
                      //       tooltip: 'Toggle flash',
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: scannableDeviceCount > 0
                        ? verifiedCount / scannableDeviceCount
                        : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${scannableDeviceCount - verifiedCount} scannable items remaining',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: Responsive.isMobileSmall(context)
                          ? 11
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 12
                          : Responsive.isTabletPortrait(context)
                          ? 16
                          : 16,
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
                            _turnOffFlash(); // Turn off flash before navigating

                            final result = await Navigator.push<List<DeviceItem>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerificationResultsTwoScreen(
                                  index: widget.index,
                                  deviceList:
                                      deviceList, // Pass deviceList instead of imeiList
                                ),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                deviceList = result;
                              });
                              print(
                                'Updated device list received: ${deviceList.where((item) => item.isVerified).length}/${deviceList.length}',
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
    );
  }

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
                ? 20
                : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
