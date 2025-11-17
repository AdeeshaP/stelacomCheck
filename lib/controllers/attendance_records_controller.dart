import 'dart:convert';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stelacom_check/app-services/api_service.dart';

class AttendanceDashboardController extends GetxController {
  // Observable variables
  final from = DateTime.now().add(Duration(days: -7)).obs;
  final to = DateTime.now().obs;
  final visitShow = true.obs;
  final checkinShow = true.obs;
  final userActions = <dynamic>[].obs;
  final visitCount = 0.obs;
  final workedDayCount = 0.obs;
  final totalSecondsWorked = 0.0.obs;
  final isLoading = false.obs;
  final userWorkingHrs = <dynamic>[].obs;
  late SharedPreferences _storage;
  dynamic user;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    await getSharedPrefs();
    await getWorkingHoursForUser();
    getUserActivities(from.value, to.value);
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
  }

  Future<void> getWorkingHoursForUser() async {
    _storage = await SharedPreferences.getInstance();
    String userData = _storage.getString('user_data') ?? "";

    if (userData != "") {
      Map<String, dynamic> userObj2 = jsonDecode(userData);
      var response2 = await ApiService.getWorkingHours(userObj2["CustomerId"]);

      if (response2 != null &&
          response2.statusCode == 200 &&
          response2.body != "null") {
        userWorkingHrs.value = jsonDecode(response2.body);
      }
    }
  }

  Future<void> getUserActivities(DateTime fromDate, DateTime toDate) async {
    isLoading.value = true;

    try {
      var response = await ApiService.getActions(
        user["Id"],
        user["CustomerId"],
        Jiffy.parseFromDateTime(fromDate).format(pattern: "yyyy-MM-dd"),
        Jiffy.parseFromDateTime(toDate).format(pattern: "yyyy-MM-dd"),
      );

      if (response != null && response.statusCode == 200) {
        List<dynamic> list = jsonDecode(response.body);
        double secondsSum = 0;

        for (var item in list) {
          if (item['TotalSeconds'] != null) {
            secondsSum = secondsSum + item['TotalSeconds'];
          }
        }

        userActions.value = list;
        visitCount.value = list
            .where((element) => element['AttType'] == 'visit')
            .toList()
            .length;

        final chekinDays = list
            .where((element) => element['AttType'] == 'checkin')
            .toList()
            .map((e) => e['InTimeDate']);

        final distinctChekinDays = [];
        chekinDays.forEach((e) {
          if (!distinctChekinDays.contains(e)) {
            distinctChekinDays.add(e);
          }
        });

        workedDayCount.value = distinctChekinDays.length;
        totalSecondsWorked.value = secondsSum;
      }
    } catch (e) {
      print("Error fetching activities: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleVisibility(bool value, String type) {
    if (type == 'checkin') {
      checkinShow.value = value;
    } else if (type == 'visit') {
      visitShow.value = value;
    }
  }

  void updateFromDate(DateTime newDate) {
    from.value = newDate;
    getUserActivities(from.value, to.value);
  }

  void updateToDate(DateTime newDate) {
    to.value = newDate;
    getUserActivities(from.value, to.value);
  }

  String getTotalHoursWorked(double totalSeconds) {
    double remainder = totalSeconds % 3600;
    double hours = (totalSeconds - remainder) / 3600;
    double minute = remainder / 60;
    return hours.truncate().toString() +
        "h " +
        minute.truncate().toString() +
        "m ";
  }

  int getWorkingDays(DateTime fromDate, DateTime toDate) {
    final workingDays = <DateTime>[];
    DateTime indexDate = fromDate;

    while (indexDate.difference(toDate).inDays != 0) {
      final isWeekendDay =
          indexDate.weekday == DateTime.saturday ||
          indexDate.weekday == DateTime.sunday;
      if (!isWeekendDay) {
        workingDays.add(indexDate);
      }
      indexDate = indexDate.add(Duration(days: 1));
    }

    return workingDays.length;
  }

  List<dynamic> get filteredActions {
    return userActions
        .where(
          (i) =>
              (i['AttType'] == 'checkin' && checkinShow.value) ||
              (i['AttType'] == 'visit' && visitShow.value),
        )
        .toList();
  }
}
