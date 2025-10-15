import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/transfer_order2.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventory-GRN/grn_process_screen.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailsScreenTwo extends StatefulWidget {
  final TransferOrder2 order;
  final int index;

  const OrderDetailsScreenTwo(
      {super.key, required this.order, required this.index});

  @override
  State<OrderDetailsScreenTwo> createState() => _OrderDetailsScreenTwoState();
}

class _OrderDetailsScreenTwoState extends State<OrderDetailsScreenTwo> {
  List<TransferOrder2> transferOrders = [];
  List<TransferOrder2> filteredOrders = [];
  String selectedStatus = 'All';
  bool isLoading = true;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  late SharedPreferences _storage;

  // Mock verification data - Replace with actual API data
  Map<String, dynamic>? verificationDetails;

// Add these state variables to your _OrderDetailsScreenTwoState class
  Map<String, int?> actualQuantities = {};
  Map<String, TextEditingController> quantityControllers = {};
  bool isProcessingGRN = false;
  String grnStatus = '';

// Initialize controllers in initState()
  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    loadVerificationDetails();
    _initializeQuantityControllers();
  }

  void _initializeQuantityControllers() {
    for (var item in widget.order.items) {
      String itemKey = '${item.model}_${item.primaryIdentifier}';
      quantityControllers[itemKey] = TextEditingController();
      actualQuantities[itemKey] = 0;
    }
  }

