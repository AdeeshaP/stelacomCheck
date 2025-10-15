import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class RecallIMEIScannerScreen extends StatefulWidget {
  final dynamic item;
  final String itemKey;
  final int actualQuantity;
  final List<String> expectedIMEIs;
  final List<String> initialScannedIMEIs;
  final Map<String, dynamic>? userObj;
  final int index;

  const RecallIMEIScannerScreen({
    super.key,
    required this.item,
    required this.itemKey,
    required this.actualQuantity,
    required this.expectedIMEIs,
    required this.initialScannedIMEIs,
    this.userObj,
    required this.index,
  });

  @override
  State<RecallIMEIScannerScreen> createState() =>
      _RecallIMEIScannerScreenState();
}

class _RecallIMEIScannerScreenState extends State<RecallIMEIScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  List<String> scannedIMEIs = [];
  Set<String> scannedSet = {};
  bool isScanning = true;
  bool flashEnabled = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late SharedPreferences _storage;

  // Duplicate prevention
  String? lastScannedCode;
  DateTime? lastScanTime;
  Timer? _scanCooldownTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeSharedPrefs();
    _requestCameraPermission();
    _initializeAnimations();

    // Initialize with previously scanned IMEIs
    scannedIMEIs = List<String>.from(widget.initialScannedIMEIs);
    scannedSet = Set<String>.from(widget.initialScannedIMEIs);
  }

  Future<void> _initializeSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
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
        content: Text('This app needs camera access to scan IMEIs.'),
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
    if (!isScanning || _isProcessing) return;
    if (scannedIMEIs.length >= widget.actualQuantity) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    _isProcessing = true;

    bool foundValidMatch = false;
    String scannedCode = '';

    for (final barcode in barcodes) {
      final String code = barcode.rawValue ?? '';
      scannedCode = code;

      // Skip if duplicate or invalid
      if (_isDuplicateCode(code) || !_isValidIMEI(code)) {
        continue;
      }

      // Check if this IMEI is in the expected list
      if (widget.expectedIMEIs.contains(code)) {
        setState(() {
          scannedIMEIs.add(code);
          scannedSet.add(code);
        });

        _showScanSuccess(code);
        foundValidMatch = true;

        if (scannedIMEIs.length >= widget.actualQuantity) {
          _showCompletionMessage();

          // Turn off flash if it's currently on
          if (flashEnabled) {
            setState(() => flashEnabled = false);
            cameraController.toggleTorch();
          }
        }

        break;
      } else {
        // _showUnexpectedIMEI(code);
        break;
      }
    }

    if (!foundValidMatch &&
        scannedCode.isNotEmpty &&
        widget.expectedIMEIs.contains(scannedCode)) {
      // This shouldn't happen, but handle edge case
      _showGeneralError(
        widget.item.imeis != null
            ? 'Unable to process scanned IMEI'
            : 'Unable to process scanned Serial Number',
      );
    }

    _provideFeedback(foundValidMatch);
    lastScanTime = DateTime.now();
    lastScannedCode = scannedCode;

    // Set cooldown
    setState(() => isScanning = false);
    _scanCooldownTimer?.cancel();
    _scanCooldownTimer = Timer(Duration(milliseconds: 1500), () {
      if (mounted && scannedIMEIs.length < widget.actualQuantity) {
        setState(() => isScanning = true);
        _isProcessing = false;
      }
    });
  }

  bool _isDuplicateCode(String code) {
    if (scannedSet.contains(code)) return true;

    if (lastScannedCode == code && lastScanTime != null) {
      final timeDifference = DateTime.now().difference(lastScanTime!);
      if (timeDifference.inSeconds < 2) return true;
    }

    return false;
  }

  bool _isValidIMEI(String code) {
    if (code.trim().isEmpty) return false;
    // IMEI should be 15 digits
    if (code.length == 15 && RegExp(r'^\d{15}$').hasMatch(code)) return true;
    // Or allow serial numbers (alphanumeric, 8-20 characters)
    if (code.length >= 8 &&
        code.length <= 20 &&
        RegExp(r'^[A-Z0-9\-]+$').hasMatch(code.toUpperCase()))
      return true;
    return false;
  }

  void _showScanSuccess(String imei) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                // 'IMEI verified: ${imei}\n${scannedIMEIs.length}/${widget.actualQuantity} scanned',
                widget.item.imeis != null
                    ? 'IMEI : ${imei} verified successfully.'
                    : 'Serial Number : ${imei} verified successfully.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCompletionMessage() {
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.done_all, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  widget.item.imeis != null
                      ? widget.actualQuantity > 1
                            ? 'All ${widget.actualQuantity} IMEIs scanned successfully!'
                            : 'IMEI scanned successfully!'
                      : widget.actualQuantity > 1
                      ? 'All ${widget.actualQuantity} serial numbers scanned successfully!'
                      : 'Serial number scanned successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  void _showGeneralError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
        duration: Duration(milliseconds: 100),
        backgroundColor: Colors.orange,
      ),
    );
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

  void _finishScanning() {
    Navigator.pop(context, scannedIMEIs);
  }

  String get scanningStatus {
    if (_isProcessing) return 'Processing...';
    if (scannedIMEIs.length >= widget.actualQuantity) return 'Complete';
    return isScanning ? 'Scanning...' : 'Cooldown';
  }

  Color get statusColor {
    if (_isProcessing) return Colors.orange;
    if (scannedIMEIs.length >= widget.actualQuantity) return Colors.blue;
    return isScanning ? Colors.green : Colors.red;
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: screenbgcolor,
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
              child: widget.userObj != null
                  ? CachedNetworkImage(
                      imageUrl: widget.userObj!['CompanyProfileImage'],
                      placeholder: (context, url) => Text("..."),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Text(""),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: choiceAction,
            color: Colors.white,
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
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(7),
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
                Row(
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
                        Navigator.pop(context, scannedIMEIs);
                      },
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        // "Scan ${widget.item.imeis != null ? 'IMEIs' : 'Serial Numbers'}",
                        // "Scanning Process",
                        "Scan - Recall",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: screenHeadingColor,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 22
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 25
                              : Responsive.isTabletPortrait(context)
                              ? 28
                              : 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(flex: 1, child: Text("")),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Item Information
          Container(
            height: 80,
            width: size.width * 0.9,
            margin: EdgeInsets.symmetric(horizontal: 5),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.model,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 15
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 16
                        : Responsive.isTabletPortrait(context)
                        ? 22
                        : 22,
                  ),
                ),

                SizedBox(height: 8),
                Text(
                  widget.actualQuantity > 1
                      ? 'Need to scan ${widget.actualQuantity} items to verify.'
                      : 'Need to scan ${widget.actualQuantity} item to verify.',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: Responsive.isMobileSmall(context)
                        ? 13
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 14
                        : Responsive.isTabletPortrait(context)
                        ? 18
                        : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Camera Scanner View
          Expanded(
            flex: 6,
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
                borderRadius: BorderRadius.circular(15),
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
                                    height: size.width * 0.5,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: statusColor,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status indicator
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isProcessing
                                  ? Icons.hourglass_empty
                                  : scannedIMEIs.length >= widget.actualQuantity
                                  ? Icons.done_all
                                  : isScanning
                                  ? Icons.camera_alt
                                  : Icons.pause,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              scanningStatus,
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
                            color: Colors.black.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            flashEnabled ? Icons.flash_on : Icons.flash_off,
                            color: flashEnabled ? Colors.yellow : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 15),

          // Progress Section
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
                    Text(
                      'Progress: ${scannedIMEIs.length} / ${widget.actualQuantity}',
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 15
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 16
                            : Responsive.isTabletPortrait(context)
                            ? 22
                            : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.actualQuantity - scannedIMEIs.length} remaining',
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
                  ],
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: widget.actualQuantity > 0
                      ? scannedIMEIs.length / widget.actualQuantity
                      : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
              ],
            ),
          ),

          SizedBox(height: 15),

          // if (scannedIMEIs.isNotEmpty)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity, // Force full width
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned ${widget.item.imeis != null ? 'IMEIs' : 'Serial Numbers'}:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  scannedIMEIs.isNotEmpty
                      ? Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 4,
                                ),
                            itemCount: scannedIMEIs.length,
                            itemBuilder: (context, index) {
                              final imei = scannedIMEIs[index];
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white38,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 12,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        imei,
                                        style: TextStyle(
                                          fontSize:
                                              Responsive.isMobileSmall(context)
                                              ? 10.5
                                              : Responsive.isMobileMedium(
                                                      context,
                                                    ) ||
                                                    Responsive.isMobileLarge(
                                                      context,
                                                    )
                                              ? 11
                                              : Responsive.isTabletPortrait(
                                                  context,
                                                )
                                              ? 16
                                              : 16,
                                          fontFamily: 'monospace',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // GestureDetector(
                                    //   onTap: () => _removeScannedIMEI(imei),
                                    //   child: Padding(
                                    //     padding: EdgeInsets.only(left: 4),
                                    //     child: Icon(
                                    //       Icons.remove,
                                    //       color: Colors.red,
                                    //       size: 14,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          widget.item.imeis != null
                              ? "No IMEIs scanned yet. Start scanning to see them here."
                              : "No serial numbers scanned yet. Start scanning to see them here.",
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 14
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 15
                                : Responsive.isTabletPortrait(context)
                                ? 20
                                : 20,
                            color: Colors.grey,
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Finish Button
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: scannedIMEIs.length >= widget.actualQuantity
                      ? _finishScanning
                      : null,
                  child: Text(
                    scannedIMEIs.length >= widget.actualQuantity
                        ? 'Complete Scanning'
                        : 'Scan ${widget.actualQuantity - scannedIMEIs.length} more ${widget.item.imeis != null ? 'IMEIs' : 'Serial Numbers'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.isMobileSmall(context)
                          ? 15
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 16
                          : Responsive.isTabletPortrait(context)
                          ? 22
                          : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        scannedIMEIs.length >= widget.actualQuantity
                        ? actionBtnColor
                        : Colors.grey[400],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
