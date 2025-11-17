import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/controllers/appstate_controller.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/Enroll/enroll_capture_screen.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/custom_success_dialog.dart';
import '../../components/utils/dialogs.dart';
import 'package:jiffy/jiffy.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_widget/sliding_widget.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'package:http_parser/http_parser.dart';

class EnrollmentPreview extends StatefulWidget {
  final String imagePath;
  final String username;
  final String location;
  final String time;
  final String date;
  EnrollmentPreview({
    Key? key,
    required this.imagePath,
    required this.username,
    required this.location,
    required this.time,
    required this.date,
  }) : super(key: key);

  @override
  State<EnrollmentPreview> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<EnrollmentPreview>
    with WidgetsBindingObserver {
  SharedPreferences? _storage;
  double lat = 0.0;
  double long = 0.0;
  dynamic userObj = Map<String, String>();
  String locationId = "";
  double locationDistance = 0.0;
  bool inCameraPreview = true;
  late var timer;
  late AppStateController appState;
  Position? currentLocation;
  late bool servicePermission = false;
  late LocationPermission locationPermission;

  @override
  void initState() {
    super.initState();
    appState = Get.put(AppStateController());

    getSharedPrefs();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userObj = jsonDecode(_storage!.getString('user_data')!);

    if (mounted) {
      appState.updateUserInfo(
        userObj["FirstName"] + " " + userObj["LastName"],
        userObj["Id"],
        userObj["CustomerId"],
        Jiffy.now().yMMMMd,
      );
    }

    currentLocation = await getCurrentLocation();
    await _getAddressFromCoordinated();

    long = currentLocation!.longitude;
    lat = currentLocation!.latitude;

    locationId = _storage!.getString('LocationId') ?? "";
    locationDistance = _storage!.getDouble('LocationDistance') ?? 0.0;
  }

  // Get user current location

  Future<Position> getCurrentLocation() async {
    servicePermission = await Geolocator.isLocationServiceEnabled();
    if (!servicePermission) {
      print("Service disbaled");
    }

    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.deniedForever ||
        locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  // GET USER CURRENT COORDINATES

  _getAddressFromCoordinated() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
        currentLocation!.latitude, currentLocation!.longitude);

    Placemark place = placemarks[0];

    appState.setLocationAddress(
      '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}',
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EnrollmentCaptureScreen(),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: Responsive.isMobileSmall(context)
                              ? 16
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 20
                                  : Responsive.isTabletPortrait(context)
                                      ? 25
                                      : 30,
                          color: screenHeadingColor,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => EnrollmentCaptureScreen(),
                            ),
                          );
                        }),
                    Expanded(
                      child: Text(
                        'Face Enrollment',
                        style: TextStyle(
                          color: screenHeadingColor,
                          fontSize: Responsive.isMobileSmall(context)
                              ? 20
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 24
                                  : Responsive.isTabletPortrait(context)
                                      ? 28
                                      : 30,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: iconColors,
                                  size: Responsive.isMobileSmall(context)
                                      ? 20
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 22
                                          : Responsive.isTabletPortrait(context)
                                              ? 25
                                              : 25,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  widget.date,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 13
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.watch,
                                  color: iconColors,
                                  size: Responsive.isMobileSmall(context)
                                      ? 20
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 22
                                          : Responsive.isTabletPortrait(context)
                                              ? 25
                                              : 25,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  widget.time,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 13
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        // Name Display
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: iconColors,
                              size: Responsive.isMobileSmall(context)
                                  ? 20
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 24
                                      : Responsive.isTabletPortrait(context)
                                          ? 25
                                          : 25,
                            ),
                            SizedBox(width: 5),
                            Text(
                              widget.username,
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 19
                                        : Responsive.isTabletPortrait(context)
                                            ? 25
                                            : 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 25),

                        // Camera Preview Container
                        Container(
                          height: Responsive.isMobileSmall(context)
                              ? 300
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 400
                                  : Responsive.isTabletPortrait(context)
                                      ? 500
                                      : 500,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              color: Colors.grey[200],
                              child: Transform.scale(
                                scale: scale,
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: FileImage(
                                          File(widget.imagePath),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),

                        // Location Info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: iconColors,
                                size: Responsive.isMobileSmall(context)
                                    ? 25
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 30
                                        : Responsive.isTabletPortrait(context)
                                            ? 35
                                            : 35,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 12
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 15
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 25,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 25),
                        // Slide to Check-in Button

                        SlidingWidget(
                          shadow: BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 5,
                          ),
                          width: size.width,
                          height: Responsive.isMobileSmall(context)
                              ? 60
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 62
                                  : Responsive.isTabletPortrait(context)
                                      ? 70
                                      : 70,
                          backgroundColor: actionBtnColor,
                          foregroundColor: Colors.white,
                          iconColor: slidingBarIconColor,
                          stickToEnd: true,
                          label: '      Slide to Enroll',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 20
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 20
                                    : 25,
                          ),
                          action: () {
                            try {
                              saveAction(widget.imagePath);
                            } catch (e) {
                              // If an error occurs, log the error to the console.
                              print(e);
                            }
                          },
                          child: Icon(
                            Icons.arrow_forward_ios_sharp,
                            color: iconColors,
                            size: Responsive.isMobileSmall(context)
                                ? 25
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 30
                                    : Responsive.isTabletPortrait(context)
                                        ? 40
                                        : 40,
                            shadows: [
                              Shadow(color: Colors.orange, blurRadius: 2.0)
                            ],
                          ),
                          backgroundColorEnd:
                              Color.fromARGB(204, 216, 171, 119),
                        ),
                      ],
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

  void saveAction(imagePath) async {
    showProgressDialog(context);
    String? uniqueID = await UniqueIdentifier.serial;
    http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'http://icheck-face-recognition-stelacom.us-east-2.elasticbeanstalk.com/api/train'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        File(imagePath).path,
        contentType: MediaType('application', 'png'),
      ),
    );
    var now = new DateTime.now();
    request.fields['year'] = now.year.toString();
    request.fields['month'] = now.month.toString();
    request.fields['day'] = now.day.toString();
    request.fields['hour'] = now.hour.toString();
    request.fields['minute'] = now.minute.toString();
    request.fields['second'] = now.second.toString();
    request.fields['pk'] = userObj["CustomerId"];
    request.fields['sk'] = userObj["Id"];
    request.fields['name'] = userObj["Id"];
    request.fields['deviceId'] = uniqueID!;
    request.fields['lat'] = lat.toString();
    request.fields['long'] = long.toString();
    request.fields['address'] = appState.locationAddress;

    http.StreamedResponse r = await request.send();
    closeDialog(context);
    print("r.statusCode == " + r.statusCode.toString());
    if (r.statusCode == 200) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomSuccessDialog(
          message: 'Successfully Enrolled.',
          onOkPressed: okHandler,
        ),
      );
    } else if (r.statusCode == 1001) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomErrorDialog(
          title: 'Error Occured.',
          message: 'No images can be identified in the image.',
          // onOkPressed: () {
          //   Navigator.of(context).pop();
          // },
          onOkPressed: moveToEnrollment,
          iconData: Icons.warning,
        ),
      );
    } else {
      r.stream.transform(utf8.decoder).join().then((String content) async {
        print("content $content");
        if (content.indexOf('people matched') > 0) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomErrorDialog(
              title: 'No Matching Faces Detected.',
              message:
                  'Sorry, we cannot find any faces that match your face image. Please try another image.',
              onOkPressed: moveToEnrollment,
              iconData: MdiIcons.faceRecognition,
            ),
          );
        } else if (content.indexOf('There are no faces') > 0 ||
            content.indexOf('Error occurred') > 0 ||
            content.indexOf('add_failed_record()') > 0 ||
            content.indexOf('list index out of range') > 0) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomErrorDialog(
              title: 'No Faces Detected.',
              message:
                  'Sorry, we cannot find any faces in the image. Please try another image.',
              onOkPressed: moveToEnrollment,
              iconData: MdiIcons.faceRecognition,
            ),
          );
        } else {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomErrorDialog(
              title: 'Error occured.!',
              message:
                  'Something went wrong with the connection to the server. Please make sure your internet connection is enabled or if the issue still persists, please contact iCheck.',
              onOkPressed: moveToEnrollment,
              iconData: MdiIcons.serverNetwork,
            ),
          );
        }
      });
    }
  }

  void okHandler() async {
    String employeeCode = _storage!.getString('employee_code') ?? "";
    var response = await ApiService.verifyUserWithoutOTP(employeeCode);

    if (response.statusCode == 200) {
      _storage!.setString('user_data', response.body);
      closeDialog(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return HomeScreen(index2: 0);
        }),
      );
    }
  }

  void moveToEnrollment() {
    closeDialog(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => EnrollmentCaptureScreen(),
      ),
      (route) => true,
    );
  }
}
