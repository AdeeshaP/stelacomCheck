
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/controllers/attendance_records_controller.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/attendance-dashboard/flat_toggle_button.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:jiffy/jiffy.dart';

class AttendanceDashboardScreen extends StatelessWidget {
  final dynamic user;
  final int index3;

  AttendanceDashboardScreen({
    Key? key,
    required this.user,
    required this.index3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller with user data
    final controller = Get.put(AttendanceDashboardController());
    controller.user = user;

    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: appBgColor,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _buildDateSelectors(controller, context),
            SizedBox(height: 15),
            _buildSummaryCard(controller, context),
            SizedBox(height: 10),
            _buildActionsList(controller, context, size),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appbarBgColor,
      toolbarHeight:
          Responsive.isMobileSmall(context) ||
              Responsive.isMobileMedium(context) ||
              Responsive.isMobileLarge(context)
          ? 40
          : Responsive.isTabletPortrait(context)
          ? 80
          : 90,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 90.0
                : Responsive.isTabletPortrait(context)
                ? 150
                : 170,
            height:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 40.0
                : Responsive.isTabletPortrait(context)
                ? 120
                : 100,
            child: Image.asset(
              'assets/images/iCheck_logo_2024.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.25),
          SizedBox(
            width:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 90.0
                : Responsive.isTabletPortrait(context)
                ? 150
                : 170,
            height:
                Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
                ? 40.0
                : Responsive.isTabletPortrait(context)
                ? 120
                : 100,
            child: user != null
                ? CachedNetworkImage(
                    imageUrl: user!['CompanyProfileImage'],
                    placeholder: (context, url) => Text("..."),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  )
                : Text(""),
          ),
        ],
      ),
      actions: <Widget>[
        PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (choice) => _handleMenuAction(choice, context),
          itemBuilder: (BuildContext context) {
            return _getMenuOptions().map((String choice) {
              return PopupMenuItem<String>(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 15
                      : 20,
                  vertical:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 5
                      : 10,
                ),
                value: choice,
                child: Text(
                  choice,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 15
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 17
                        : Responsive.isTabletPortrait(context)
                        ? 25
                        : 25,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  List<String> _getMenuOptions() {
    return ['Help', 'About Us', 'Contact Us', 'T & C', 'Log Out'];
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final options = _getMenuOptions();
    // Handle navigation using GetX
    if (choice == options[0]) {
      Get.to(() => HelpScreen(index3: index3));
    } else if (choice == options[1]) {
      Get.to(() => AboutUs(index3: index3));
    } else if (choice == options[2]) {
      Get.to(() => ContactUs(index3: index3));
    } else if (choice == options[3]) {
      Get.to(() => TermsAndConditions(index3: index3));
    } else if (choice == options[4]) {
      LogoutService.logoutWithOptions(context);
    }
  }

  Widget _buildDateSelectors(
    AttendanceDashboardController controller,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDatePicker(
              context: context,
              label: "From Date",
              date: controller.from,
              onDateSelected: controller.updateFromDate,
            ),
            _buildDatePicker(
              context: context,
              label: "To Date",
              date: controller.to,
              onDateSelected: controller.updateToDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required Rx<DateTime> date,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: Responsive.isMobileSmall(context)
                ? 12
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 14
                : Responsive.isTabletPortrait(context)
                ? 18
                : 20,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1)),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: screenHeadingColor,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  ),
                );
              },
              context: context,
              initialDate: date.value,
              firstDate: DateTime(1950),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: Responsive.isMobileSmall(context)
                        ? 16
                        : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                        ? 18
                        : Responsive.isTabletPortrait(context)
                        ? 22
                        : 25,
                    color: iconColors,
                  ),
                  SizedBox(width: 8),
                  Text(
                    Jiffy.parseFromDateTime(
                      date.value,
                    ).format(pattern: "yyyy/MM/dd"),
                    style: TextStyle(
                      fontSize: Responsive.isMobileSmall(context)
                          ? 14
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 16
                          : Responsive.isTabletPortrait(context)
                          ? 20
                          : 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    AttendanceDashboardController controller,
    BuildContext context,
  ) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 11, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 18
                      : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                      ? 20
                      : Responsive.isTabletPortrait(context)
                      ? 22
                      : 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryItem(
                    context,
                    'Working Days',
                    '${controller.getWorkingDays(controller.from.value, controller.to.value) + 1}',
                    numberColors,
                  ),
                  _buildSummaryItemWithToggle(
                    context,
                    controller,
                    'Days Present',
                    '${controller.workedDayCount.value}',
                    'checkin',
                  ),
                  _buildSummaryItem(
                    context,
                    'Hours Worked',
                    controller.getTotalHoursWorked(
                      controller.totalSecondsWorked.value,
                    ),
                    numberColors,
                  ),
                ],
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  _buildSummaryItemWithToggle(
                    context,
                    controller,
                    'Visits',
                    '${controller.visitCount.value}',
                    'visit',
                  ),
                  _buildSummaryItem(
                    context,
                    'Days Absent',
                    '${(controller.getWorkingDays(controller.from.value, controller.to.value) + 1 - controller.workedDayCount.value)}',
                    numberColors,
                  ),
                  _buildSummaryItem(
                    context,
                    'Working Hours',
                    controller.userWorkingHrs.length > 0
                        ? controller.userWorkingHrs[0]["Value"]
                        : "",
                    numberColors,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.isMobileSmall(context)
                  ? 12
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 13
                  : Responsive.isTabletPortrait(context)
                  ? 18
                  : 18,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 16
                  : Responsive.isTabletPortrait(context)
                  ? 20
                  : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItemWithToggle(
    BuildContext context,
    AttendanceDashboardController controller,
    String label,
    String value,
    String type,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.isMobileSmall(context)
                  ? 12
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 13
                  : Responsive.isTabletPortrait(context)
                  ? 18
                  : 18,
            ),
          ),
          SizedBox(height: 5),
          FlatToggleButton(
            buttonText: value,
            toggled: (val, type) => controller.toggleVisibility(val, type),
            type: type,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList(
    AttendanceDashboardController controller,
    BuildContext context,
    Size size,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
        height: size.width * 0.9,
        child: controller.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: controller.filteredActions
                      .map((item) => _buildActionCard(context, item))
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, dynamic item) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          item['MonthName'],
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 10
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 14
                                : Responsive.isTabletPortrait(context)
                                ? 20
                                : 22,
                          ),
                        ),
                        Text(
                          item['Day'],
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 16
                                : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                ? 18
                                : Responsive.isTabletPortrait(context)
                                ? 20
                                : 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTimeColumn(context, item, 'In'),
                      if (item['AttType'] != 'visit')
                        _buildTimeColumn(context, item, 'Out')
                      else
                        Container(
                          width: Responsive.isMobileSmall(context)
                              ? 60
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 70
                              : Responsive.isTabletPortrait(context)
                              ? 90
                              : 100,
                        ),
                      if (item['AttType'] != 'visit')
                        _buildTimeSpentColumn(context, item)
                      else
                        Container(
                          width: Responsive.isMobileSmall(context)
                              ? 80
                              : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                              ? 90
                              : Responsive.isTabletPortrait(context)
                              ? 100
                              : 150,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimeColumn(BuildContext context, dynamic item, String type) {
    String label = type == 'In'
        ? (item['AttType'] == 'visit' ? "Visit" : "Check In")
        : "Check Out";
    String timeValue = type == 'In'
        ? item['InTimeValue']
        : item['OutTimeValue'];
    bool isError = timeValue == '-' && type == 'Out';

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 11
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 12
                : Responsive.isTabletPortrait(context)
                ? 15
                : 20,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3),
        Container(
          width: Responsive.isMobileSmall(context)
              ? 60
              : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
              ? 70
              : Responsive.isTabletPortrait(context)
              ? 90
              : 100,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isError
                ? Color(0xFFD32F2F).withOpacity(0.1)
                : Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeValue,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 11
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 15
                  : Responsive.isTabletPortrait(context)
                  ? 18
                  : 22,
              fontWeight: FontWeight.w500,
              color: isError ? Color(0xFFD32F2F) : Color(0xFF4CAF50),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSpentColumn(BuildContext context, dynamic item) {
    bool isError = item['TimeSpent'] == '-';

    return Column(
      children: [
        Text(
          "Time Spent",
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 11
                : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                ? 12
                : Responsive.isTabletPortrait(context)
                ? 16
                : 19,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3),
        Container(
          width: Responsive.isMobileSmall(context)
              ? 80
              : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
              ? 90
              : Responsive.isTabletPortrait(context)
              ? 100
              : 150,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isError
                ? Color(0xFFD32F2F).withOpacity(0.1)
                : Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item['TimeSpent'],
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 11
                  : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                  ? 15
                  : Responsive.isTabletPortrait(context)
                  ? 18
                  : 22,
              fontWeight: FontWeight.w500,
              color: isError ? Color(0xFFD32F2F) : Color(0xFF4CAF50),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
