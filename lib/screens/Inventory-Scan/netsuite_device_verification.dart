import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stelacom_check/app-services/stelacom_api_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/netsuite_device_item.dart';
import 'package:stelacom_check/models/scanned_item2.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventory-Scan/netsuite_verification_results.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NetsuiteDeviceItemScanScreen extends StatefulWidget {
  final int index;
  final String locationDescription;

  const NetsuiteDeviceItemScanScreen({
    super.key,
    required this.index,
    required this.locationDescription,
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

  static const String STORAGE_KEY_USER_DATA = 'user_data';
  static const String STORAGE_KEY_EMPLOYEE_CODE = 'employee_code';

  String? lastScannedBarcode;
  DateTime? lastScanTime;
  Timer? _scanCooldownTimer;
  bool _isProcessing = false;
  bool isLoading = true;
  String? errorMessage;

  List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Log Out',
  ];

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

    print("Location description ID: ${widget.locationDescription}");

    // Load devices from API
    
    await loadDevicesFromAPI();
  }

  // Updated to load from NetSuite API
  Future<void> loadDevicesFromAPI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Option 1: Load from actual API (COMMENT THIS FOR TESTING)
      final response = await StelacomApiService.loadDeviceListOfLocation(
        int.parse(widget.locationDescription),
      );

      // final response = await _loadFromLocalJSON();

      setState(() {
        List<dynamic> dosArray = [];

        if (response.containsKey('data') &&
            response['data'] is Map &&
            response['data']['dos'] is List) {
          dosArray = response['data']['dos'] as List<dynamic>;
        } else if (response.containsKey('dos') && response['dos'] is List) {
          dosArray = response['dos'] as List<dynamic>;
        } else if (response.isNotEmpty) {
          dosArray = [response];
        }

        // Convert to DeviceItem list
        deviceList = dosArray
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
      });

      print('Loaded ${deviceList.length} devices from API');
      print(
        'Scannable devices: ${deviceList.where((d) => d.scannableIdentifier != null).length}',
      );
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
        'assets/json/netsuite_device_list.json',
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

      // Find matching device by Number field
      NetsuiteDeviceItem? matchedDevice = _findMatchingDevice(code);

      if (matchedDevice != null) {
        if (!matchedDevice.serialized) {
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

  NetsuiteDeviceItem? _findMatchingDevice(String scannedCode) {
    // Exact match on Number field
    for (NetsuiteDeviceItem item in deviceList) {
      String? identifier = item.scannableIdentifier;
      if (identifier != null && identifier == scannedCode) {
        return item;
      }
    }

    // Partial match
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

  void _showVerificationSuccess(NetsuiteDeviceItem device) {
    String deviceInfo = device.deviceType == 'IMEI Device'
        ? 'IMEI: ${device.number}'
        : 'Serial: ${device.number}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
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
        duration: Duration(milliseconds: 1500),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showNonSerializedDeviceMessage(NetsuiteDeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This item cannot be scanned individually:\n${device.model}',
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showAlreadyVerifiedMessage(NetsuiteDeviceItem device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.done_all, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Device already verified: ${device.model}'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showNoMatchFound(String scannedCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('No matching device found in inventory.')),
          ],
        ),
        duration: Duration(milliseconds: 1500),
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

  bool _isValidBarcode(String code) {
    if (code.trim().isEmpty) return false;
    // Accept various formats for flexibility
    if (code.length >= 8 && code.length <= 25) return true;
    return false;
  }

  void _addScannedItem(String barcode, NetsuiteDeviceItem device) {
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

  void _turnOffFlash() {
    if (flashEnabled) {
      setState(() => flashEnabled = false);
      cameraController.toggleTorch();
    }
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  get verifiedCount =>
      deviceList.where((item) => item.serialized && item.isVerified).length;
  get scannableDeviceCount =>
      deviceList.where((item) => item.scannableIdentifier != null).length;
  get totalCount => deviceList.length;

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
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  value: choice,
                  child: Text(
                    choice,
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
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
                  Text('Loading devices from NetSuite...'),
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
                  Text(errorMessage!, textAlign: TextAlign.center),
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
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
                            onTap: () => Navigator.of(context).pop(),
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
                                        fontSize: 12,
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
                    'Point camera at device Serial Number/IMEI to verify',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 10),

                  // Verification Progress
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
                                    'Verified: $verifiedCount / $scannableDeviceCount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Total Items in Location: $totalCount',
                                    style: TextStyle(
                                      fontSize: 14,
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
                            fontSize: 12,
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
                                  _turnOffFlash();

                                  final result = await Navigator.push<List< NetsuiteDeviceItem>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NetsuiteVerificationResultsScreen(
                                        index: widget.index,
                                        deviceList: deviceList,
                                      ),
                                    ),
                                  );

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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
