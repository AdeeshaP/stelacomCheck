import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import '../../components/utils/custom_error_dialog.dart';
import '../../components/utils/dialogs.dart';

// Result class to return both validation result and description
class LocationValidationResult {
  final bool isValid;
  final String? description;

  LocationValidationResult({required this.isValid, this.description});
}

class LocationValidationService {
  static Future<LocationValidationResult> validateLocationForInventoryScan(
      BuildContext context) async {
    try {
      // Show loading dialog
      showProgressDialog(context);

      // Get user data from SharedPreferences
      SharedPreferences storage = await SharedPreferences.getInstance();
      String? userData = storage.getString('user_data');
      if (userData == null) {
        closeDialog(context);
        _showErrorDialog(context, 'User data not found');
        return LocationValidationResult(isValid: false);
      }

      Map<String, dynamic> userObj = jsonDecode(userData);

      // Get location restrictions from API
      var response = await ApiService.getAllLocationRestritions(
          userObj["Code"], userObj["CustomerId"]);

      if (response == null ||
          response.statusCode != 200 ||
          response.body == "null") {
        closeDialog(context);
        _showErrorDialog(context, 'Failed to fetch location restrictions');
        return LocationValidationResult(isValid: false);
      }

      List<dynamic> locationRestrictions = jsonDecode(response.body);

      // If no location restrictions, allow access
      if (locationRestrictions.isEmpty) {
        closeDialog(context);
        return LocationValidationResult(isValid: true);
      }

      // Check location services and permissions
      final GeolocatorPlatform geolocatorPlatform = GeolocatorPlatform.instance;

      bool isLocationServiceEnabled =
          await geolocatorPlatform.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        closeDialog(context);
        _showLocationServiceDisabledDialog(context);
        return LocationValidationResult(isValid: false);
      }

      LocationPermission permission =
          await geolocatorPlatform.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        closeDialog(context);
        _showLocationPermissionDialog(context);
        return LocationValidationResult(isValid: false);
      }

      // Get current position with high accuracy
      Position currentPosition = await geolocatorPlatform.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      String? validLocationDescription;

      // Process each location using the EXACT same logic as your original code
      for (var element in locationRestrictions) {
        // Use the same distance calculation method as your original code
        double distance2 = _distanceBetweenTwoLocations(
            currentPosition.latitude,
            currentPosition.longitude,
            double.parse(element['InLat']),
            double.parse(element['InLong']));

        // Apply the same distance calculation as your original code
        element['Distance'] = distance2 * 1000 - element['Radius'];

        print('Location: ${element['Name']}, Distance: ${element['Distance']}');

        // Check if user is within this location (Distance <= 0 means within radius)
        if (element['Distance'] <= 0) {
          validLocationDescription = element['Description'];
          print(
              'User is within location: ${element['Name']}, Description: ${element['Description']}');
        }
      }

      // Apply the EXACT same blocking logic as your original code
      var blockedLocations = locationRestrictions
          .where((object) =>
              (object['Distance'] > 0 && object['AllowedByPass'] == 0) ||
              (object['AllowedByPass'] == 1) && object['Distance'] > 0)
          .toList();

      print('Total locations: ${locationRestrictions.length}');
      print('Blocked locations: ${blockedLocations.length}');

      bool shouldBlock = blockedLocations.length == locationRestrictions.length;

      closeDialog(context);

      if (shouldBlock) {
        // Find the closest location for error message
        var closestLocation = locationRestrictions
            .reduce((a, b) => a['Distance'] < b['Distance'] ? a : b);

        double distanceKm = closestLocation['Distance'] / 1000;
        String locationName = closestLocation['Name'] ?? 'assigned location';

        _showLocationRestrictionDialog(context,
            'You are ${distanceKm.toStringAsFixed(3)} KM away from the correct location');
        return LocationValidationResult(isValid: false);
      }

      return LocationValidationResult(
          isValid: true, description: validLocationDescription);
    } catch (e) {
      closeDialog(context);
      _showErrorDialog(
          context, 'Location validation failed. Please try again.');
      print('Location validation error: $e');
      return LocationValidationResult(isValid: false);
    }
  }

  /// Use the EXACT same distance calculation as your original code
  static double _toRadians(double degrees) => degrees * pi / 180;

  static num _haversin(double radians) => pow(sin(radians / 2), 2);

  static double _distanceBetweenTwoLocations(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6372.8; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final lat1Radians = _toRadians(lat1);
    final lat2Radians = _toRadians(lat2);

    final a =
        _haversin(dLat) + cos(lat1Radians) * cos(lat2Radians) * _haversin(dLon);
    final c = 2 * asin(sqrt(a));

    return r * c;
  }

  static void _showLocationServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomErrorDialog(
        title: 'Location service disabled.',
        message: 'Please enable location service before try this operation',
        onOkPressed: () async {
          Navigator.of(context).pop();
          await Geolocator.openLocationSettings();
        },
        iconData: Icons.warning,
      ),
    );
  }

  static void _showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomErrorDialog(
        title: 'Location Permission Required',
        message:
            'Location permission is required to use Inventory Scan feature',
        onOkPressed: () {
          Navigator.of(context).pop();
        },
        iconData: Icons.warning,
      ),
    );
  }

  static void _showLocationRestrictionDialog(
      BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomErrorDialog(
        title: 'Error!',
        message:
            'Inventory Scan is not available from your current location. You are not at the exact location or inside the assigned radius.\n Please move to the assigned location and try.',
        onOkPressed: () {
          Navigator.of(context).pop();
        },
        iconData: Icons.not_listed_location,
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomErrorDialog(
        title: 'Location checking',
        message: 'Something went wrong. Please contact iCheck administrator',
        onOkPressed: () {
          Navigator.of(context).pop();
        },
        iconData: Icons.warning,
      ),
    );
  }
}

// Usage example in your Dashboard screen:
/*
// In your Dashboard screen where the Inventory Scan button is:
ElevatedButton(
  onPressed: () async {
    bool isLocationValid = await LocationValidationService
        .validateLocationForInventoryScan(context);
    
    if (isLocationValid) {
      // Navigate to Inventory Scan screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InventoryScanScreen()),
      );
    }
    // Error dialog is automatically shown if location is invalid
  },
  child: Text('Inventory Scan'),
)
*/
