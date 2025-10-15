// models/scanned_item.dart
class ScannedItem {
  final String barcode;
  final String identifier; // Could be IMEI or serial number
  final DateTime timestamp;
  final String deviceModel;
  final String deviceType; // New field to track device type

  ScannedItem({
    required this.barcode,
    required this.identifier,
    required this.timestamp,
    required this.deviceModel,
    required this.deviceType,
  });

  // Convert to JSON for storage if needed
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'identifier': identifier,
      'timestamp': timestamp.toIso8601String(),
      'device_model': deviceModel,
      'device_type': deviceType,
    };
  }

  // Create from JSON
  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      barcode: json['barcode'],
      identifier: json['identifier'],
      timestamp: DateTime.parse(json['timestamp']),
      deviceModel: json['device_model'],
      deviceType: json['device_type'] ?? 'Unknown',
    );
  }

  // Helper method to get formatted timestamp
  String get formattedTimestamp {
    return "${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} "
           "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}