import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/models/device_item.dart'; // Updated model
import 'package:stelacom_check/models/netsuite_device_item.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';
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
  final Function(List<DeviceItem>)? onDeviceListUpdated;

  const NetsuiteVerificationResultsScreen({
    super.key,
    required this.index,
    required this.deviceList,
    this.onDeviceListUpdated,
  });

  @override
  _NetsuiteVerificationResultsScreenState createState() =>
      _NetsuiteVerificationResultsScreenState();
}

class _NetsuiteVerificationResultsScreenState
    extends State<NetsuiteVerificationResultsScreen> {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String employeeCode = "";
  String userData = "";
  final ImagePicker _picker = ImagePicker();
  List<DeviceItem> deviceList = [];
  String searchQuery = "";
  String filterStatus = "All";
  // Pagination variables
  int _currentPage = 0;
  int _rowsPerPage = 5;
  DeviceDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    deviceList = List.from(widget.deviceList);
    _initializeDataSource();
    getSharedPrefs();
  }

  void _initializeDataSource() {
    _dataSource = DeviceDataSource(
      deviceList: filteredDeviceList,
      context: context,
      onUnverifiedAction: _showUnverifiedItemActions,
      onQuantityUpdate: _updateQuantityVerified,
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

  // Filter device list based on search and status filter
  List<DeviceItem> get filteredDeviceList {
    List<DeviceItem> filtered = deviceList;

    // Apply status filter
    switch (filterStatus) {
      case "Verified":
        filtered = filtered.where((item) => item.isVerified).toList();
        break;
      case "Unverified":
        filtered = filtered.where((item) => !item.isVerified).toList();
        break;
      case "Serialized":
        filtered = filtered.where((item) => item.serialized).toList();
        break;
      case "Non-Serialized":
        filtered = filtered.where((item) => !item.serialized).toList();
        break;
      default: // "All"
        break;
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final query = searchQuery.toLowerCase();
        return item.model.toLowerCase().contains(query) ||
            (item.imei?.toLowerCase().contains(query) ?? false) ||
            (item.serialNo?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  // Calculate verification statistics
  int get verifiedCount => deviceList.where((item) => item.isVerified).length;
  int get totalCount => deviceList.length;
  int get serializedCount => deviceList.where((item) => item.serialized).length;
  int get nonSerializedCount =>
      deviceList.where((item) => !item.serialized).length;
  bool get allItemsVerified => verifiedCount == totalCount;

  // Update data source when filters change
  void _updateDataSource() {
    setState(() {
      _dataSource = DeviceDataSource(
        deviceList: filteredDeviceList,
        context: context,
        onUnverifiedAction: _showUnverifiedItemActions,
        onQuantityUpdate: _updateQuantityVerified,
      );
    });
  }

  // Update quantity for non-serialized items
  void _updateQuantityVerified(DeviceItem item, int newQuantity) {
    setState(() {
      item.quantityVerified = newQuantity;
      item.isVerified = (newQuantity >= item.quantity!);
      item.verificationTime = DateTime.now();
    });
    _saveDeviceListToStorage();
    _updateDataSource();
  }

  // Show dialog for unverified item actions
  void _showUnverifiedItemActions(DeviceItem item) {
    if (!item.serialized) {
      _showQuantityUpdateDialogForNZ(item);
    } else {
      _showSerializedItemActions(item);
    }
  }

  void _showSerializedItemActions(DeviceItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unverified Item Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imei != null)
                Text(
                  'IMEI: ${item.imei}',
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
              if (item.serialNo != null)
                Text(
                  'Serial: ${item.serialNo}',
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
                'Model: ${item.model}',
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please scan the barcode for: ${item.model}',
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
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                  ),
                );
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
  
  void _showQuantityUpdateDialogForNZ(DeviceItem item) {
    TextEditingController quantityController = TextEditingController(
      text: item.quantityVerified.toString(),
    );

    // Add controller for variance reason text field
    TextEditingController varianceReasonController = TextEditingController();

    // Local state for this dialog
    bool imagesCaptured = false;
    List<File> localAttachedImages = [];
    bool isValidQuantity = item.quantityVerified > 0;
    String? selectedVarianceReason;

    // Function to show full-screen image
    void _showFullScreenImage(File imageFile) {
      // Dismiss keyboard before showing full-screen image
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
                        // Ensure keyboard stays dismissed after closing
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
        // Additional safety: dismiss keyboard when dialog is completely closed
        FocusScope.of(context).unfocus();
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Check if variance reason is needed
            final enteredQuantity = int.tryParse(quantityController.text) ?? 0;
            final needsVarianceReason =
                isValidQuantity && enteredQuantity != item.quantity;

            return AlertDialog(
              title: Text('Update Verified Quantity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model: ${item.model}',
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
                        labelText: 'Verified Quantity',
                        border: OutlineInputBorder(),
                        helperText: 'Enter quantity from 0 to ${item.quantity}',
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          final newQuantity = int.tryParse(value) ?? 0;
                          isValidQuantity =
                              newQuantity >= 0 && newQuantity <= item.quantity!;
                          // Reset variance reason when quantity changes
                          selectedVarianceReason = null;
                          varianceReasonController.clear();
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    // Show variance reason text field when quantity doesn't match
                    if (needsVarianceReason) ...[
                      Text(
                        'Reason for Variance',
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
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Damaged items, Missing items, etc.',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedVarianceReason = value.trim().isEmpty
                                ? null
                                : value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                    ],

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

                    // Single Camera button - enabled and colored when valid quantity
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isValidQuantity
                            ? () async {
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
                              }
                            : null, // Disabled when quantity invalid
                        icon: Icon(
                          Icons.camera_alt,
                          color: isValidQuantity ? Colors.green : Colors.grey,
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
                            color: isValidQuantity ? Colors.green : Colors.grey,
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
                          side: BorderSide(
                            color: isValidQuantity
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Show "Image Captured" text when image is taken
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

                      // Display captured images
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
                                    // Make the image tappable for full-screen view
                                    GestureDetector(
                                      onTap: () => _showFullScreenImage(image),
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
                                    // Close button
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setDialogState(() {
                                            localAttachedImages.removeAt(index);
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

                      // Add a hint text to show users they can tap to view
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
                      (imagesCaptured &&
                          isValidQuantity &&
                          (!needsVarianceReason ||
                              selectedVarianceReason != null))
                      ? () {
                          final newQuantity =
                              int.tryParse(quantityController.text) ?? 0;
                          if (newQuantity >= 0 &&
                              newQuantity <= item.quantity!) {
                            setState(() {
                              // Update the item
                              item.quantityVerified = newQuantity;
                              item.isVerified = true;
                              item.verificationTime = DateTime.now();

                              // Set variance reason
                              if (newQuantity != item.quantity) {
                                item.varianceReason =
                                    selectedVarianceReason ?? "Unknown";
                              } else {
                                item.varianceReason = "Image Attached";
                              }
                            });

                            _saveDeviceListToStorage();
                            _updateDataSource();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Quantity updated and image attached for ${item.model}',
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
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter a valid quantity (0-${item.quantity})',
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
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        imagesCaptured &&
                            isValidQuantity &&
                            (!needsVarianceReason ||
                                selectedVarianceReason != null)
                        ? actionBtnColor
                        : Colors.grey,
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

  // Show variance reason input dialog
  void _showVarianceReasonDialog(DeviceItem item) {
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
              title: Text('Variance Reason'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imei != null)
                    Text(
                      'IMEI: ${item.imei}',
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
                  if (item.serialNo != null)
                    Text(
                      'Serial: ${item.serialNo}',
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
                    'Model: ${item.model}',
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
                  Container(
                    height: 150,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: commonReasons.length,
                      itemBuilder: (context, index) {
                        return RadioListTile<String>(
                          activeColor: actionBtnColor,
                          title: Text(
                            commonReasons[index],
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
                          value: commonReasons[index],
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
                      },
                    ),
                  ),
                  if (selectedReason == 'Other')
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter custom reason...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                ],
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
                                'Variance reason added and item verified for ${item.model}',
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
                    style: TextStyle(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<DeviceItem> filteredList = filteredDeviceList;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(deviceList);
        return false;
      },
      child: Scaffold(
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
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // Header
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
              ),
              SizedBox(height: 10),

              // Summary Cards
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
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
                                            Responsive.isMobileMedium(
                                              context,
                                            ) ||
                                            Responsive.isMobileLarge(context)
                                        ? 20
                                        : Responsive.isTabletPortrait(context)
                                        ? 25
                                        : 25,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$verifiedCount',
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                          ? 9.5
                                          : Responsive.isMobileMedium(
                                                  context,
                                                ) ||
                                                Responsive.isMobileLarge(
                                                  context,
                                                )
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
                                    Icons.cancel,
                                    color: Colors.red,
                                    size:
                                        Responsive.isMobileSmall(context) ||
                                            Responsive.isMobileMedium(
                                              context,
                                            ) ||
                                            Responsive.isMobileLarge(context)
                                        ? 20
                                        : Responsive.isTabletPortrait(context)
                                        ? 25
                                        : 25,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${totalCount - verifiedCount}',
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Unverified',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                          ? 9.5
                                          : Responsive.isMobileMedium(
                                                  context,
                                                ) ||
                                                Responsive.isMobileLarge(
                                                  context,
                                                )
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
                                    size:
                                        Responsive.isMobileSmall(context) ||
                                            Responsive.isMobileMedium(
                                              context,
                                            ) ||
                                            Responsive.isMobileLarge(context)
                                        ? 20
                                        : Responsive.isTabletPortrait(context)
                                        ? 24
                                        : 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$totalCount',
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobileSmall(context)
                                          ? 9.5
                                          : Responsive.isMobileMedium(
                                                  context,
                                                ) ||
                                                Responsive.isMobileLarge(
                                                  context,
                                                )
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
                      ],
                    ),
                    SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Card(
                    //         color: Colors.white,
                    //         elevation: 2,
                    //         child: Padding(
                    //           padding: EdgeInsets.all(12),
                    //           child: Column(
                    //             children: [
                    //               Icon(Icons.qr_code,
                    //                   color: Colors.purple, size: 20),
                    //               SizedBox(height: 4),
                    //               Text('$serializedCount',
                    //                   style: TextStyle(
                    //                       fontSize: 16,
                    //                       fontWeight: FontWeight.bold)),
                    //               Text('Serialized',
                    //                   style: TextStyle(fontSize: 10)),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     SizedBox(width: 8),
                    //     Expanded(
                    //       child: Card(
                    //         color: Colors.white,
                    //         elevation: 2,
                    //         child: Padding(
                    //           padding: EdgeInsets.all(12),
                    //           child: Column(
                    //             children: [
                    //               Icon(Icons.inventory_2,
                    //                   color: Colors.orange, size: 20),
                    //               SizedBox(height: 4),
                    //               Text('$nonSerializedCount',
                    //                   style: TextStyle(
                    //                       fontSize: 16,
                    //                       fontWeight: FontWeight.bold)),
                    //               Text('Bulk Items',
                    //                   style: TextStyle(fontSize: 10)),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     Expanded(
                    //         child: SizedBox()), // Empty space for alignment
                    //   ],
                    // ),
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
                          hintText: 'Search Model/IMEI/Serial...',
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
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 216, 16, 2),
                            ),
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
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: const Color.fromARGB(255, 216, 16, 2),
                            ),
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
                                size:
                                    Responsive.isMobileSmall(context) ||
                                        Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 64
                                    : Responsive.isTabletPortrait(context)
                                    ? 80
                                    : 80,
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
                            // Rows per page selector
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

                            // DataTable
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
                                              'IMEI No/\nSerial No',
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
                                              ' Model',
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
                                              '   Action',
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

              // Action Buttons
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    SizedBox(
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
                                ? 20
                                : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Submit Verification Report',
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 20
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 25
                  : Responsive.isTabletPortrait(context)
                  ? 30
                  : 30,
            ),
          ),
          content: SingleChildScrollView(
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
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
                        ? 20
                        : 20,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _commentsController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 15
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 16
                        : Responsive.isTabletPortrait(context)
                        ? 22
                        : 22,
                  ),
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
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
                          ? 19
                          : 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 216, 16, 2),
                      ),
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
                  'Are you sure you want to submit this verification report?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12.5
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 14
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveDeviceListToStorage();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Verification report submitted successfully!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                // Navigator.of(context).pop(deviceList);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(index2: widget.index),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 14
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionBtnColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

// DataSource class for PaginatedDataTable
class DeviceDataSource extends DataTableSource {
  final List<DeviceItem> deviceList;
  final BuildContext context;
  final Function(DeviceItem) onUnverifiedAction;
  final Function(DeviceItem, int) onQuantityUpdate;

  DeviceDataSource({
    required this.deviceList,
    required this.context,
    required this.onUnverifiedAction,
    required this.onQuantityUpdate,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= deviceList.length) return null;
    final item = deviceList[index];

    return DataRow(
      cells: [
        // ID/Serial Cell
        DataCell(
          Container(
            width: 100,
            child: item.serialized
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.imei != null)
                          Text(
                            'IMEI: ${item.imei!.length > 14 ? item.imei!.substring(0, 14) + '...' : item.imei}',
                            style: TextStyle(
                              fontSize:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 9
                                  : Responsive.isTabletPortrait(context)
                                  ? 13
                                  : 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (item.serialNo != null)
                          Text(
                            'SN: ${item.serialNo}',
                            style: TextStyle(
                              fontSize:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 9
                                  : Responsive.isTabletPortrait(context)
                                  ? 13
                                  : 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  )
                : Text(
                    // 'Qty: ${item.quantityVerified ?? 0}/${item.quantity ?? 0}',
                    'N/A',
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 9
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 10
                          : Responsive.isTabletPortrait(context)
                          ? 16
                          : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),

        // Model Cell
        DataCell(
          Container(
            width: 90,
            child: Text(
              item.model,
              style: TextStyle(
                fontSize: Responsive.isMobileSmall(context)
                    ? 10
                    : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                    ? 11
                    : Responsive.isTabletPortrait(context)
                    ? 15
                    : 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isVerified ? Icons.check_circle : Icons.cancel,
                      color: item.isVerified ? Colors.green : Colors.red,
                      size:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action/Time Cell
        DataCell(
          Container(
            width: 50,
            child: Center(
              child: !item.isVerified
                  ? item.varianceReason != null
                        ? Text(
                            '${item.varianceReason}',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 9
                                  : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                  ? 9.5
                                  : Responsive.isTabletPortrait(context)
                                  ? 14
                                  : 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                        : IconButton(
                            icon: Icon(
                              item.serialized
                                  ? Icons.edit_document
                                  : Icons.add_box,
                              color: Colors.grey[400],
                              size:
                                  Responsive.isMobileSmall(context) ||
                                      Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 18
                                  : Responsive.isTabletPortrait(context)
                                  ? 24
                                  : 24,
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
                        fontSize: Responsive.isMobileSmall(context)
                            ? 9
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 9.5
                            : Responsive.isTabletPortrait(context)
                            ? 14
                            : 14,
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
                        fontSize: Responsive.isMobileSmall(context)
                            ? 9
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 9.5
                            : Responsive.isTabletPortrait(context)
                            ? 14
                            : 14,
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
                          size:
                              Responsive.isMobileSmall(context) ||
                                  Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 14
                              : Responsive.isTabletPortrait(context)
                              ? 18
                              : 18,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 1),
                        Text(
                          '${item.verificationTime!.hour.toString().padLeft(2, '0')}:${item.verificationTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 9
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 9.5
                                : Responsive.isTabletPortrait(context)
                                ? 14
                                : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '-',
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 9
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 10
                            : Responsive.isTabletPortrait(context)
                            ? 15
                            : 15,
                        color: Colors.grey[600],
                      ),
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
