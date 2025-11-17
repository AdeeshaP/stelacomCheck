// import 'dart:convert';
// import 'package:get/get.dart';

// class AppStateController extends GetxController {
//   // Observable variables
//   var deficeInfoRetrieved = false.obs;
//   var regDeficeInfoPassed = false.obs;
//   var _time = ''.obs;
//   var _date = ''.obs;
//   var _officeDate = ''.obs;
//   var _officeTime = ''.obs;
//   var _name = ''.obs;
//   var _userid = ''.obs;
//   var _customerid = ''.obs;
//   var _locationAddress = ''.obs;
//   var isSupervisor = false.obs;
//   var isDeactivated = false.obs;
//   var _officeAddress = ''.obs;
//   var individualRequestLeaves = <dynamic>[].obs;
//   var groupRequestLeaves = <dynamic>[].obs;
//   var requestOTs = <dynamic>[].obs;
//   var propertyVariables = <dynamic>[].obs;
//   var requestAvailable = false.obs;

//   // Getters
//   String get officeDate => _officeDate.value;
//   String get officeTime => _officeTime.value;
//   String get name => _name.value;
//   String get date => _date.value;
//   String get time => _time.value;
//   String get userid => _userid.value;
//   String get customerid => _customerid.value;
//   String get locationAddress => _locationAddress.value;
//   String get officeAddress => _officeAddress.value;
  
//   // Boolean getters that return actual values
//   bool get isDeactivatedValue => isDeactivated.value;
//   bool get isSupervisorValue => isSupervisor.value;
//   bool get requestAvailableValue => requestAvailable.value;

//   // Methods to update state
//   void updateUserInfo(
//       String newName, String newUserId, String newCustomerId, String date) {
//     _name.value = newName;
//     _userid.value = newUserId;
//     _customerid.value = newCustomerId;
//     _date.value = date;
//   }

//   void updateOfficeDate(String newDate) {
//     _officeDate.value = newDate;
//   }

//   void updateOfficeTime(String newTime) {
//     _officeTime.value = newTime;
//   }

//   void updateTime(String newTime) {
//     _time.value = newTime;
//   }

//   void setLocationAddress(String address) {
//     _locationAddress.value = address;
//   }

//   void updateSupervisorRequests(
//       List<dynamic> individualRequests, List<dynamic> groupRequests) {
//     individualRequestLeaves.value = individualRequests;
//     groupRequestLeaves.value = groupRequests;

//     if (individualRequestLeaves.isNotEmpty || groupRequestLeaves.isNotEmpty) {
//       requestAvailable.value = true;
//     } else {
//       requestAvailable.value = false;
//     }
//   }

//   void checkIsSupervsor(String userData) {
//     Map<String, dynamic> userObj = jsonDecode(userData);
//     if (userObj["IsSupervisor"] == 1) {
//       isSupervisor.value = true;
//     } else {
//       isSupervisor.value = false;
//     }
//   }

//   void updateUserWorkingHrs(List<dynamic> propertieVariables) {
//     propertyVariables.value = propertieVariables;
//   }

//   void updateOfficeAddress(String newAddress) {
//     _officeAddress.value = newAddress;
//   }

//   void checkIsDeleted(String userData) {
//     Map<String, dynamic> userObj = jsonDecode(userData);
//     if (userObj["Deleted"] == 1) {
//       isDeactivated.value = true;
//     } else {
//       isDeactivated.value = false;
//     }
//   }
// }

import 'dart:convert';
import 'package:get/get.dart';

class AppStateController extends GetxController {
  // Observable variables
  var deficeInfoRetrieved = false.obs;
  var regDeficeInfoPassed = false.obs;
  var _time = ''.obs;
  var _date = ''.obs;
  var _officeDate = ''.obs;
  var _officeTime = ''.obs;
  var _name = ''.obs;
  var _userid = ''.obs;
  var _customerid = ''.obs;
  var _locationAddress = ''.obs;
  var isSupervisor = false.obs;
  var isDeactivated = false.obs;
  var _officeAddress = ''.obs;
  var individualRequestLeaves = <dynamic>[].obs;
  var groupRequestLeaves = <dynamic>[].obs;
  var requestOTs = <dynamic>[].obs;
  var propertyVariables = <dynamic>[].obs;
  var requestAvailable = false.obs;
  
