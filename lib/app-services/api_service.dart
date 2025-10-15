import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class ApiService {
  static final String apiBaseUrl =
      'https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/';

  static dynamic verifyUserWithEmpCode(String empCode) async {
    try {
      var response = await http.get(Uri.parse(apiBaseUrl +
          'users/verifyByTheCode?Code=$empCode' +
          '&isEnabled=True'));

      return response;
    } catch (e) {
      print(e);
    }

    return [];
  }
 static dynamic verifyUserWithoutOTP(String empCode) async {
    try {
      var response = await http.get(Uri.parse(apiBaseUrl +
          'users/verifyByTheCode?Code=$empCode'));

      return response;
    } catch (e) {
      print(e);
    }

    return [];
  }

  static dynamic verifyUserOTPCode(String empCode, String otp) async {
    try {
      var response = await http.get(
        Uri.parse(apiBaseUrl +
            'users/verifyByTheCode?Code=' +
            empCode +
            '&isEnabled=True' +
            '&OTP=' +
            otp),
      );

      return response;
    } catch (e) {
      print(e);
    }

    return [];
  }

  static dynamic getTodayCheckInCheckOut(
      String userId, String customerId) async {
    var url = apiBaseUrl +
        'users/todayCheckInCheckOut?customerId=' +
        customerId +
        "&userId=" +
        userId +
        "&date=" +
        Jiffy.parseFromDateTime((new DateTime.now()))
            .format(pattern: "yyyy-MM-dd");
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getActions(String userId, String customerId, String startDate,
      String endDate) async {
    var url = apiBaseUrl +
        'services-user-get-actions?customerId=' +
        customerId +
        "&userId=" +
        userId +
        "&startDate=" +
        startDate +
        "&endDate=" +
        endDate;
    print(url);

    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic postApplyLeaves(
    String memberId,
    String memberName,
    String customerId,
    String leaveDate,
    String fromDate,
    String toDate,
    String noOfDays,
    String lastModifiedDate,
    String createdBy,
    String lastModifyBy,
    String status,
    String description,
    String type,
    bool isFullDay,
    String attachFilePath,
  ) async {
    final http.Response response = await http.post(
      Uri.parse(apiBaseUrl + 'services-leaves'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "MemberId": memberId,
        "MemberName": memberName,
        "CustomerId": customerId,
        "LeaveDate": leaveDate,
        "FromDate": fromDate,
        "ToDate": toDate,
        "NumOfDays": noOfDays.toString(),
        "CreatedDate": Jiffy.parseFromDateTime((new DateTime.now()))
            .format(pattern: "yyyy-MM-dd hh:mm:ss"),
        "LastModifiedDate": lastModifiedDate,
        "CreatedBy": createdBy,
        "LastModifiedBy": lastModifyBy,
        "Status": status,
        "Description": description,
        "Type": type,
        "IsFullday": isFullDay,
        // "Attachment" : attachFile,
        "Attachment": attachFilePath,
      }),
    );
    print('Response body: ${response.body.toString()}');
    return response;
  }

  static dynamic getMyCheckIns(String startDate, String endDate, String userId,
      String customerId) async {
    var url = apiBaseUrl +
        'users/myCheckIns?customerId=' +
        customerId +
        "&userId=" +
        userId +
        "&startDate=" +
        startDate +
        "&endDate=" +
        endDate;
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getMyLocationRestritions(
      String userId, String customerId) async {
    var url = apiBaseUrl +
        'services-user-location-restriction?MemberId=' +
        userId +
        '&Type=User';
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic updateFCMDeviceToken(String code, String deviceToken) async {
    final http.Response response = await http.put(
      Uri.parse(apiBaseUrl + 'services-user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Type': 'FCMDeviceToken',
        'Code': code,
        'UserId': code,
        'FCMDeviceToken': deviceToken
      }),
    );
    return response;
  }

  static dynamic getAllLocationRestritions(
      String userId, String customerId) async {
    var url = apiBaseUrl +
        'services-user-location-restriction?MemberId=' +
        userId +
        '&Type=All';
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getPopupProfileImageData(
    String eventDate,
    String userId,
    String customerId,
  ) async {
    var url = apiBaseUrl +
        'services-event-getDayEvents?CustomerId=' +
        customerId +
        "&EventDate=" +
        eventDate +
        "&MemberId=" +
        userId +
        "&GroupOrUser=user&ShiftId=";
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic postRegisteredDeviceInfo(
      String deviceModel,
      String androidVersion,
      int status,
      String userId,
      String createdDate,
      String lastModifiedDate,
      String createdBy,
      String lastModifyBy) async {
    final http.Response response = await http.post(
      Uri.parse(apiBaseUrl + 'services-register-devices'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "DeviceModel": deviceModel,
        "AndroidVersion": androidVersion,
        "Status": status.toString(),
        "MemberId": userId,
        "LastModifiedDate": lastModifiedDate,
        "CreatedBy": createdBy,
        "LastModifiedBy": lastModifyBy,
      }),
    );
    return response;
  }

  static dynamic getRegisteredDeviceInfo(String userId) async {
    var url = apiBaseUrl + 'services-register-devices?MemberId=' + userId;
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getWorkingHours(String customerId) async {
    var url = apiBaseUrl +
        'services-config-system-variable?CustomerId=' +
        customerId +
        "&Variable=Work_hours";
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getLeaveTypes(String customerId) async {
    var url = apiBaseUrl +
        'services-config-system-variable?CustomerId=' +
        customerId +
        "&Type=leave";
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getLeaves(
      String userId, String startDate, String endDate) async {
    var url = apiBaseUrl +
        'services-leaves?MemberId=' +
        userId +
        "&StartDate=" +
        startDate +
        "&EndDate=" +
        endDate;
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getLeavesCategorizedWithTypes(
      String userId, String custId, String startDate, String endDate) async {
    var url = apiBaseUrl +
        "services-leaves?CustomerId=" +
        custId +
        "&MemberId=" +
        userId +
        "&leaveCount=1&StartDate=" +
        startDate +
        "&EndDate=" +
        endDate;
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getIndividualSupervisorLeaveRequests(
      String custId, String supervisorId) async {
    var url = apiBaseUrl +
        "services-leaves?CustomerId=" +
        custId +
        "&SupervisorId=" +
        supervisorId +
        "&Status=Pending&IsGroup=0";
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic getGroupSupervisorLeaveRequests(
      String custId, String supervisorId) async {
    var url = apiBaseUrl +
        "services-leaves?CustomerId=" +
        custId +
        "&SupervisorId=" +
        supervisorId +
        "&Status=Pending&IsGroup=1";
    var response = await http.get(Uri.parse(url));
    return response;
  }

  static dynamic approveRejectLeaveBySupervisor(
    String leaveId,
    String memberId,
    String memberName,
    String customerId,
    String leaveDate,
    String fromDate,
    String toDate,
    String noOfDays,
    String createdDate,
    String lastModifiedDate,
    String createdBy,
    String lastModifyBy,
    String approvedBy,
    String status,
    String description,
    String type,
    int isFullDay,
    String attachFilePath,
  ) async {
    final http.Response response = await http.post(
      Uri.parse(apiBaseUrl + 'services-leaves'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "Id": leaveId,
        "MemberId": memberId,
        "MemberName": memberName,
        "CustomerId": customerId,
        "LeaveDate": leaveDate,
        "FromDate": fromDate,
        "ToDate": toDate,
        "NumOfDays": noOfDays.toString(),
        "CreatedDate": createdDate,
        "LastModifiedDate": lastModifiedDate,
        "CreatedBy": createdBy,
        "ApprovedBy": approvedBy,
        "LastModifiedBy": lastModifyBy,
        "Status": status,
        "Description": description,
        "Type": type,
        "IsFullday": isFullDay,
        "Attachment": attachFilePath,
      }),
    );
    return response;
  }

  static dynamic geOTHrsAndShifts(
      String customerId, String attendanceId) async {
    var url = apiBaseUrl +
        'services-manage-OT-hours?CustomerId=' +
        customerId +
        "&AttendanceId=" +
        attendanceId;
    var response = await http.get(Uri.parse(url));
    return response;
  }
}
