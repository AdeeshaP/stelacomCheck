import 'package:flutter/material.dart';
import 'package:stelacom_check/components/utils/custom_error_dialog.dart';
import 'package:stelacom_check/components/utils/dialogs.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/app-services/api_service.dart';
import 'package:stelacom_check/responsive.dart';
import 'package:stelacom_check/screens/enroll/otp_input_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CodeVerificationScreen extends StatefulWidget {
  CodeVerificationScreen({Key? key}) : super(key: key);

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final codeController = TextEditingController();
  late SharedPreferences _storage;
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void handleCodeVerification(String code) async {
    showProgressDialog(context);
    _storage = await SharedPreferences.getInstance();

    try {
      var response = await ApiService.verifyUserWithEmpCode(code);
      closeDialog(context);

      if (response.body == "NoRecordsFound") {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Error',
            message: 'Invalid code. Please try with a valid code.',
            onOkPressed: () => Navigator.of(context).pop(),
            iconData: Icons.error_outline,
          ),
        );
        return;
      } else {
        _storage.setString('employee_code', code);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return OTPInputSreen();
        }));
      }
    } catch (ex) {
      closeDialog(context);
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error occured.!',
          message: 'Failed. Please try again.',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
          iconData: Icons.error_outline,
        ),
      );
    }
  }

  retryahndler() {
    closeDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;

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
                      : 100), // OTP Icon
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
                'Code Verification',
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
                'We will send you one-time password\nto your mobile number registered with your employee code.',
                textAlign: TextAlign.center,
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
                      : 50),
              // Empoyee Code Input
              Form(
                key: _key,
                child: TextFormField(
                  cursorColor: actionBtnColor,
                  autofocus: true,
                  controller: codeController,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 16
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 18
                            : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                  ),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide()),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.transparent)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.transparent)),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      hintText: 'Enter your employee code',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: Responsive.isMobileSmall(context)
                            ? 18
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 20
                                : Responsive.isTabletPortrait(context)
                                    ? 25
                                    : 25,
                      )),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(
                  height: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : 30),

              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _key.currentState!.validate()
                        ? handleCodeVerification(codeController.text)
                        : ();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Get OTP',
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
                      fontWeight: FontWeight.bold,
                    ),
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
