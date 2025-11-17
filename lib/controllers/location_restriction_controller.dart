import 'dart:math';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stelacom_check/components/utils/custom_error_dialog.dart';
import 'package:stelacom_check/components/utils/dialogs.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkin_capture_screen.dart';
import 'package:stelacom_check/screens/checkin-checkout/checkout_capture_screen.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:flutter/material.dart';

class LocationRestrictionsController extends GetxController {
  // Observables - replaces Provider state
  final userLocationRestrictions = <dynamic>[].obs;
  final userObj = Rxn<Map<String, dynamic>>();
  final shouldShowAlert = true.obs;
  final currentPosition = Rxn<Position>();
  final isLoading = true.obs;
  
  // Non-observable variables
  late SharedPreferences _storage;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  @override
  void onInit() {
    super.onInit();
    getSharedPrefs();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    String? userData = _storage.getString('user_data');
    if (userData != null) {
      userObj.value = jsonDecode(userData);
    }

    showProgressDialog(Get.context!);
    var response = await ApiService.getAllLocationRestritions(
        userObj.value!["Code"], userObj.value!["CustomerId"]);

    if (response != null &&
        response.statusCode == 200 &&
        response.body != "null") {
      
      // Set location restrictions using GetX observable
      userLocationRestrictions.value = jsonDecode(response.body);

      if (userLocationRestrictions.isEmpty) {
        closeDialog(Get.context!);
        String? action = _storage.getString('Action');
        _storage.setDouble('Distance', 0);
        
        if (action == 'checkin') {
          Get.off(() => CheckInCapture());
        } else if (action == 'checkout') {
          Get.off(() => CheckoutCapture());
        }
      } else {
        await checkForGeofence();
      }
    }
  }

  Future<void> checkForGeofence() async {
    bool firstServiceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    
    if (firstServiceEnabled) {
      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        closeDialog(Get.context!);
      } else {
        await getCordinates();
      }
    } else {
      closeDialog(Get.context!);
      
      Get.dialog(
        CustomErrorDialog(
          title: 'Location service disabled.',
          message: 'Please enable location service before try this operation',
          onOkPressed: switchOnLocation,
          iconData: Icons.warning,
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> getCordinates() async {
    try {
      Position position = await _geolocatorPlatform.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high));
      
      currentPosition.value = position;

      var lat = position.latitude;
      var long = position.longitude;

      // Create a new list to trigger reactivity
      List<dynamic> updatedRestrictions = [];
      
      for (var element in userLocationRestrictions) {
        // Single distance calculation using improved Haversine formula
        double distanceInMeters = calculateDistanceInMeters(lat, long,
            double.parse(element['InLat']), double.parse(element['InLong']));

        // Calculate distance from boundary (negative if inside)
        element['Distance'] = distanceInMeters - element['Radius'];

        // Generate user-friendly status text
        element['DistanceText'] = generateDistanceText(
            distanceInMeters, element['Radius'], element['AllowedByPass']);

        print("Location: ${element['Name']}, Distance: ${element['Distance']}m");
        
        updatedRestrictions.add(element);
      }
      
      // Update observable list to trigger UI rebuild
      userLocationRestrictions.value = updatedRestrictions;
      
      closeDialog(Get.context!);
      isLoading.value = false;
    } catch (e) {
      closeDialog(Get.context!);
      
      Get.dialog(
        CustomErrorDialog(
          title: 'Location checking',
          message: 'Something went wrong. Please contact iCheck administrator',
          onOkPressed: () {
            Get.back();
            Get.off(() => HomeScreen(index2: 0));
          },
          iconData: Icons.warning,
        ),
        barrierDismissible: false,
      );
      
      print(e);
    }
  }

  /// Calculates distance between two points using Haversine formula
  /// Returns distance in meters with high accuracy
  double calculateDistanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMeters = 6371000; // Earth's radius in meters

    // Convert degrees to radians
    final double lat1Rad = lat1 * pi / 180;
    final double lat2Rad = lat2 * pi / 180;
    final double deltaLatRad = (lat2 - lat1) * pi / 180;
    final double deltaLonRad = (lon2 - lon1) * pi / 180;

    // Haversine formula
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Generates user-friendly distance text based on location status
  String generateDistanceText(
      double actualDistance, double radius, int allowBypass) {
    double distanceKm = actualDistance / 1000;
    double remainingDistance = actualDistance - radius;

    if (remainingDistance <= 0) {
      // User is inside the radius
      return 'Inside now (${distanceKm.toStringAsFixed(3)} KM)';
    } else if (allowBypass == 1) {
      // User is outside but bypass is allowed
      double remainingKm = remainingDistance / 1000;
      return '${remainingKm.toStringAsFixed(3)} KM to go (Allow by pass option enabled)';
    } else {
      // User is outside and no bypass allowed
      double remainingKm = remainingDistance / 1000;
      return '${remainingKm.toStringAsFixed(3)} KM to go or try to enable allow by pass option';
    }
  }

  void switchOnLocation() async {
    Get.back();
    bool ison = await Geolocator.isLocationServiceEnabled();
    
    if (!ison) {
      bool isturnedon = await Geolocator.openLocationSettings();
      
      if (isturnedon) {
        Get.off(() => HomeScreen(index2: 0));
      } else {
        Get.off(() => CheckInCapture());
      }
    }
  }

  void handleLocationTap(int index) {
    final locationDistance = userLocationRestrictions[index]['Distance'];
    final locationID = userLocationRestrictions[index]['Id'];
    final allowByPass = userLocationRestrictions[index]['AllowedByPass'];

    if (allowByPass == null || allowByPass == 0) {
      if (locationDistance > 0) {
        return;
      }
    }

    String? action = _storage.getString('Action');
    
    if (allowByPass == null || allowByPass == 0) {
      _storage.setDouble('Distance', locationDistance);
    } else {
      _storage.setString("LocationId", locationID);
      _storage.setDouble("LocationDistance", locationDistance);
    }

    if (action == 'checkin') {
      Get.to(() => CheckInCapture());
    } else if (action == 'checkout') {
      Get.to(() => CheckoutCapture());
    }
  }

  // Check if all locations are outside radius without bypass
  bool shouldShowLocationAlert() {
    if (userLocationRestrictions.isEmpty) return false;
    
    return userLocationRestrictions
            .where((object) =>
                object['Distance'] != null &&
                object['Distance'] > 0 &&
                object['AllowedByPass'] == 0)
            .length ==
        userLocationRestrictions.length;
  }
}
