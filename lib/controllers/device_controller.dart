import 'package:get/get.dart';

class DeviceInfoController extends GetxController {
  // Observable device data
  var deviceData = <String, dynamic>{}.obs;
  var deviceGeneralData = <String, dynamic>{}.obs;
  var deviceDisplayData = <String, dynamic>{}.obs;

  // Getters
  Map<String, dynamic> get deviceDataValue => deviceData.value;
  Map<String, dynamic> get deviceGeneralDataValue => deviceGeneralData.value;
  Map<String, dynamic> get deviceDisplayDataValue => deviceDisplayData.value;

  // Methods to update device data
  void updateDeviceData(Map<String, dynamic> data) {
    deviceData.value = data;
  }

  void updateDeviceGeneralData(Map<String, dynamic> data) {
    deviceGeneralData.value = data;
  }

  void updateDeviceDisplayData(Map<String, dynamic> data) {
    deviceDisplayData.value = data;
  }

  // Clear device data
  void clearDeviceData() {
    deviceData.value = {};
    deviceGeneralData.value = {};
    deviceDisplayData.value = {};
  }
}