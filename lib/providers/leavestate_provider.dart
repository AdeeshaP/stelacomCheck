import 'package:flutter/foundation.dart';

class LeaveState extends ChangeNotifier {
  List<dynamic> _dropdowndata = [];
  List<dynamic> _allLeaveList = [];

  List<dynamic> get data => _dropdowndata;
  List<dynamic> get allLeaveList => _allLeaveList;

  void updateData(List<dynamic> newData) {
    _dropdowndata = newData;
    notifyListeners();
  }

  void updateLeaveData(List<dynamic> newData) {
    _allLeaveList = newData;
    notifyListeners();
  }
}
