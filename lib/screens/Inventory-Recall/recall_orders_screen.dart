import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/recall_transfer_order.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Inventory-Recall/order_details.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecallTransferOrdersScreen extends StatefulWidget {
  final int index;

  const RecallTransferOrdersScreen({super.key, required this.index});

  @override
  _RecallTransferOrdersScreenState createState() =>
      _RecallTransferOrdersScreenState();
}

class _RecallTransferOrdersScreenState
    extends State<RecallTransferOrdersScreen> {
  String selectedStatus = 'All';
  bool isLoading = true;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  late SharedPreferences _storage;
  List<RecallTransferOrder> transferOrdersNew = [];
  List<RecallTransferOrder> filteredOrdersNew = [];

  @override
  void initState() {
    super.initState();
    loadTransferOrders();
    getSharedPrefs();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userData = _storage.getString('user_data')!;
    employeeCode = _storage.getString('employee_code') ?? "";

    userObj = jsonDecode(userData);
  }

  Future<void> loadTransferOrders() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/recall_transfer_orders.json',
      );

      final data = json.decode(response);

      setState(() {
        transferOrdersNew = (data['recall_transfer_orders'] as List)
            .map((order) => RecallTransferOrder.fromJson(order))
            .toList();
        filteredOrdersNew = transferOrdersNew;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transfer orders: $e')),
      );
    }
  }

  void filterOrders(String status) {
    setState(() {
      selectedStatus = status;
      if (status == 'All') {
        filteredOrdersNew = transferOrdersNew;
      } else {
        filteredOrdersNew = transferOrdersNew
            .where((order) => order.status == status)
            .toList();
      }
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
              // --------- App Logo ---------- //
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
              // --------- Company Logo ---------- //
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
                    value: choice,
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
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
            : Column(
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
                                // Navigator.of(context).pop();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HomeScreen(index2: widget.index),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                "Recall Tarnsfer Orders",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: screenHeadingColor,
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 22
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 25
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

                  // Filter Chips
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    // color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Sent', 'Partial']
                            .map(
                              (status) => Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    status,
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
                                          : Responsive.isTabletPortrait(context)
                                          ? 22
                                          : 22,
                                    ),
                                  ),
                                  selected: selectedStatus == status,
                                  onSelected: (selected) =>
                                      filterOrders(status),
                                  selectedColor: Color(
                                    0xFFFF8C00,
                                  ).withOpacity(0.2),
                                  checkmarkColor: Color(0xFFFF8C00),
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  // Orders Count
                  Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: Color(0xFFFF8C00)),
                        SizedBox(width: 8),
                        Text(
                          '${filteredOrdersNew.length} Transfer Orders',
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
                      ],
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child: filteredOrdersNew.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No transfer orders found',
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 16
                                        : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                        ? 18
                                        : Responsive.isTabletPortrait(context)
                                        ? 25
                                        : 25,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadTransferOrders,
                            color: Color(0xFFFF8C00),
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredOrdersNew.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrdersNew[index];
                                return TransferOrderCard(
                                  order: order,
                                  onTap: () => navigateToOrderDetails(order),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void navigateToOrderDetails(RecallTransferOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecallOrderDetailsScreen(order: order, index: widget.index),
      ),
    );
  }
}

// Transfer Order Card Widget
class TransferOrderCard extends StatelessWidget {
  final RecallTransferOrder order;
  final VoidCallback onTap;

  const TransferOrderCard({Key? key, required this.order, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.transferId,
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
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(order.status),
                          size:
                              Responsive.isMobileSmall(context) ||
                                  Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 16
                              : Responsive.isTabletPortrait(context)
                              ? 25
                              : 25,
                          color: getStatusColor(order.status),
                        ),
                        SizedBox(width: 4),
                        Text(
                          order.status,
                          style: TextStyle(
                            color: getStatusColor(order.status),
                            fontWeight: FontWeight.w600,
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
                ],
              ),

              SizedBox(height: 12),

              // Location Info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size:
                        Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 16
                        : Responsive.isTabletPortrait(context)
                        ? 20
                        : 20,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.fromLocation} → ${order.toLocation}',
                      style: TextStyle(
                        fontSize:
                            Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 18
                            : 18,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Date and Items Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size:
                            Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 16
                            : Responsive.isTabletPortrait(context)
                            ? 20
                            : 20,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        order.assignedDate,
                        style: TextStyle(
                          fontSize: Responsive.isMobileSmall(context)
                              ? 14
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 14
                              : Responsive.isTabletPortrait(context)
                              ? 18
                              : 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${order.totalItems} items',
                      style: TextStyle(
                        fontSize:
                            Responsive.isMobileSmall(context) ||
                                Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 12
                            : Responsive.isTabletPortrait(context)
                            ? 15
                            : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'In-Transit':
        return Colors.blue;
      case 'Partial':
        return Color.fromARGB(255, 245, 161, 45);
      case 'Pending':
        return Colors.blue;
      case 'Sent':
        return Color.fromARGB(255, 55, 173, 59);
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'In-Transit':
        return Icons.local_shipping;
      case 'Sent':
        return Icons.check_circle;
      case 'Partial':
        return Icons.hourglass_top;
      case 'Pending':
        return Icons.pending_actions;
      default:
        return Icons.help;
    }
  }
}
