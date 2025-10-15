import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stelacom_check/components/utils/custom_error_dialog.dart';
import 'package:stelacom_check/components/utils/dialogs.dart';
import 'package:stelacom_check/constants.dart';
import '../enroll/code_verification.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/enroll/enroll_user.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// OTP Input Screen
class OTPInputSreen extends StatefulWidget {
  OTPInputSreen({Key? key}) : super(key: key);

  @override
  State<OTPInputSreen> createState() => _OTPInputSreenState();
}

class _OTPInputSreenState extends State<OTPInputSreen> {
  List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  late SharedPreferences _storage;
  String empCode = "";

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    empCode = _storage.getString('employee_code') ?? "";
  }

  void resendCode() async {
    _storage = await SharedPreferences.getInstance();
    String empCode2 = _storage.getString('employee_code') ?? "";

    var response2 = await ApiService.verifyUserWithEmpCode(empCode2);
    print(response2);
  }

  void validateOTP(String otp) async {
    print("emp code is $empCode");
    print("otpCode is $otp");

    showProgressDialog(context);
    _storage = await SharedPreferences.getInstance();

    var response = await ApiService.verifyUserOTPCode(empCode, otp);
    closeDialog(context);

    if (response.body == "null" || response.body == null) {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error',
          message: 'Invalid OTP.',
          onOkPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CodeVerificationScreen(),
              ),
            );
          },
          iconData: Icons.error_outline,
        ),
      );
    } else {
      print("OTP Response body ${response.body}");

      Map<String, dynamic> userObj = jsonDecode(response.body);

      if (userObj["enrolled"] == 'done') {
        await _storage.setString('user_data', response.body);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(index2: 0),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => EnrollUser(userObj: userObj),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: appBgColor,
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              // Welcome Text
              Text(
                'Welcome to StelacomCheck\nAttendance & Inventory Management\nSystem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 20
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 20
                          : Responsive.isTabletPortrait(context)
                              ? 30
                              : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 60
                      : 100),
              // OTP Icon with checkmark
              Container(
                height: 150,
                child: Center(
                  child: Image.asset(
                    'assets/images/iCheck_logo_2024.png',
                    fit: BoxFit.fill,
                    scale: Responsive.isMobileSmall(context) ||
                            Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 2
                        : 1,
                  ),
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 40
                      : 60),
              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 20
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 22
                          : Responsive.isTabletPortrait(context)
                              ? 30
                              : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 10
                      : 30),
              Text(
                'Enter the OTP sent to your phone number',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Responsive.isMobileSmall(context)
                      ? 14
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 16
                          : Responsive.isTabletPortrait(context)
                              ? 25
                              : 25,
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 40
                      : 50), // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 40,
                    child: TextField(
                      cursorColor: actionBtnColor,
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 17
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 19
                                : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 25,
                      ),
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : 40), // Resend OTP text
              TextButton(
                onPressed: () {
                  resendCode();
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: iconColors,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                  ),
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : 30), // Verify Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String otp = otpControllers
                        .map((controller) => controller.text)
                        .join();
                    // Add verification logic here
                    print('Entered OTP: $otp');
                    validateOTP(otp);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Verify',
                    style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 16
                            : Responsive.isMobileMedium(context)
                                ? 18
                                : Responsive.isMobileLarge(context)
                                    ? 19
                                    : Responsive.isTabletPortrait(context)
                                        ? 25
                                        : 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
