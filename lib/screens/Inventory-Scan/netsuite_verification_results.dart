import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stelacom_check/constants.dart';
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
  final Function(List<NetsuiteDeviceItem>)? onDeviceListUpdated;

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
  List<NetsuiteDeviceItem> deviceList = [];
  String searchQuery = "";
  String filterStatus = "All";
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
      _storage.clear();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
        (route) => false,
      );
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
        filtered = filtered.where((item) => item.serialized).toList();
        break;
      case "Non-Serialized":
        filtered = filtered.where((item) => !item.serialized).toList();
        break;
      default:
        break;
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final query = searchQuery.toLowerCase();
        return item.model.toLowerCase().contains(query) ||
            (item.number?.toLowerCase().contains(query) ?? false) ||
            item.itemCode.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  int get verifiedCount => deviceList.where((item) => item.isVerified).length;
  int get totalCount => deviceList.length;
  int get serializedCount => deviceList.where((item) => item.serialized).length;
  int get nonSerializedCount =>
      deviceList.where((item) => !item.serialized).length;
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
    if (!item.serialized) {
      _showNonSerializedItemDialog(item);
    } else {
      _showSerializedItemActions(item);
    }
  }

  void _showSerializedItemActions(NetsuiteDeviceItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unverified Item Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Item Code: ${item.itemCode}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Number: ${item.number ?? "N/A"}',
                style: TextStyle(fontSize: 14),
              ),
              Text('Model: ${item.model}', style: TextStyle(fontSize: 14)),
              SizedBox(height: 16),
              Text(
                'Choose an action:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    content: Text('Please scan the barcode for: ${item.model}'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Rescan',
                style: TextStyle(
                  color: actionBtnColor,
                  fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNonSerializedItemDialog(NetsuiteDeviceItem item) {
    TextEditingController varianceReasonController = TextEditingController();
    bool imagesCaptured = false;
    List<File> localAttachedImages = [];
    String? selectedVarianceReason;

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
                      icon: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool hasVarianceReason =
                selectedVarianceReason != null &&
                selectedVarianceReason!.isNotEmpty;

            return AlertDialog(
              title: Text('Non-Serialized Item Verification'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Code: ${item.itemCode}',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Number: ${item.number ?? "N/A"}',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Model: ${item.model}',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Variance Reason (Optional)',
                      style: TextStyle(
                        fontSize: 16,
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
                        hintText: 'e.g., Item not available, Wrong count, etc.',
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
                    Row(
                      children: [
                        Text(
                          'Attach Photo',
                          style: TextStyle(
                            fontSize: 16,
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
                          size: 24,
                        ),
                        label: Text(
                          'Take Photo',
                          style: TextStyle(color: Colors.green, fontSize: 14),
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
                    if (imagesCaptured) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Image Captured',
                            style: TextStyle(
                              fontSize: 14,
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
                                            size: 12,
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
                          fontSize: 12,
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
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: imagesCaptured
                      ? () {
                          setState(() {
                            item.isVerified = true;
                            item.verificationTime = DateTime.now();
                            item.varianceReason = hasVarianceReason
                                ? selectedVarianceReason
                                : "Image Attached";
                          });

                          _saveDeviceListToStorage();
                          _updateDataSource();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Item verified with image for ${item.model}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: imagesCaptured
                        ? actionBtnColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Verify'),
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
              title: Text('Variance Reason'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Code: ${item.itemCode}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Number: ${item.number ?? "N/A"}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text('Model: ${item.model}', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 16),
                  Text(
                    'Select reason:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                            style: TextStyle(fontSize: 14),
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
                    style: TextStyle(color: Colors.red, fontSize: 14),
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
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
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
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: appbarBgColor,
          toolbarHeight: 40,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 90.0,
                height: 40.0,
                child: Image.asset(
                  'assets/images/iCheck_logo_2024.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: size.width * 0.25),
              SizedBox(
                width: 90.0,
                height: 40.0,
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
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
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
                          fontSize: 22,
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
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$verifiedCount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Verified', style: TextStyle(fontSize: 10)),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Unverified',
                                style: TextStyle(fontSize: 10),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Total', style: TextStyle(fontSize: 10)),
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
                                          DataColumn(
                                            label: Text(
                                              'Type',
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
                        fontSize: 16,
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Submit Verification Report',
            style: TextStyle(fontSize: 20),
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
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Verified: $verifiedCount items',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  '• Unverified: ${totalCount - verifiedCount} items',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  '• Serialized: $serializedCount items',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  '• Non-serialized: $nonSerializedCount items',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  '• Total: $totalCount items',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _commentsController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
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
                  'Are you sure you want to submit this verification report?',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(index2: widget.index),
                  ),
                  (route) => false,
                );
              },
              child: Text('Submit', style: TextStyle(fontSize: 15)),
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
            child: item.number != null
                ? Text(
                    item.number!.length > 15
                        ? item.number!.substring(0, 15) + '...'
                        : item.number!,
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  )
                : Text('N/A', style: TextStyle(fontSize: 10)),
          ),
        ),

        // Model Cell
        DataCell(
          Container(
            width: 90,
            child: Text(
              item.model,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Type Cell
        DataCell(
          Container(
            width: 50,
            child: Text(
              item.deviceType == 'IMEI Device'
                  ? 'IMEI'
                  : item.deviceType == 'Serial Number Device'
                  ? 'Serial'
                  : 'Bulk',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: item.deviceType == 'IMEI Device'
                    ? Colors.blue
                    : item.deviceType == 'Serial Number Device'
                    ? Colors.purple
                    : Colors.orange,
              ),
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
                              item.serialized
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
