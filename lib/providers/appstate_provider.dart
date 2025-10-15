import 'dart:convert';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool deficeInfoRetrieved = false;
  bool regDeficeInfoPassed = false;
  String time = '';
  String _date = '';
  String _officeDate = '';
  String _officeTime = '';
  String _name = '';
  String _userid = '';
  String _customerid = '';
  String _locationAddress = '';
  bool isSupervisor = false;
  bool isDeactivated = false;
  String _officeAddress = '';
  List<dynamic> individualRequestLeaves = [];
  List<dynamic> groupRequestLeaves = [];
  List<dynamic> requestOTs = [];
  List<dynamic> propertyVariables = [];
  bool requestAvailable = false;

  String get officeDate => _officeDate;
  String get officeTime => _officeTime;
  String get name => _name;
  String get date => _date;
  String get userid => _userid;
  String get customerid => _customerid;
  String get locationAddress => _locationAddress;
  String get officeAddress => _officeAddress;

  // Methods to update state

  void updateUserInfo(
      String newName, String newUserId, String newCustomerId, String date) {
    _name = newName;
    _userid = newUserId;
    _customerid = newCustomerId;
    _date = date;
    notifyListeners();
  }

  void updateOfficeDate(String newDate) {
    _officeDate = newDate;
    notifyListeners();
  }

  void updateOfficeTime(String newTime) {
    _officeTime = newTime;
    notifyListeners();
  }

  void updateTime(String newTime) {
    time = newTime;
    notifyListeners();
  }

  void setLocationAddress(String address) {
    _locationAddress = address;
    notifyListeners();
  }

  void updateSupervisorRequests(
      List<dynamic> individualRequests, List<dynamic> groupRequests) {
    individualRequestLeaves = individualRequests;
    groupRequestLeaves = groupRequests;

    if (individualRequestLeaves.isNotEmpty || groupRequestLeaves.isNotEmpty) {
      requestAvailable = true;
    } else {
      requestAvailable = false;
    }

    notifyListeners();
  }

  void checkIsSupervsor(String userData) {
    Map<String, dynamic> userObj = jsonDecode(userData);
    if (userObj["IsSupervisor"] == 1) {
      isSupervisor = true;
    } else {
      isSupervisor = false;
    }
    notifyListeners();
  }

  void updateUserWorkingHrs(List<dynamic> propertieVariables) {
    propertyVariables = propertieVariables;

    notifyListeners();
  }

  void updateOfficeAddress(String newAddress) {
    _officeAddress = newAddress;
    notifyListeners();
  }

  void checkIsDeleted(String userData) {
    Map<String, dynamic> userObj = jsonDecode(userData);
    if (userObj["Deleted"] == 1) {
      isDeactivated = true;
    } else {
      isDeactivated = false;
    }
    notifyListeners();
  }
}
