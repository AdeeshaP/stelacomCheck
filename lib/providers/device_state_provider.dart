import 'package:flutter/foundation.dart';

class DeviceState extends ChangeNotifier {
  Map<String, dynamic> _deviceGeneralData = {};
  Map<String, dynamic> _deviceDisplayData = {};

  Map<String, dynamic> get deviceGeneralData => _deviceGeneralData;
  Map<String, dynamic> get deviceDisplayData => _deviceDisplayData;

  void updateDeviceGeneralData(Map<String, dynamic> data) {
    _deviceGeneralData = data;
    notifyListeners();
  }

  void updateDeviceDisplaylData(Map<String, dynamic> data2) {
    _deviceDisplayData = data2;
    notifyListeners();
  }
}
