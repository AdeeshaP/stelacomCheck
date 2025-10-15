import 'package:flutter/material.dart';

class LocationRestrictionState extends ChangeNotifier {
  // Define your state variables here
  // For example:
  List<dynamic> userLocationRestrictions = [];

  // Add methods to update your state
  void setUserLocationRestrictions(List<dynamic> restrictions) {
    userLocationRestrictions = restrictions;
    notifyListeners();
  }
}
