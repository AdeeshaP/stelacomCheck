import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/app-services/submitted_device_service.dart';
import 'package:stelacom_check/app-services/verification_email_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/netsuite_device_item.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetsuiteVerificationResultsScreen extends StatefulWidget {
  final int index;
  final List<NetsuiteDeviceItem> deviceList;
  final Function(List<NetsuiteDeviceItem>)? onDeviceListUpdated;
  final String? locationId;
  final String? location;

  const NetsuiteVerificationResultsScreen({
    super.key,
    required this.index,
    required this.deviceList,
    this.onDeviceListUpdated,
    required this.location,
    required this.locationId,
  });

  @override
  _NetsuiteVerificationResultsScreenState createState() =>
      _NetsuiteVerificationResultsScreenState();
}

class _NetsuiteVerificationResultsScreenState
    extends State<NetsuiteVerificationResultsScreen>
    with WidgetsBindingObserver {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  final ImagePicker _picker = ImagePicker();
  List<NetsuiteDeviceItem> deviceList = [];
  String searchQuery = "";
  String filterStatus = "All";
  int _currentPage = 0;
  int _rowsPerPage = 5;
  DeviceDataSource? _dataSource;
  bool _reportSubmitted = false;

  @override
  void initState() {
    super.initState();
    deviceList = List.from(widget.deviceList);
    _initializeDataSource();
    getSharedPrefs();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app returns to foreground after email app
    if (state == AppLifecycleState.resumed && _reportSubmitted) {
      _reportSubmitted = false;

      // Navigate to home screen
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(index2: widget.index),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  void _initializeDataSource() {
    _dataSource = DeviceDataSource(
      deviceList: filteredDeviceList,
      context: context,
      onUnverifiedAction: _showUnverifiedItemActions,
    );
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
    print(_currentPage);
  }

  Future<void> _saveDeviceListToStorage() async {
    print('Device list saved to memory only');
  }

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
      // _storage.clear();
      // Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
      //   (route) => false,
      // );
      LogoutService.logoutWithOptions(context);
    }
  }

  List<NetsuiteDeviceItem> get filteredDeviceList {
    List<NetsuiteDeviceItem> filtered = deviceList;

    // Apply status filter
    switch (filterStatus) {
      case "Verified":
        filtered = filtered.where((item) => item.isVerified).toList();
        break;
      case "Unverified":
        filtered = filtered.where((item) => !item.isVerified).toList();
        break;
      case "Serialized":
        filtered = filtered.where((item) => item.isSerialized).toList();
        break;
      case "Non-Serialized":
        filtered = filtered.where((item) => !item.isSerialized).toList();
        break;
      default:
        break;
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final query = searchQuery.toLowerCase();
        return item.item.toLowerCase().contains(query) ||
            (item.serialNumber?.toLowerCase().contains(query) ?? false) ||
            item.itemCode.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  int get verifiedCount => deviceList.where((item) => item.isVerified).length;
  int get totalCount => deviceList.length;
  int get serializedCount =>
      deviceList.where((item) => item.isSerialized).length;
  int get nonSerializedCount =>
      deviceList.where((item) => !item.isSerialized).length;
  bool get allItemsVerified => verifiedCount == totalCount;

  void _updateDataSource() {
    setState(() {
      _dataSource = DeviceDataSource(
        deviceList: filteredDeviceList,
        context: context,
        onUnverifiedAction: _showUnverifiedItemActions,
      );
    });
  }

  void _showUnverifiedItemActions(NetsuiteDeviceItem item) {
    if (!item.isSerialized) {
      _showQuantityUpdateDialogForNZ(item);
    } else {
      _showSerializedItemActions(item);
    }
  }

  // Serialized item actions dialog

  void _showSerializedItemActions(NetsuiteDeviceItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // backgroundColor: Colors.white,
          title: Text(
            'Unverified Item Actions',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Code: ${item.itemCode}',
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
              Text(
                'Number: ${item.serialNumber ?? "N/A"}',
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
              Text(
                'Model: ${item.item}',
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
              SizedBox(height: 16),
              Text(
                'Choose an action:',
                style: TextStyle(
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pop(context, deviceList);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please scan the barcode for: ${item.item}',
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                'Rescan',
                style: TextStyle(
                  color: actionBtnColor,
                  fontWeight: FontWeight.w600,
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showVarianceReasonDialog(item);
              },
              child: Text(
                'Add Variance Reason',
                style: TextStyle(
                  color: actionBtnColor,
                  fontWeight: FontWeight.w600,
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  void _showQuantityUpdateDialogForNZ(NetsuiteDeviceItem item) {
    TextEditingController quantityController = TextEditingController();
    TextEditingController varianceReasonController = TextEditingController();

    bool imagesCaptured = false;
    List<File> localAttachedImages = [];
    bool isValidQuantity = false;
    String? selectedVarianceReason;
    String? quantityError;

    // Function to show full-screen image
    void _showFullScreenImage(File imageFile) {
      FocusScope.of(context).unfocus();

      showDialog(
        context: context,
        barrierColor: Colors.black,
        builder: (BuildContext context) {
          return Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(imageFile, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus();
                      },
                      icon: Icon(
                        Icons.close,
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
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tap and drag to pan • Pinch to zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 13
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                            ? 18
                            : 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        FocusScope.of(context).unfocus();
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enteredText = quantityController.text.trim();
            final enteredQuantity = int.tryParse(enteredText);

            // ✅ FIXED LOGIC: Determine when variance reason is needed
            final needsVarianceReason =
                enteredQuantity != null &&
                isValidQuantity &&
                enteredQuantity != item.quantity;

            // ✅ FIXED LOGIC: Photo is only allowed when quantity > 0
            final canTakePhoto = isValidQuantity && enteredQuantity! > 0;

            // ✅ FIXED LOGIC: Enable Update button based on conditions
            final canUpdate =
                isValidQuantity &&
                enteredQuantity != null &&
                // If quantity is 0, must have variance reason (no photo needed)
                (enteredQuantity == 0
                    ? (selectedVarianceReason != null &&
                          selectedVarianceReason!.trim().isNotEmpty)
                    : // If quantity > 0 and matches total, only photo needed
                      enteredQuantity == item.quantity
                    ? imagesCaptured
                    : // If quantity > 0 but doesn't match, need both photo and variance reason
                      imagesCaptured &&
                          selectedVarianceReason != null &&
                          selectedVarianceReason!.trim().isNotEmpty);

            return AlertDialog(
              title: Text(
                'Update Verified Quantity',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model: ${item.item}',
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
                    SizedBox(height: 5),
                    Text(
                      'Total Quantity: ${item.quantity}',
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
                    SizedBox(height: 5),
                    Text(
                      'Currently Verified: ${item.quantityVerified}',
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
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Verified Quantity',
                        labelStyle: TextStyle(
                          color: Colors.black54,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 15
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 16
                              : Responsive.isTabletPortrait(context)
                              ? 20
                              : 20,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: quantityError != null
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: quantityError != null
                                ? Colors.red
                                : Colors.black54,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: quantityError != null
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        hintText: 'Enter quantity (0 to ${item.quantity})',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 13
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 14
                              : Responsive.isTabletPortrait(context)
                              ? 18
                              : 18,
                        ),
                        errorText: quantityError,
                        errorStyle: TextStyle(
                          color: Colors.red,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 12
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 13
                              : Responsive.isTabletPortrait(context)
                              ? 16
                              : 16,
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          final newQuantity = int.tryParse(value.trim());

                          // Validate and set error messages
                          if (value.trim().isEmpty) {
                            quantityError = null;
                            isValidQuantity = false;
                          } else if (newQuantity == null) {
                            quantityError = 'Please enter a valid number';
                            isValidQuantity = false;
                          } else if (newQuantity < 0) {
                            quantityError = 'Quantity cannot be negative';
                            isValidQuantity = false;
                          } else if (newQuantity > item.quantity!) {
                            quantityError =
                                'Cannot exceed total quantity (${item.quantity})';
                            isValidQuantity = false;
                          } else {
                            quantityError = null;
                            isValidQuantity = true;
                          }

                          // Reset variance reason and images when quantity changes
                          selectedVarianceReason = null;
                          varianceReasonController.clear();
                          localAttachedImages.clear();
                          imagesCaptured = false;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    // ✅ Show variance reason when needed (quantity != total quantity)
                    if (needsVarianceReason) ...[
                      Text(
                        'Reason for Variance *',
                        style: TextStyle(
                          fontSize: Responsive.isMobileSmall(context)
                              ? 15
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 16
                              : Responsive.isTabletPortrait(context)
                              ? 22
                              : 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: varianceReasonController,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          labelText: 'Enter variance reason',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black54,
                              width: 1,
                            ),
                          ),
                          hintText: enteredQuantity == 0
                              ? 'e.g., All items damaged/missing'
                              : 'e.g., Some items damaged, Missing items, etc.',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedVarianceReason = value.trim().isEmpty
                                ? null
                                : value.trim();
                          });
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // ✅ Show photo section only when quantity > 0
                    if (canTakePhoto) ...[
                      Row(
                        children: [
                          Text(
                            'Capture Bulk Photo',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 15
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 16
                                  : Responsive.isTabletPortrait(context)
                                  ? 22
                                  : 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final XFile? photo = await _picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 80,
                                maxWidth: 1024,
                                maxHeight: 1024,
                              );

                              if (photo != null) {
                                setDialogState(() {
                                  localAttachedImages.add(File(photo.path));
                                  imagesCaptured = true;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error taking picture: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.camera_alt,
                            color: Colors.green,
                            size:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 24
                                : Responsive.isTabletPortrait(context)
                                ? 30
                                : 30,
                          ),
                          label: Text(
                            'Take Photo',
                            style: TextStyle(
                              color: Colors.green,
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
                            side: BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Show captured images
                      if (imagesCaptured) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 18
                                  : Responsive.isTabletPortrait(context)
                                  ? 25
                                  : 25,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Image Captured',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 14
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: localAttachedImages.asMap().entries.map((
                                entry,
                              ) {
                                int index = entry.key;
                                File image = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showFullScreenImage(image),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              image,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              localAttachedImages.removeAt(
                                                index,
                                              );
                                              if (localAttachedImages.isEmpty) {
                                                imagesCaptured = false;
                                              }
                                            });
                                          },
                                          child: Container(
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
                                                  ? 20
                                                  : 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap image to view full screen',
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 11
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 12
                                : Responsive.isTabletPortrait(context)
                                ? 17
                                : 17,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
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
                ElevatedButton(
                  onPressed: canUpdate
                      ? () {
                          final newQuantity =
                              int.tryParse(quantityController.text.trim()) ?? 0;

                          setState(() {
                            item.quantityVerified = newQuantity;
                            item.isVerified = true;
                            item.verificationTime = DateTime.now();

                            if (newQuantity == 0) {
                              // Quantity is 0: variance reason only, no photo
                              item.varianceReason =
                                  selectedVarianceReason ?? "Unknown";
                            } else if (newQuantity != item.quantity) {
                              // Quantity doesn't match: variance reason + photo
                              item.varianceReason =
                                  selectedVarianceReason ?? "Unknown";
                            } else {
                              // Quantity matches: photo only
                              item.varianceReason = "Image Attached";
                            }
                          });

                          _saveDeviceListToStorage();
                          _updateDataSource();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newQuantity == 0
                                    ? 'Item marked with 0 quantity and variance reason'
                                    : 'Quantity updated and image attached for ${item.item}',
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
                              backgroundColor: Colors.green,
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUpdate ? actionBtnColor : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showVarianceReasonDialog(NetsuiteDeviceItem item) {
    TextEditingController reasonController = TextEditingController();
    String? selectedReason;

    List<String> commonReasons = [
      'Item damaged',
      'Item missing',
      'Item not in location',
      'Barcode unreadable',
      'Item sold out',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Variance Reason',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Code: ${item.itemCode}',
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
                      Text(
                        'Number: ${item.serialNumber ?? "N/A"}',
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
                      Text(
                        'Model: ${item.item}',
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
                      SizedBox(height: 16),
                      Text(
                        'Select reason:',
                        style: TextStyle(
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
                      SizedBox(height: 8),
                      // Radio buttons list
                      ...commonReasons.map((reason) {
                        return RadioListTile<String>(
                          activeColor: actionBtnColor,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            reason,
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
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedReason = value;
                              if (value != 'Other') {
                                reasonController.text = value!;
                              } else {
                                reasonController.text = '';
                              }
                            });
                          },
                        );
                      }).toList(),
                      if (selectedReason == 'Other') ...[
                        SizedBox(height: 8),
                        TextField(
                          controller: reasonController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Enter custom reason...',
                            hintStyle: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 13
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 14
                                  : Responsive.isTabletPortrait(context)
                                  ? 18
                                  : 18,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: actionBtnColor,
                                width: 1,
                              ),
                            ),
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            // THIS IS THE KEY FIX - Update the dialog state when typing
                            setDialogState(() {
                              // This will trigger rebuild and enable/disable Submit button
                            });

                            // Scroll to bottom when user starts typing
                            Future.delayed(Duration(milliseconds: 100), () {
                              if (context.mounted) {
                                Scrollable.ensureVisible(
                                  context,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
                        ),
                        SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
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
                ElevatedButton(
                  onPressed:
                      selectedReason != null &&
                          (selectedReason != 'Other' ||
                              reasonController.text.trim().isNotEmpty)
                      ? () {
                          setState(() {
                            item.varianceReason =
                                reasonController.text.trim().isEmpty
                                ? selectedReason
                                : reasonController.text.trim();
                            item.isVerified = true;
                            item.verificationTime = DateTime.now();
                          });
                          _saveDeviceListToStorage();
                          _updateDataSource();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Variance reason added and item verified for ${item.item}',
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<NetsuiteDeviceItem> filteredList = filteredDeviceList;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(deviceList);
        return false;
      },
      child: Scaffold(
        // key: _scaffoldKey,
        resizeToAvoidBottomInset: true,
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
        backgroundColor: appBgColor,
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
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(deviceList),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        "Verification Results",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: screenHeadingColor,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 20
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 22
                              : Responsive.isTabletPortrait(context)
                              ? 27
                              : 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(flex: 1, child: Text("")),
                  ],
                ),
              ),
              SizedBox(height: 10),

              // Summary Cards
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size:
                                    Responsive.isMobileSmall(context) ||
                                        Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 20
                                    : Responsive.isTabletPortrait(context)
                                    ? 30
                                    : 30,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$verifiedCount',
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
                                'Verified',
                                style: TextStyle(
                                  fontSize:
                                      Responsive.isMobileSmall(context) ||
                                          Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 10
                                      : Responsive.isTabletPortrait(context)
                                      ? 15
                                      : 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(height: 4),
                              Text(
                                '${totalCount - verifiedCount}',
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
                                'Unverified',
                                style: TextStyle(
                                  fontSize:
                                      Responsive.isMobileSmall(context) ||
                                          Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 10
                                      : Responsive.isTabletPortrait(context)
                                      ? 15
                                      : 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: Colors.grey,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$totalCount',
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
                                'Total',
                                style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 9
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 10
                                      : Responsive.isTabletPortrait(context)
                                      ? 16
                                      : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              // Search and Filter
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                          _updateDataSource();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search Model/Number/Item Code...',
                          hintStyle: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 13
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 14
                                : Responsive.isTabletPortrait(context)
                                ? 18
                                : 18,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size:
                                Responsive.isMobileSmall(context) ||
                                    Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 20
                                : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: actionBtnColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: filterStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: actionBtnColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                        items:
                            [
                              'All',
                              'Verified',
                              'Unverified',
                              'Serialized',
                              'Non-Serialized',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
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
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            filterStatus = value!;
                          });
                          _updateDataSource();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // DataTable with Pagination
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
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
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No items found',
                                style: TextStyle(
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 16
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 18
                                      : Responsive.isTabletPortrait(context)
                                      ? 25
                                      : 25,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Results: ${filteredList.length}',
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
                                          : Responsive.isTabletPortrait(context)
                                          ? 20
                                          : 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Rows per page: ',
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
                                        ),
                                      ),
                                      DropdownButton<int>(
                                        value: _rowsPerPage,
                                        underline: SizedBox(),
                                        items: [5, 10, 25, 50].map((int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              value.toString(),
                                              style: TextStyle(
                                                fontSize:
                                                    Responsive.isMobileSmall(
                                                      context,
                                                    )
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
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _rowsPerPage = value!;
                                            _currentPage = 0;
                                          });
                                          _updateDataSource();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1),
                            Expanded(
                              child: _dataSource != null
                                  ? SingleChildScrollView(
                                      child: PaginatedDataTable(
                                        dataRowMaxHeight: 50,
                                        header: null,
                                        headingRowColor: WidgetStatePropertyAll(
                                          Colors.grey[100],
                                        ),
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              'Number',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobileSmall(
                                                      context,
                                                    )
                                                    ? 11
                                                    : Responsive.isMobileMedium(
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
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Model',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobileSmall(
                                                      context,
                                                    )
                                                    ? 11
                                                    : Responsive.isMobileMedium(
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
                                          ),
                                          // DataColumn(
                                          //   label: Text(
                                          //     'Type',
                                          //     style: TextStyle(
                                          //       fontWeight: FontWeight.bold,
                                          //       fontSize:
                                          //           Responsive.isMobileSmall(
                                          //             context,
                                          //           )
                                          //           ? 11
                                          //           : Responsive.isMobileMedium(
                                          //                   context,
                                          //                 ) ||
                                          //                 Responsive.isMobileLarge(
                                          //                   context,
                                          //                 )
                                          //           ? 12
                                          //           : Responsive.isTabletPortrait(
                                          //               context,
                                          //             )
                                          //           ? 18
                                          //           : 18,
                                          //     ),
                                          //   ),
                                          // ),
                                          DataColumn(
                                            label: Text(
                                              'Verify\nStatus',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobileSmall(
                                                      context,
                                                    )
                                                    ? 11
                                                    : Responsive.isMobileMedium(
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
                                          ),
                                          DataColumn(
                                            label: Text(
                                              '  Action',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobileSmall(
                                                      context,
                                                    )
                                                    ? 11
                                                    : Responsive.isMobileMedium(
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
                                          ),
                                        ],
                                        source: _dataSource!,
                                        rowsPerPage: _rowsPerPage,
                                        showCheckboxColumn: false,
                                        columnSpacing: 15,
                                        horizontalMargin: 10,
                                        showFirstLastButtons: true,
                                      ),
                                    )
                                  : Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Submit Button
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: allItemsVerified
                        ? () {
                            _showSubmissionDialog();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allItemsVerified
                          ? actionBtnColor
                          : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      allItemsVerified
                          ? 'Submit Verification Report'
                          : 'Submit Verification Report (${totalCount - verifiedCount} items pending)',
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmissionDialog() {
    final TextEditingController _commentsController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return WillPopScope(
              onWillPop: () async =>
                  !isSubmitting, // Prevent back button during submission
              child: AlertDialog(
                // backgroundColor: Colors.white,
                title: Text(
                  'Submit Verification Report',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                content: isSubmitting
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: actionBtnColor),
                          SizedBox(height: 16),
                          Text(
                            'Generating report and opening email...',
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary:',
                              style: TextStyle(
                                color: Colors.black,
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
                            Text(
                              '• Verified: $verifiedCount items',
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
                            SizedBox(height: 3),
                            Text(
                              '• Unverified: ${totalCount - verifiedCount} items',
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
                            SizedBox(height: 3),
                            Text(
                              '• Serialized: $serializedCount items',
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
                            SizedBox(height: 3),
                            Text(
                              '• Non-serialized: $nonSerializedCount items',
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
                            SizedBox(height: 3),
                            Text(
                              '• Total: $totalCount items',
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
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email will be sent to:',
                                          style: TextStyle(
                                            fontSize:
                                                Responsive.isMobileSmall(
                                                  context,
                                                )
                                                ? 11
                                                : Responsive.isMobileMedium(
                                                        context,
                                                      ) ||
                                                      Responsive.isMobileLarge(
                                                        context,
                                                      )
                                                ? 12
                                                : Responsive.isTabletPortrait(
                                                    context,
                                                  )
                                                ? 17
                                                : 17,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          VerificationReportService
                                              .RECIPIENT_EMAIL,
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
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Additional Notes',
                              style: TextStyle(
                                color: Colors.black,
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
                            TextField(
                              controller: _commentsController,
                              maxLines: 3,
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                labelStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontSize: Responsive.isMobileSmall(context)
                                      ? 14
                                      : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                      ? 15
                                      : Responsive.isTabletPortrait(context)
                                      ? 20
                                      : 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: "Enter any extra notes here...",
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'An Excel report will be generated and your email app will open with the report attached.',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 12
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 13
                                    : Responsive.isTabletPortrait(context)
                                    ? 17
                                    : 17,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                actions: isSubmitting
                    ? []
                    : [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red, fontSize: 15),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Start loading state
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              // Generate Excel report
                              File excelFile =
                                  await VerificationReportService.generateExcelReport(
                                    deviceList: deviceList,
                                    locationName: widget.location ?? 'Unknown',
                                    additionalNotes:
                                        _commentsController.text.trim().isEmpty
                                        ? null
                                        : _commentsController.text.trim(),
                                    username: userObj != null
                                        ? userObj!["FirstName"] +
                                              " " +
                                              userObj!["LastName"]
                                        : 'Unknown',
                                  );

                              // ✨ NEW: Store submitted device identifiers
                              List<String> submittedIdentifiers = deviceList
                                  .where(
                                    (device) =>
                                        device.isVerified &&
                                        device.isSerialized,
                                  )
                                  .map(
                                    (device) =>
                                        device.scannableIdentifier ?? '',
                                  )
                                  .where((id) => id.isNotEmpty)
                                  .toList();

                              await SubmittedDevicesService.storeSubmittedDevices(
                                deviceIdentifiers: submittedIdentifiers,
                                locationId: widget.locationId ?? '',
                                locationDescription:
                                    widget.location ?? 'Unknown',
                                userId:
                                    userObj != null && userObj!['id'] != null
                                    ? userObj!['id'].toString()
                                    : '',
                              );

                              _reportSubmitted = true;

                              // Close the dialog BEFORE opening email
                              if (Navigator.canPop(dialogContext)) {
                                Navigator.pop(dialogContext);
                              }

                              await Future.delayed(Duration(milliseconds: 300));

                              await VerificationReportService.sendVerificationEmail(
                                excelFile: excelFile,
                                locationDescription:
                                    widget.location ?? 'Unknown',
                                verifiedCount: verifiedCount,
                                totalCount: totalCount,
                                username: userObj != null
                                    ? userObj!["FirstName"] +
                                          " " +
                                          userObj!["LastName"]
                                    : 'Unknown',
                                additionalNotes:
                                    _commentsController.text.trim().isEmpty
                                    ? null
                                    : _commentsController.text.trim(),
                              );

                              // This code runs when email app is opened
                              // The app is now in background, waiting for user action
                            } catch (e) {
                              // Reset flag on error
                              _reportSubmitted = false;

                              // Close dialog if still open
                              if (Navigator.canPop(dialogContext)) {
                                Navigator.pop(dialogContext);
                              }

                              // Check if widget is still mounted before showing error
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.white),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Failed to generate/send report: $e',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionBtnColor,
                            foregroundColor: Colors.white,
                          ),

                          child: Text('Submit', style: TextStyle(fontSize: 15)),
                        ),
                      ],
              ),
            );
          },
        );
      },
    );
  }
}

// DataSource class for PaginatedDataTable
class DeviceDataSource extends DataTableSource {
  final List<NetsuiteDeviceItem> deviceList;
  final BuildContext context;
  final Function(NetsuiteDeviceItem) onUnverifiedAction;

  DeviceDataSource({
    required this.deviceList,
    required this.context,
    required this.onUnverifiedAction,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= deviceList.length) return null;
    final item = deviceList[index];

    return DataRow(
      cells: [
        // Number Cell
        DataCell(
          Container(
            width: 80,
            // child: item.number != null
            //     ? Text(
            //         item.number!.length > 15
            //             ? item.number!.substring(0, 15) + '...'
            //             : item.number!,
            //         style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
            //       )
            //     : Text('N/A', style: TextStyle(fontSize: 10)),
            child: item.isSerialized == true && item.serialNumber != null
                ? Text(
                    item.serialNumber!.length > 30
                        ? item.serialNumber!.substring(0, 30) + '...'
                        : item.serialNumber!,
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  )
                : Text('N/A', style: TextStyle(fontSize: 10)),
          ),
        ),

        // Model Cell
        DataCell(
          Container(
            width: 100,
            child: Text(
              item.item,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Type Cell
        // DataCell(
        //   Container(
        //     width: 50,
        //     child: Text(
        //       item.deviceType == 'IMEI Device'
        //           ? 'IMEI'
        //           : item.deviceType == 'Serial Number Device'
        //           ? 'Serial'
        //           : 'Non\nSerial',
        //       style: TextStyle(
        //         fontSize: 9,
        //         fontWeight: FontWeight.w500,
        //         color: item.deviceType == 'IMEI Device'
        //             ? Colors.blue
        //             : item.deviceType == 'Serial Number Device'
        //             ? Colors.purple
        //             : Colors.orange,
        //       ),
        //     ),
        //   ),
        // ),

        // Status Cell
        DataCell(
          Container(
            width: 40,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isVerified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isVerified ? Icons.check_circle : Icons.cancel,
                  color: item.isVerified ? Colors.green : Colors.red,
                  size: 14,
                ),
              ),
            ),
          ),
        ),

        // Action Cell
        DataCell(
          Container(
            width: 50,
            child: Center(
              child: !item.isVerified
                  ? item.varianceReason != null
                        ? Text(
                            '${item.varianceReason}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                        : IconButton(
                            icon: Icon(
                              item.isSerialized
                                  ? Icons.edit_document
                                  : Icons.add_box,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            onPressed: () => onUnverifiedAction(item),
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          )
                  : item.varianceReason == "Image Attached"
                  ? Text(
                      'Image Attached',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  : item.varianceReason != null
                  ? Text(
                      '${item.varianceReason}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  : item.verificationTime != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 1),
                        Text(
                          '${item.verificationTime!.hour.toString().padLeft(2, '0')}:${item.verificationTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '-',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => deviceList.length;

  @override
  int get selectedRowCount => 0;
}
