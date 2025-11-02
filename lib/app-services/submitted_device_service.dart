import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubmittedDevicesService {
  static String _getStorageKey(String userId) {
    return 'submitted_devices_history_$userId';
  }

  /// Store submitted devices with location and timestamp
  static Future<void> storeSubmittedDevices({
    required List<String> deviceIdentifiers,
    required String locationId,
    required String locationDescription,
    required String userId, // NEW: Required parameter
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing data for this user
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );

    // Create submission record
    String submissionId =
        '${locationId}_${DateTime.now().millisecondsSinceEpoch}';
    Map<String, dynamic> submissionRecord = {
      'locationId': locationId,
      'locationDescription': locationDescription,
      'submittedAt': DateTime.now().toIso8601String(),
      'deviceIdentifiers': deviceIdentifiers,
      'deviceCount': deviceIdentifiers.length,
      'userId': userId, // Store userId in record
    };

    submittedData[submissionId] = submissionRecord;

    // Save back to storage with user-specific key
    String storageKey = _getStorageKey(userId);
    await prefs.setString(storageKey, jsonEncode(submittedData));

    print(
      '✅ Stored ${deviceIdentifiers.length} submitted devices for user: $userId, location: $locationDescription',
    );
  }

  /// Get all submitted devices data for a specific user
  static Future<Map<String, dynamic>> getSubmittedDevicesData({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String storageKey = _getStorageKey(userId);
    String? data = prefs.getString(storageKey);

    if (data == null || data.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing submitted devices data: $e');
      return {};
    }
  }

  /// Check if a device identifier has been submitted
  static Future<SubmissionStatus> checkDeviceSubmissionStatus({
    required String deviceIdentifier,
    required String locationId,
    required String userId, // NEW: Required parameter
  }) async {
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );

    for (var entry in submittedData.entries) {
      Map<String, dynamic> submission = entry.value as Map<String, dynamic>;

      // Check if submission is for the same location
      if (submission['locationId'] == locationId) {
        List<dynamic> identifiers =
            submission['deviceIdentifiers'] as List<dynamic>;

        if (identifiers.contains(deviceIdentifier)) {
          return SubmissionStatus(
            isSubmitted: true,
            submittedAt: DateTime.parse(submission['submittedAt'] as String),
            locationDescription: submission['locationDescription'] as String,
          );
        }
      }
    }

    return SubmissionStatus(isSubmitted: false);
  }

  /// Get all submitted device identifiers for a specific location
  static Future<Set<String>> getSubmittedDeviceIdentifiers({
    required String locationId,
    required String userId, // NEW: Required parameter
  }) async {
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );
    Set<String> allIdentifiers = {};

    for (var entry in submittedData.entries) {
      Map<String, dynamic> submission = entry.value as Map<String, dynamic>;

      if (submission['locationId'] == locationId) {
        List<dynamic> identifiers =
            submission['deviceIdentifiers'] as List<dynamic>;
        allIdentifiers.addAll(identifiers.cast<String>());
      }
    }

    return allIdentifiers;
  }

  /// Clear submitted devices for a specific location (user-scoped)
  static Future<void> clearLocationSubmissions({
    required String locationId,
    required String userId, // NEW: Required parameter
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );

    // Remove all submissions for this location
    submittedData.removeWhere((key, value) {
      Map<String, dynamic> submission = value as Map<String, dynamic>;
      return submission['locationId'] == locationId;
    });

    String storageKey = _getStorageKey(userId);
    await prefs.setString(storageKey, jsonEncode(submittedData));
    print('🗑️ Cleared submissions for user: $userId, location: $locationId');
  }

  /// Clear all submitted devices data for a specific user
  static Future<void> clearAllSubmissions({
    required String userId, // NEW: Required parameter
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String storageKey = _getStorageKey(userId);
    await prefs.remove(storageKey);
    print('🗑️ Cleared all submission history for user: $userId');
  }

  /// Clear all submitted devices data for ALL users (admin function)
  static Future<void> clearAllUsersSubmissions() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all keys
    Set<String> allKeys = prefs.getKeys();

    // Remove all keys that start with 'submitted_devices_history_'
    for (String key in allKeys) {
      if (key.startsWith('submitted_devices_history_')) {
        await prefs.remove(key);
      }
    }

    print('🗑️ Cleared all submission history for ALL users');
  }

  /// Get submission history for a location (user-scoped)
  static Future<List<SubmissionHistoryItem>> getLocationSubmissionHistory({
    required String locationId,
    required String userId, // NEW: Required parameter
  }) async {
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );
    List<SubmissionHistoryItem> history = [];

    for (var entry in submittedData.entries) {
      Map<String, dynamic> submission = entry.value as Map<String, dynamic>;

      if (submission['locationId'] == locationId) {
        history.add(
          SubmissionHistoryItem(
            submissionId: entry.key,
            locationDescription: submission['locationDescription'] as String,
            submittedAt: DateTime.parse(submission['submittedAt'] as String),
            deviceCount: submission['deviceCount'] as int,
          ),
        );
      }
    }

    // Sort by date (newest first)
    history.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return history;
  }

  /// Clean up old submissions (older than specified days) for a user
  static Future<void> cleanupOldSubmissions({
    required String userId,
    int daysToKeep = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> submittedData = await getSubmittedDevicesData(
      userId: userId,
    );

    DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    submittedData.removeWhere((key, value) {
      Map<String, dynamic> submission = value as Map<String, dynamic>;
      DateTime submittedAt = DateTime.parse(
        submission['submittedAt'] as String,
      );
      return submittedAt.isBefore(cutoffDate);
    });

    String storageKey = _getStorageKey(userId);
    await prefs.setString(storageKey, jsonEncode(submittedData));
    print(
      '🧹 Cleaned up submissions older than $daysToKeep days for user: $userId',
    );
  }

  /// Get all user IDs that have submission data (admin function)
  static Future<List<String>> getAllUserIds() async {
    final prefs = await SharedPreferences.getInstance();
    Set<String> allKeys = prefs.getKeys();
    List<String> userIds = [];

    for (String key in allKeys) {
      if (key.startsWith('submitted_devices_history_')) {
        String userId = key.replaceFirst('submitted_devices_history_', '');
        userIds.add(userId);
      }
    }

    return userIds;
  }
}

/// Status of device submission
class SubmissionStatus {
  final bool isSubmitted;
  final DateTime? submittedAt;
  final String? locationDescription;

  SubmissionStatus({
    required this.isSubmitted,
    this.submittedAt,
    this.locationDescription,
  });
}

/// Submission history item
class SubmissionHistoryItem {
  final String submissionId;
  final String locationDescription;
  final DateTime submittedAt;
  final int deviceCount;

  SubmissionHistoryItem({
    required this.submissionId,
    required this.locationDescription,
    required this.submittedAt,
    required this.deviceCount,
  });
}