// Dispose controllers
  @override
  void dispose() {
    quantityControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    userData = _storage.getString('user_data') ?? "";
    employeeCode = _storage.getString('employee_code') ?? "";

    if (userData.isNotEmpty) {
      try {
        userObj = jsonDecode(userData);
        setState(() {});
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
  }

  // Load verification details if TO is already verified
  Future<void> loadVerificationDetails() async {
    if (widget.order.status.toLowerCase() == 'received' ||
        widget.order.status.toLowerCase() == 'verified') {
      // Mock data - Replace with actual API call
      verificationDetails = {
        'verified_by': 'John Doe (WWW5)',
        'verified_date': '2025-08-18 14:30:00',
        'verified_items': widget.order.items.length,
        'total_items': widget.order.totalItems,
        'verification_notes': 'All items verified successfully',
        'discrepancies': [],
      };
      setState(() {});
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
            index3: widget.index,
          );
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs(
            index3: widget.index,
          );
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs(
            index3: widget.index,
          );
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions(
            index3: widget.index,
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

  // Get status color based on status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.green;
      case 'partially received':
        return Colors.orangeAccent;
      case 'in-transit':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get status icon based on status
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Icons.inventory;
      case 'partially received':
        return Icons.hourglass_top;
      case 'in-transit':
        return Icons.local_shipping;
      default:
        return Icons.help;
    }
  }

  // Check if GRN process can be started
  bool canStartGRN() {
    return widget.order.status.toLowerCase() == 'in-transit';
  }

  // Check if verification details should be shown
  bool shouldShowVerificationDetails() {
    return widget.order.status.toLowerCase() == 'verified' ||
        widget.order.status.toLowerCase() == 'received';
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
                child: userObj != null
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
              onSelected: choiceAction,
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          "Order Details",
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
                      Expanded(
                        flex: 1,
                        child: Text(""),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: getStatusColor(widget.order.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: getStatusColor(widget.order.status),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            getStatusIcon(widget.order.status),
                            color: getStatusColor(widget.order.status),
                            size: Responsive.isMobileSmall(context)
                                ? 24
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 25
                                    : Responsive.isTabletPortrait(context)
                                        ? 30
                                        : 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transfer Order Status',
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 13
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 14
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 18
                                                : 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.order.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(
                                                context) ||
                                            Responsive.isMobileMedium(
                                                context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 18
                                        : Responsive.isTabletPortrait(context)
                                            ? 24
                                            : 24,
                                    color: getStatusColor(widget.order.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order Info Card
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Information',
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
                            _buildInfoRow(
                                'Transfer ID', widget.order.transferId),
                            _buildInfoRow('From', widget.order.fromLocation),
                            _buildInfoRow('To', widget.order.toLocation),
                            _buildInfoRow(
                                'Assigned Date', widget.order.assignedDate),
                            _buildInfoRow('Status', widget.order.status),
                            _buildInfoRow(
                                'Total Items', '${widget.order.totalItems}'),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Verification Details (only for Verified status)
                    if (shouldShowVerificationDetails() &&
                        verificationDetails != null)
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verification Details',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 16
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 18
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 24
                                                      : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildInfoRow('Verified By',
                                  verificationDetails!['verified_by']),
                              _buildInfoRow('Verified Date',
                                  verificationDetails!['verified_date']),
                              _buildInfoRow('Items Verified',
                                  '${verificationDetails!['verified_items']}/${verificationDetails!['total_items']}'),
                              _buildInfoRow('Notes',
                                  verificationDetails!['verification_notes']),
                            ],
                          ),
                        ),
                      ),

                    if (shouldShowVerificationDetails()) SizedBox(height: 16),

                    // GRN Action Button (only for Received status)
                    if (canStartGRN())
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GRNProcessScreen(
                                  order: widget.order,
                                  index: widget.index,
                                  userObj: userObj,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: Responsive.isMobileSmall(context)
                                ? 24
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 25
                                    : Responsive.isTabletPortrait(context)
                                        ? 30
                                        : 30,
                          ),
                          label: Text(
                            'START GRN PROCESS',
                            style: TextStyle(
                              color: Colors.white,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionBtnColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                    // Status Information Banner
                    if (!canStartGRN())
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 20
                                  : Responsive.isTabletPortrait(context)
                                      ? 25
                                      : 25,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.order.status.toLowerCase() ==
                                            'received' ||
                                        widget.order.status.toLowerCase() ==
                                            'partially received'
                                    ? 'This transfer order has already been verified and processed.'
                                    : widget.order.status.toLowerCase() ==
                                            'in-transit'
                                        ? 'This transfer order is currently in-transit. GRN process will be available once received.'
                                        : 'GRN process is not available for this status.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
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
                      ),
                    SizedBox(height: 10),
                    // Items List
                    Text(
                      'Items (${widget.order.items.length})',
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 16
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 17
                                : Responsive.isTabletPortrait(context)
                                    ? 22
                                    : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 12),

                    // Items Cards
                    ...widget.order.items
                        .map((item) => Card(
                              color: Colors.white,
                              margin: EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                title: Text(
                                  item.model,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 15
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 20,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 3),
                                    Text(
                                      '${item.brand} • ${item.category}',
                                      style: TextStyle(
                                        fontSize: Responsive.isMobileSmall(
                                                context)
                                            ? 13
                                            : Responsive.isMobileMedium(
                                                        context) ||
                                                    Responsive.isMobileLarge(
                                                        context)
                                                ? 14
                                                : Responsive.isTabletPortrait(
                                                        context)
                                                    ? 18
                                                    : 18,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            item.serialized && item.quantity > 1
                                                ? 0
                                                : 3),
                                    if (item.serialized)
                                      Text(
                                        item.quantity > 1
                                            ? ""
                                            : item.imeis != null
                                                ? "IMEI : ${item.primaryIdentifier}"
                                                : 'SN: ${item.primaryIdentifier}',
                                        style: TextStyle(
                                          fontSize: Responsive.isMobileSmall(
                                                  context)
                                              ? 11
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 12
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 15
                                                      : 15,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Qty: ${item.quantity}',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                              ? 11
                                              : Responsive.isMobileMedium(
                                                          context) ||
                                                      Responsive.isMobileLarge(
                                                          context)
                                                  ? 12
                                                  : Responsive.isTabletPortrait(
                                                          context)
                                                      ? 18
                                                      : 18,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              width: 100,
              child: Text(
                '$label :',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
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
}
