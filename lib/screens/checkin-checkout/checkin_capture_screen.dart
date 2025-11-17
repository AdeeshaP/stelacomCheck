import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:stelacom_check/components/utils/custom_error_dialog.dart';
import 'package:stelacom_check/components/utils/dialogs.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkin_preview_screen.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/main.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:stelacom_check/controllers/appstate_controller.dart';

class CheckInCapture extends StatefulWidget {
  const CheckInCapture({Key? key}) : super(key: key);

  @override
  State<CheckInCapture> createState() => _CheckInCaptureState();
}

class _CheckInCaptureState extends State<CheckInCapture>
    with WidgetsBindingObserver {
  XFile? imageFile;
  SharedPreferences? _storage;
  double lat = 0.0;
  double long = 0.0;
  dynamic userObj = Map<String, String>();
  String locationId = "";
  double locationDistance = 0.0;
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  CameraDescription? firstCamera;
  int _cameraIndex = 0;
  bool _regDeficeInfoPassed = false;
  bool _deficeInfoRetrieved = false;
  List<dynamic> registeredDevices = [];
  String deviceModel = "";
  String deviceVersion = "";
  late var timer;
  Position? currentLocation;
  CustomPaint? customPaint;
  bool isBusy = false;
  bool _isCameraReady = false;
  late AppStateController appState;

  @override
  void initState() {
    super.initState();
    appState = Get.put(AppStateController());

    getSharedPrefs();
    WidgetsBinding.instance.addObserver(this);
    if (mounted)
      timer = Timer.periodic(Duration(milliseconds: 50), (_) {
        appState.updateTime(Jiffy.now().format(pattern: "hh:mm:ss a"));
      });

    initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController!.dispose();

    timer.cancel();
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    await handleLocationPermssion();

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

    bool? deviceInfoRetrieved = _storage!.getBool('DeficeInfoRetrieved');
    setState(() {
      _deficeInfoRetrieved = deviceInfoRetrieved ?? false;
    });

    if (deviceInfoRetrieved == false || deviceInfoRetrieved == null) {
      getDeviceInfo();
    }
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    } else if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    } else {
      currentLocation = await Geolocator.getCurrentPosition();
      await _getAddressFromCoordinated();

      long = currentLocation!.longitude;
      lat = currentLocation!.latitude;

      locationId = _storage!.getString('LocationId') ?? "";
      locationDistance = _storage!.getDouble('LocationDistance') ?? 0.0;
    }

    bool? regDeviceInfoPassed = _storage!.getBool('RegDeficeInfoPassed');
    setState(() {
      _regDeficeInfoPassed = regDeviceInfoPassed ?? false;
    });

    if (regDeviceInfoPassed == false || regDeviceInfoPassed == null) {
      await getRegisteredDevicesAndPassData();
    }
  }

  Future<void> initCamera() async {
    try {
      if (cameras.length > 1) {
        firstCamera = cameras[1];
        _cameraIndex = 1;
      } else {
        firstCamera = cameras.first;
        _cameraIndex = 0;
      }
      _cameraController = CameraController(
        firstCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initializeControllerFuture = _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isCameraReady = false;
      });
    }
  }

  // GET INSTALLED DEVICE INFORMATION

  Future<void> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();

      var androidInfo = await deviceInfoPlugin.androidInfo;
      var androidVersion = androidInfo.version.release;
      var androidModel = androidInfo.model;

      setState(() {
        deviceModel = androidModel;
        deviceVersion = androidVersion;
      });
    } else if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      var iOSversion = iosInfo.systemVersion;
      var iOSmodel = iosInfo.model;
      setState(() {
        deviceModel = iOSmodel;
        deviceVersion = iOSversion;
      });
    }

    setState(() {
      _deficeInfoRetrieved = true;
      _storage!.setBool('DeficeInfoRetrieved', _deficeInfoRetrieved);
    });
  }

  // GET ALREADY REGISTRED DEVICES INFO

  Future<void> getRegisteredDevicesAndPassData() async {
    var response = await ApiService.getRegisteredDeviceInfo(appState.userid);
    var isAleardyRegistred = false;

    if (response.statusCode == 200) {
      registeredDevices = jsonDecode(response.body);

      for (int x = 0; x < registeredDevices.length; x++) {
        if (registeredDevices[x]["DeviceModel"] == deviceModel &&
            registeredDevices[x]["AndroidVersion"] == deviceVersion) {
          isAleardyRegistred = true;
        }
      }
      if (isAleardyRegistred == false) {
        int status = 0;
        String userId = userObj!["Code"];
        String createdDate = "";
        String LastModifiedDate = "";
        String createdBy = userObj!["Code"];
        String LastModifyBy = "";

        var response = await ApiService.postRegisteredDeviceInfo(
          deviceModel,
          deviceVersion,
          status,
          userId,
          createdDate,
          LastModifiedDate,
          createdBy,
          LastModifyBy,
        );

        if (response.statusCode == 200) {
          print("Suceessfully data passed.");
        } else if (response.statusCode == 1001) {
          print("Data not sent");
        } else {
          print("failed");
        }
      }
    }
    setState(() {
      _regDeficeInfoPassed = true;
      _storage!.setBool('RegDeficeInfoPassed', _regDeficeInfoPassed);
    });
  }

  // Get user current location

  Future<void> handleLocationPermssion() async {
    LocationPermission locationPermission;

    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomErrorDialog(
          title: 'Feature is blocked!',
          message: 'Location permissions are denied.',
          onOkPressed: () {
            closeDialog(context);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => HomeScreen(index2: 0)));
            Geolocator.requestPermission();
          },
          iconData: Icons.block,
        ),
      );
    }
    if (locationPermission == LocationPermission.deniedForever) {
      locationPermission = await Geolocator.requestPermission();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomErrorDialog(
          title: 'Feature is blocked!',
          message: 'Location permissions are permanently denied.',
          onOkPressed: () {
            closeDialog(context);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => HomeScreen(index2: 0)));
            Geolocator.requestPermission();
          },
          iconData: Icons.block,
        ),
      );
    }
  }

  // GET USER CURRENT COORDINATES

  _getAddressFromCoordinated() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      currentLocation!.latitude,
      currentLocation!.longitude,
    );

    Placemark place = placemarks[0];

    appState.setLocationAddress(
      '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}',
    );
  }

  saveImage() async {
    try {
      await _initializeControllerFuture;
      imageFile = await _cameraController!.takePicture();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CheckinPreviewScreen(
            imagePath: imageFile!.path,
            username: userObj["FirstName"] + " " + userObj["LastName"],
            location: appState.locationAddress,
            time: appState.time,
            date: appState.date,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Future _onCameraSwitched(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(child: _buildFaceRecognitionArea(screenHeight)),
                      _buildBottomButtons(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: screenHeadingColor),
                onPressed: () {
                  // Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(index2: 0),
                    ),
                    (route) => false,
                  );
                },
              ),
              Expanded(
                child: Text(
                  'Check-in Enrollment',
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
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: shadeBoxBgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        'Date',
                        DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        'Time',
                        DateFormat('HH:mm:ss').format(DateTime.now()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoItem(
                  Icons.location_on,
                  'Location',
                  appState.locationAddress,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColors,
          size: Responsive.isMobileSmall(context)
              ? 18
              : Responsive.isMobileMedium(context) ||
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
                label,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 11
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 13
                      : Responsive.isTabletPortrait(context)
                      ? 16
                      : 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(double screenHeight) {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        width: screenHeight * 0.35,
        height: screenHeight * 0.35,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.face, size: screenHeight * 0.15, color: iconColors),
      );
    }

    final size = screenHeight * 0.35;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Container(
            width: size,
            height: size,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceRecognitionArea(double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Keep your face focused',
            style: TextStyle(
              color: iconColors,
              fontSize: Responsive.isMobileSmall(context)
                  ? 18
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 20
                  : Responsive.isTabletPortrait(context)
                  ? 22
                  : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: screenHeight * 0.32,
                height: screenHeight * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColors, width: 2),
                ),
                child: _buildCameraPreview(screenHeight),
              ),
            ],
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: shadeBoxBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Position your face in the circle and ensure adequate light.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HomeScreen(index2: 0)),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.grey[800]!,
                    size: Responsive.isMobileSmall(context)
                        ? 25
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 30
                        : 35,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Back",
                style: TextStyle(
                  color: Colors.grey[800]!,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (appState.locationAddress != "") {
                    saveImage();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: appState.locationAddress == ""
                      ? BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[600]!, Colors.orange[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[200]!.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                  child: Icon(
                    Icons.camera_alt,
                    color: appState.locationAddress == ""
                        ? Colors.grey[800]
                        : Colors.white,
                    size: Responsive.isMobileSmall(context)
                        ? 30
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 40
                        : 45,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Capture',
                style: TextStyle(
                  color: appState.locationAddress == ""
                      ? Colors.grey[800]!
                      : cameraCaptureBtnTextColor,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_cameraIndex == 0 && cameras.length > 1) {
                    firstCamera = cameras[1];
                    _cameraIndex = 1;
                  } else {
                    firstCamera = cameras.first;
                    _cameraIndex = 0;
                  }

                  _onCameraSwitched(firstCamera!);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.grey[800]!,
                    size: Responsive.isMobileSmall(context)
                        ? 25
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 30
                        : 35,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Switch",
                style: TextStyle(
                  color: Colors.grey[800]!,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                      ? 18
                      : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
