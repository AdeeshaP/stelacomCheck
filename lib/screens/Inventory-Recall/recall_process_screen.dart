import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/recall_transfer_order.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventory-Recall/recall_orders_screen.dart';
import 'package:stelacom_check/screens/Inventory-Recall/scan_verifiying_screen.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecallProcessScreen extends StatefulWidget {
  final RecallTransferOrder order;
  final int index;
  final Map<String, dynamic>? userObj;

  const RecallProcessScreen({
    super.key,
    required this.order,
    required this.index,
    this.userObj,
  });

  @override
  State<RecallProcessScreen> createState() => _RecallProcessScreenState();
}

class _RecallProcessScreenState extends State<RecallProcessScreen> {
  Map<String, int?> actualQuantities = {};
  Map<String, TextEditingController> quantityControllers = {};
  Map<String, List<String>> scannedIMEIs = {};
  bool isProcessingRecall = false;
  int currentStep = 0;
  PageController _pageController = PageController();
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  Map<String, TextEditingController> varianceReasonControllers = {};
  Map<String, List<File>> capturedImages = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    _initializeControllers();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userData = _storage.getString('user_data')!;
    employeeCode = _storage.getString('employee_code') ?? "";

    userObj = jsonDecode(userData);
  }

  void _initializeControllers() {
    for (var item in widget.order.items) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      quantityControllers[itemKey] = TextEditingController();
      varianceReasonControllers[itemKey] = TextEditingController();
      actualQuantities[itemKey] = null; // Initialize to null, not 0
      scannedIMEIs[itemKey] = [];
      capturedImages[itemKey] = [];
    }
  }

  @override
  void dispose() {
    quantityControllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    varianceReasonControllers.values.forEach(
      (controller) => controller.dispose(),
    );
    super.dispose();
  }

  bool _isQuantityStepValid() {
    for (var item in widget.order.items) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int? actualQty = actualQuantities[itemKey];

      if (actualQty == null) {
        return false;
      }

      if (actualQty < 0) {
        return false;
      }

      if (actualQty > item.quantity) {
        return false;
      }
      // Check if variance reason is required and provided
      if (actualQty < item.quantity &&
          varianceReasonControllers[itemKey]!.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _isIMEIScanningStepValid() {
    List<dynamic> discrepancyItems = widget.order.items.where((item) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int actual = actualQuantities[itemKey] ?? 0;
      return actual != item.quantity && actual > 0;
    }).toList();

    for (var item in discrepancyItems) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int actualQty = actualQuantities[itemKey] ?? 0;

      if (actualQty > 0) {
        if (item.serialized) {
          int scannedCount = scannedIMEIs[itemKey]?.length ?? 0;
          // Must scan exactly the actual quantity received
          if (scannedCount < actualQty) return false;
        } else {
          // For non-serialized items, at least 1 photo is required
          if (capturedImages[itemKey]!.isEmpty) return false;
        }
      }
    }
    return true;
  }

  bool _hasDiscrepancies() {
    for (var item in widget.order.items) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int actual = actualQuantities[itemKey] ?? 0;
      if (actual != item.quantity) {
        return true;
      }
    }
    return false;
  }

  void _nextStep() {
    if (currentStep == 0 && _isQuantityStepValid()) {
      setState(() {
        currentStep = _hasDiscrepancies() ? 1 : 2;
      });
      _pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentStep == 1) {
      setState(() {
        currentStep = 2;
      });
      _pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep = currentStep == 2 && _hasDiscrepancies() ? 1 : 0;
      });
      _pageController.animateToPage(
        currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToIMEIScanner(dynamic item, String itemKey) async {
    int actualQty = actualQuantities[itemKey] ?? 0;
    List<String> expectedIMEIs = [];

    if (item.imeis != null && item.imeis.isNotEmpty) {
      expectedIMEIs = List<String>.from(item.imeis);
    } else if (item.serialNos != null && item.serialNos.isNotEmpty) {
      expectedIMEIs = List<String>.from(item.serialNos);
    }

    if (expectedIMEIs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No expected IMEIs/Serial Numbers found for this item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (actualQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter actual quantity first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => RecallIMEIScannerScreen(
            item: item,
            itemKey: itemKey,
            actualQuantity: actualQty,
            expectedIMEIs: expectedIMEIs,
            initialScannedIMEIs: scannedIMEIs[itemKey] ?? [],
            userObj: userObj,
            index: widget.index,
          ),
        ),
      );

      // Update scanned IMEIs when returning from scanner
      if (result != null) {
        setState(() {
          scannedIMEIs[itemKey] = result;
        });

        // Show success message if all required IMEIs are scanned

        // if (result.length >= actualQty) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Row(
        //         children: [
        //           Icon(Icons.check_circle, color: Colors.white),
        //           SizedBox(width: 8),
        //           Text(
        //             item.imeis != null
        //                 ? 'All ${actualQty} IMEIs scanned successfully\n for ${item.model}'
        //                 : 'All ${actualQty} Serial numbers scanned successfully\n for ${item.model}',
        //             style: TextStyle(fontWeight: FontWeight.bold),
        //           ),
        //         ],
        //       ),
        //       backgroundColor: Colors.green,
        //       duration: Duration(seconds: 1),
        //     ),
        //   );
        // }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening scanner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeRecall() {
    setState(() {
      isProcessingRecall = true;
    });

    // Simulate processing
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return RecallTransferOrdersScreen(index: widget.index);
          },
        ),
      ); // Return to previous screen with success
    });
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
            return HelpScreen(index3: widget.index);
          },
        ),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AboutUs(index3: widget.index);
          },
        ),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ContactUs(index3: widget.index);
          },
        ),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return TermsAndConditions(index3: widget.index);
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Scaffold(
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
        body: Column(
          children: [
            // Header Section
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
                          Navigator.of(context).pop();
                        },
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          "Recall Process",
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
                      Expanded(flex: 1, child: Text("")),
                    ],
                  ),
                ],
              ),
            ),
            // TO Info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.grey[600],
                    size:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 20
                        : Responsive.isTabletPortrait(context)
                        ? 25
                        : 25,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.transferId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 18
                                : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                          ),
                        ),
                        Text(
                          '${widget.order.fromLocation} → ${widget.order.toLocation}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 14
                                : Responsive.isTabletPortrait(context)
                                ? 18
                                : 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Quantity', currentStep >= 0),
                  Expanded(child: Divider()),
                  if (_hasDiscrepancies()) ...[
                    _buildStepIndicator(1, _getStep2Title(), currentStep >= 1),
                    Expanded(child: Divider()),
                  ],
                  _buildStepIndicator(2, 'Review', currentStep >= 2),
                ],
              ),
            ),
            SizedBox(height: 15),
            // Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildQuantityVerificationStep(),
                  if (_hasDiscrepancies()) _buildIMEIScanningStep(),
                  _buildReviewStep(),
                ],
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isProcessingRecall ? null : _previousStep,
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 15
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 16
                                : Responsive.isTabletPortrait(context)
                                ? 20
                                : 20,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionBtnColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (currentStep > 0) SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getNextButtonAction(),
                      child: _getNextButtonChild(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getNextButtonColor(),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  String _getStep2Title() {
    List<dynamic> discrepancyItems = widget.order.items.where((item) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int actual = actualQuantities[itemKey] ?? 0;
      return actual != item.quantity && actual > 0;
    }).toList();

    // Check if any discrepancy item is serialized
    bool hasSerializedItems = discrepancyItems.any((item) => item.serialized);
    bool hasNonSerializedItems = discrepancyItems.any(
      (item) => !item.serialized,
    );

    if (hasSerializedItems && hasNonSerializedItems) {
      return 'Verify'; // Mixed types
    } else if (hasSerializedItems) {
      return 'Scan'; // Only serialized items
    } else {
      return 'Capture'; // Only non-serialized items
    }
  }

  Widget _buildStepIndicator(int logicalStep, String title, bool isActive) {
    // Map logical steps to display numbers based on whether we have discrepancies
    int displayNumber;
    if (_hasDiscrepancies()) {
      displayNumber = logicalStep + 1; // Normal: 1, 2, 3
    } else {
      // Skip scan step: Quantity=1, Review=2
      if (logicalStep == 0)
        displayNumber = 1; // Quantity
      else if (logicalStep == 2)
        displayNumber = 2; // Review
      else
        displayNumber = logicalStep + 1; // Fallback
    }

    return Column(
      children: [
        Container(
          width:
              Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 32
              : Responsive.isTabletPortrait(context)
              ? 40
              : 40,
          height:
              Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 32
              : Responsive.isTabletPortrait(context)
              ? 40
              : 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFFFF8C00) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$displayNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize:
                    Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 14
                    : Responsive.isTabletPortrait(context)
                    ? 18
                    : 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 12
                : Responsive.isTabletPortrait(context)
                ? 18
                : 18,
            color: isActive ? Color(0xFFFF8C00) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // QUANTITY VERIFICATION STEP (PHASE 1)

  Widget _buildQuantityVerificationStep() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.order.items.length,
      itemBuilder: (context, index) {
        final item = widget.order.items[index];
        String itemKey = '${item.model}_${item.primaryIdentifier}';

        return Card(
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Info
                Text(
                  item.model,
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
                SizedBox(height: 4),
                Text(
                  '${item.brand} • ${item.category}',
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
                SizedBox(height: item.serialized && item.quantity > 1 ? 1 : 4),

                if (item.serialized)
                  Text(
                    item.quantity > 1
                        // ? '${item.quantity} serialized units'
                        ? ""
                        : item.imeis != null
                        ? "IMEI : ${item.primaryIdentifier}"
                        : 'Serial Number: ${item.primaryIdentifier}',
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

                SizedBox(height: item.serialized && item.quantity > 1 ? 1 : 12),

                // Quantity Section
                Row(
                  children: [
                    // Expected Quantity
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expected Qty',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 12
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 13
                                  : Responsive.isTabletPortrait(context)
                                  ? 18
                                  : 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 20
                                  : Responsive.isTabletPortrait(context)
                                  ? 40
                                  : 40,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 15
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                    ? 20
                                    : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Actual Quantity Input
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actual Qty',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 12
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 13
                                  : Responsive.isTabletPortrait(context)
                                  ? 18
                                  : 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 5),
                          TextFormField(
                            style: TextStyle(
                              fontSize:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 16
                                  : Responsive.isTabletPortrait(context)
                                  ? 20
                                  : 20,
                            ),
                            controller: quantityControllers[itemKey],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Color(0xFFFF8C00),
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  actualQuantities[itemKey] = null;
                                } else {
                                  actualQuantities[itemKey] = int.tryParse(
                                    value,
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Status Indicator
                SizedBox(height: 12),
                _buildQuantityStatus(item, itemKey),
                // Variance Reason Section (add this after _buildQuantityStatus)
                if (actualQuantities[itemKey] != null &&
                    actualQuantities[itemKey]! < item.quantity) ...[
                  SizedBox(height: 12),
                  Text(
                    'Variance Reason',
                    style: TextStyle(
                      fontSize:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  TextField(
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: Responsive.isMobileSmall(context)
                          ? 13
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 14.5
                          : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
                    ),
                    controller: varianceReasonControllers[itemKey],
                    decoration: InputDecoration(
                      hintText:
                          'Explain why actual quantity is less than expected',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 13
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 19
                            : 19,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Color(0xFFFF8C00)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild to update button state
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // SCAN / CAPTURE STEP (PHASE 2)

  Widget _buildIMEIScanningStep() {
    List<dynamic> discrepancyItems = widget.order.items.where((item) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      int actual = actualQuantities[itemKey] ?? 0;
      return actual != item.quantity;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: discrepancyItems.length,
      itemBuilder: (context, index) {
        final item = discrepancyItems[index];
        String itemKey = '${item.model}_${item.primaryIdentifier}';
        int actualQty = actualQuantities[itemKey] ?? 0;
        int expectedQty = item.quantity;

        return Card(
          color: Colors.white,
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.model,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 16
                                  : Responsive.isTabletPortrait(context)
                                  ? 22
                                  : 22,
                            ),
                          ),
                          Text(
                            '${item.brand} • ${item.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 14
                                  : Responsive.isTabletPortrait(context)
                                  ? 18
                                  : 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Quantity Info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Expected: $expectedQty',
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
                      Text(
                        'Actual: $actualQty',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
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
                ),

                SizedBox(height: 16),

                // IMEI Scanning Section
                if (actualQty > 0) ...[
                  Text(
                    item.serialized
                        ? 'Scan Received Items ($actualQty items)'
                        : 'Capture Received Items ($actualQty items)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Scan Button
                  OutlinedButton.icon(
                    onPressed: item.serialized
                        ? (scannedIMEIs[itemKey]!.length < actualQty
                              ? () => _navigateToIMEIScanner(item, itemKey)
                              : null)
                        : (capturedImages[itemKey]!.length < 3
                              ? () => _captureImage(itemKey)
                              : null),
                    icon: Icon(
                      item.serialized
                          ? Icons.qr_code_scanner
                          : Icons.camera_alt,
                      size: Responsive.isMobileSmall(context)
                          ? 17
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 18
                          : Responsive.isTabletPortrait(context)
                          ? 25
                          : 25,
                    ),
                    label: Text(
                      item.serialized ? 'Scan IMEI/SN' : 'Take Photo',
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
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFFF8C00)),
                      foregroundColor: Color(0xFFFF8C00),
                    ),
                  ),

                  // Scanned IMEIs List
                  if (scannedIMEIs[itemKey]!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: scannedIMEIs[itemKey]!.asMap().entries.map((
                          entry,
                        ) {
                          int index = entry.key;
                          String imei = entry.value;
                          return Chip(
                            label: Text(
                              imei,
                              style: TextStyle(
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
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                scannedIMEIs[itemKey]!.removeAt(index);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  // After the OutlinedButton.icon section, add:

                  // Display captured images for non-serialized items
                  if (!item.serialized && capturedImages[itemKey]!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Captured Photos (${capturedImages[itemKey]!.length}/3)',
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
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: capturedImages[itemKey]!
                                .asMap()
                                .entries
                                .map((entry) {
                                  int index = entry.key;
                                  File imageFile = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            imageFile,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: IconButton(
                                          onPressed: () =>
                                              _removeImage(itemKey, index),
                                          icon: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size:
                                                  Responsive.isMobileSmall(
                                                    context,
                                                  )
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
                                                  ? 20
                                                  : 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 5),
                ],

                // Notes Section
                Text(
                  'Reason for Variance',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 13
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 14
                        : Responsive.isTabletPortrait(context)
                        ? 17
                        : 17,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  style: TextStyle(color: Colors.black54),
                  // controller: notesControllers[itemKey],
                  controller: varianceReasonControllers[itemKey],
                  readOnly: true,
                  enabled: false,
                  maxLines: 2,
                  decoration: InputDecoration(
                    fillColor: Colors.grey[100],
                    filled: true,
                    hintText: 'Add notes about this mismatch...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFFF8C00)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Capture images of non-serialzied items if their expected and actual quantities are not eqal

  void _captureImage(String itemKey) async {
    if (capturedImages[itemKey]!.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum 3 photos allowed',
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
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          capturedImages[itemKey]!.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    }
  }

  // Remove captured images of non-serialzied items

  void _removeImage(String itemKey, int imageIndex) {
    setState(() {
      capturedImages[itemKey]!.removeAt(imageIndex);
    });
  }

  // REVIEW STEP (PHASE 3)

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recall Summary',
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
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildSummaryRow('Transfer Order', widget.order.transferId),
                  _buildSummaryRow(
                    'Total Items',
                    '${widget.order.items.length}',
                  ),
                  _buildSummaryRow(
                    'Status',
                    _hasDiscrepancies() ? 'Partially Sent' : 'Completed',
                  ),
                  if (_hasDiscrepancies())
                    _buildSummaryRow(
                      'Discrepancies',
                      '${widget.order.items.where((item) {
                        String itemKey = '${item.model}_${item.primaryIdentifier}';
                        int actual = actualQuantities[itemKey] ?? 0;
                        return actual != item.quantity;
                      }).length}',
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Items Review
          Text(
            'Items Review',
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 15
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 16
                  : Responsive.isTabletPortrait(context)
                  ? 24
                  : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 8
                : 16,
          ),

          ...widget.order.items.map((item) {
            String itemKey = '${item.model}_${item.primaryIdentifier}';
            int actualQty = actualQuantities[itemKey] ?? 0;
            bool hasDiscrepancy = actualQty != item.quantity;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.only(
                bottom:
                    Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 8
                    : 12,
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 12
                      : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.model,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 13
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 14
                                  : Responsive.isTabletPortrait(context)
                                  ? 20
                                  : 20,
                            ),
                          ),
                        ),
                        if (hasDiscrepancy)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Discrepancy',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize:
                                    Responsive.isMobileSmall(context) ||
                                        Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 10
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 4
                          : 15,
                    ),
                    Text(
                      'Expected: ${item.quantity} | Actual: $actualQty',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: Responsive.isMobileSmall(context)
                            ? 11
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 12
                            : Responsive.isTabletPortrait(context)
                            ? 20
                            : 20,
                      ),
                    ),
                    if (hasDiscrepancy &&
                        scannedIMEIs[itemKey]!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        item.imeis != null
                            ? 'IMEIs: ${scannedIMEIs[itemKey]!.join(', ')}'
                            : 'Serial Numbers: ${scannedIMEIs[itemKey]!.join(', ')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: Responsive.isMobileSmall(context)
                              ? 10
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 11
                              : Responsive.isTabletPortrait(context)
                              ? 15
                              : 15,
                        ),
                      ),
                    ],
                    if (hasDiscrepancy &&
                        // notesControllers[itemKey]!.text.isNotEmpty) ...[
                        varianceReasonControllers[itemKey]!
                            .text
                            .isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        // 'Notes: ${notesControllers[itemKey]!.text}',
                        'Variance Reasons: ${varianceReasonControllers[itemKey]!.text}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: Responsive.isMobileSmall(context)
                              ? 10
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 11
                              : Responsive.isTabletPortrait(context)
                              ? 15
                              : 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: Responsive.isMobileSmall(context)
                    ? 13
                    : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                    ? 14
                    : Responsive.isTabletPortrait(context)
                    ? 20
                    : 20,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.isMobileSmall(context)
                    ? 13
                    : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                    ? 14
                    : Responsive.isTabletPortrait(context)
                    ? 20
                    : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStatus(dynamic item, String itemKey) {
    int expected = item.quantity;
    int? actual = actualQuantities[itemKey];

    if (actual != null && actual > expected) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 16),
            SizedBox(width: 6),
            Text(
              'Actual cannot exceed expected ($expected)',
              style: TextStyle(
                color: Colors.red,
                fontSize:
                    Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 12
                    : Responsive.isTabletPortrait(context)
                    ? 16
                    : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  VoidCallback? _getNextButtonAction() {
    if (isProcessingRecall) return null;

    if (currentStep == 0 && !_isQuantityStepValid()) return null;
    if (currentStep == 1 && !_isIMEIScanningStepValid()) return null;
    if (currentStep == 2) return _completeRecall;

    return _nextStep;
  }

  Widget _getNextButtonChild() {
    if (isProcessingRecall) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Processing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.isMobileSmall(context)
                  ? 15
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
      );
    }

    if (currentStep == 2) {
      return Text(
        'Complete Recall',
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.isMobileSmall(context)
              ? 15
              : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
              ? 16
              : Responsive.isTabletPortrait(context)
              ? 20
              : 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(
      'Next',
      style: TextStyle(
        color: Colors.white,
        fontSize: Responsive.isMobileSmall(context)
            ? 15
            : Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
            ? 16
            : Responsive.isTabletPortrait(context)
            ? 20
            : 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getNextButtonColor() {
    if (isProcessingRecall) return Colors.grey[400]!;
    if (currentStep == 0 && !_isQuantityStepValid()) return Colors.grey[400]!;
    if (currentStep == 1 && !_isIMEIScanningStepValid())
      return Colors.grey[400]!;
    return Color(0xFFFF8C00);
  }
}
