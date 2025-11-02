import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stelacom_check/app-services/submitted_device_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/screens/enroll/code_verification.dart';

class LogoutService {
  static Future<String?> _getCurrentUserId() async {
    final _storage = await SharedPreferences.getInstance();

    // Get from user data
    String userData = _storage.getString('user_data') ?? "";
    if (userData.isNotEmpty) {
      try {
        Map<String, dynamic> userObj = jsonDecode(userData);
        return userObj['id']?.toString();
      } catch (e) {
        print('Error parsing user data in logout: $e');
      }
    }

    return null;
  }

  /// Perform logout with selective clearing
  static Future<void> logout(
    BuildContext context, {
    bool clearSubmissionHistory = false,
  }) async {
    final _storage = await SharedPreferences.getInstance();

    print('🔍 Logout initiated');
    print('🔍 Clear submission history: $clearSubmissionHistory');

    if (clearSubmissionHistory) {
      // Get current user ID BEFORE clearing user data
      String? userId = await _getCurrentUserId();
      
      if (userId != null && userId.isNotEmpty) {
        print('🗑️ Clearing submission history for user: $userId');
        await SubmittedDevicesService.clearAllSubmissions(userId: userId);
        print('✅ Submission history cleared successfully');
      }
      
      // Clear all storage data only if checkbox is checked
      await _storage.clear();
      print('✅ All session data cleared');
    } else {
      // Only clear user session data, keep submission history
      await _storage.remove('user_data');
      await _storage.remove('employee_code');
      print('✅ User session data cleared, submission history preserved');
    }

    // Navigate to login screen
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => CodeVerificationScreen()),
        (route) => false,
      );
    }
  }

  /// Logout with option to clear submission history
  static Future<void> logoutWithOptions(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => _LogoutOptionsDialog(),
    );

    // Only proceed with logout if user confirmed (not null)
    if (result != null) {
      print('🔐 User confirmed logout with clearHistory: $result');
      await logout(context, clearSubmissionHistory: result);
    } else {
      print('❌ Logout cancelled by user');
    }
  }
}

class _LogoutOptionsDialog extends StatefulWidget {
  @override
  _LogoutOptionsDialogState createState() => _LogoutOptionsDialogState();
}

class _LogoutOptionsDialogState extends State<_LogoutOptionsDialog> {
  bool clearHistory = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with circular background
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout, color: Colors.orange[700], size: 60),
            ),
            SizedBox(height: 25),

            // Title
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),

            // Message
            Text(
              'Are you sure you want to log out of your account?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),

            // Checkbox option with clean styling
            InkWell(
              onTap: () {
                setState(() {
                  clearHistory = !clearHistory;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: clearHistory ? Colors.grey[100] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: clearHistory ? Colors.grey[400]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: clearHistory ? actionBtnColor : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: clearHistory
                              ? actionBtnColor
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: clearHistory
                          ? Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clear my submission history',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Allows re-scanning of verified devices',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Returns null (cancel)
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Return the clearHistory value
                      print('📤 Dialog returning clearHistory: $clearHistory');
                      Navigator.pop(context, clearHistory);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionBtnColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}