  // NEW: Add observables for dashboard state
  var userObj = Rxn<Map<String, dynamic>>();
  var lastCheckIn = Rxn<Map<String, dynamic>>();
  var workedTime = "Not checked in yet".obs;
  var employeeCode = ''.obs;
  var formattedDuration = ''.obs;
  var formattedDate = ''.obs;
  var formattedInTime = ''.obs;
  var formattedOutTime = ''.obs;

  // Getters
  String get officeDate => _officeDate.value;
  String get officeTime => _officeTime.value;
  String get name => _name.value;
  String get date => _date.value;
  String get time => _time.value;
  String get userid => _userid.value;
  String get customerid => _customerid.value;
  String get locationAddress => _locationAddress.value;
  String get officeAddress => _officeAddress.value;
  
  // Boolean getters that return actual values
  bool get isDeactivatedValue => isDeactivated.value;
  bool get isSupervisorValue => isSupervisor.value;
  bool get requestAvailableValue => requestAvailable.value;
  
  // NEW: Getters for dashboard
  bool get isCheckedIn => lastCheckIn.value != null && lastCheckIn.value!["OutTime"] == null;
  String get workedTimeValue => workedTime.value;

  // Methods to update state
  void updateUserInfo(
      String newName, String newUserId, String newCustomerId, String date) {
    _name.value = newName;
    _userid.value = newUserId;
    _customerid.value = newCustomerId;
    _date.value = date;
  }

  void updateOfficeDate(String newDate) {
    _officeDate.value = newDate;
  }

  void updateOfficeTime(String newTime) {
    _officeTime.value = newTime;
  }

  void updateTime(String newTime) {
    _time.value = newTime;
  }

  void setLocationAddress(String address) {
    _locationAddress.value = address;
  }

  void updateSupervisorRequests(
      List<dynamic> individualRequests, List<dynamic> groupRequests) {
    individualRequestLeaves.value = individualRequests;
    groupRequestLeaves.value = groupRequests;

    if (individualRequestLeaves.isNotEmpty || groupRequestLeaves.isNotEmpty) {
      requestAvailable.value = true;
    } else {
      requestAvailable.value = false;
    }
  }

  void checkIsSupervsor(String userData) {
    Map<String, dynamic> userObj = jsonDecode(userData);
    if (userObj["IsSupervisor"] == 1) {
      isSupervisor.value = true;
    } else {
      isSupervisor.value = false;
    }
  }

  void updateUserWorkingHrs(List<dynamic> propertieVariables) {
    propertyVariables.value = propertieVariables;
  }

  void updateOfficeAddress(String newAddress) {
    _officeAddress.value = newAddress;
  }

  void checkIsDeleted(String userData) {
    Map<String, dynamic> userObj = jsonDecode(userData);
    if (userObj["Deleted"] == 1) {
      isDeactivated.value = true;
    } else {
      isDeactivated.value = false;
    }
  }
  
  // NEW: Methods for dashboard state management
  void setUserObj(Map<String, dynamic>? user) {
    userObj.value = user;
  }
  
  void setLastCheckIn(Map<String, dynamic>? checkIn) {
    lastCheckIn.value = checkIn;
  }
  
  void updateWorkedTime(String time) {
    workedTime.value = time;
  }
  
  void setEmployeeCode(String code) {
    employeeCode.value = code;
  }
  
  void updateFormattedDuration(String duration) {
    formattedDuration.value = duration;
  }
  
  void updateFormattedDate(String date) {
    formattedDate.value = date;
  }
  
  void updateFormattedInTime(String time) {
    formattedInTime.value = time;
  }
  
  void updateFormattedOutTime(String time) {
    formattedOutTime.value = time;
  }
}