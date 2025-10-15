// models/device_item.dart
class DeviceItem {
  final String model;
  final String? imei;
  final String? serialNo;
  final bool serialized;
  final int? quantity; // For non-serialized items
  bool isVerified;
  DateTime? verificationTime;
  int quantityVerified; // For non-serialized items - how many have been verified
  String? varianceReason; // For items with variance reasons

  DeviceItem({
    required this.model,
    this.imei,
    this.serialNo,
    required this.serialized,
    this.quantity,
    this.isVerified = false,
    this.verificationTime,
    this.quantityVerified = 0, // Default to 0 verified
    this.varianceReason,
  });

  // Helper method to get the scannable identifier
  String? get scannableIdentifier {
    if (!serialized) return null; // Non-serialized items can't be scanned
    return imei ?? serialNo; // Prefer IMEI, fallback to serial number
  }

  // Helper method to determine device type
  String get deviceType {
    if (!serialized) return 'Non-Serialized';
    if (imei != null) return 'IMEI Device';
    if (serialNo != null) return 'Serial Number Device';
    return 'Unknown';
  }

  // Helper method to get display identifier
  String get displayIdentifier {
    if (imei != null) return 'IMEI: $imei';
    if (serialNo != null) return 'Serial: $serialNo';
    if (quantity != null) return 'Quantity: $quantityVerified/$quantity';
    return 'No identifier';
  }

  // Helper method to check if verification is complete
  bool get isFullyVerified {
    if (serialized) {
      return isVerified;
    } else {
      return quantityVerified >= (quantity ?? 0);
    }
  }

  // Helper method to get verification progress for non-serialized items
  double get verificationProgress {
    if (serialized || quantity == null || quantity == 0) return isVerified ? 1.0 : 0.0;
    return quantityVerified / quantity!;
  }

  // Convert to JSON for storage if needed
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'imei': imei,
      'serial_no': serialNo,
      'serialized': serialized,
      'quantity': quantity,
      'is_verified': isVerified,
      'verification_time': verificationTime?.toIso8601String(),
      'quantity_verified': quantityVerified,
      'variance_reason': varianceReason,
    };
  }

  // Create from JSON
  factory DeviceItem.fromJson(Map<String, dynamic> json) {
    return DeviceItem(
      model: json['model'],
      imei: json['imei'],
      serialNo: json['serial_no'],
      serialized: json['serialized'] ?? true,
      quantity: json['quantity'],
      isVerified: json['is_verified'] ?? false,
      verificationTime: json['verification_time'] != null
          ? DateTime.parse(json['verification_time'])
          : null,
      quantityVerified: json['quantity_verified'] ?? 0,
      varianceReason: json['variance_reason'],
    );
  }

  // Create from original JSON device format (for loading from assets)
  factory DeviceItem.fromDeviceJson(Map<String, dynamic> json) {
    bool isSerialized = json['serialized'] ?? false;
    
    return DeviceItem(
      model: json['model'],
      imei: json['imei'],
      serialNo: json['serial_no'],
      serialized: isSerialized,
      quantity: isSerialized ? null : json['quantity'],
      isVerified: false, // Always start unverified
      quantityVerified: 0, // Start with 0 verified
    );
  }

  // Copy with method for updating properties
  DeviceItem copyWith({
    String? model,
    String? imei,
    String? serialNo,
    bool? serialized,
    int? quantity,
    bool? isVerified,
    DateTime? verificationTime,
    int? quantityVerified,
    String? varianceReason,
  }) {
    return DeviceItem(
      model: model ?? this.model,
      imei: imei ?? this.imei,
      serialNo: serialNo ?? this.serialNo,
      serialized: serialized ?? this.serialized,
      quantity: quantity ?? this.quantity,
      isVerified: isVerified ?? this.isVerified,
      verificationTime: verificationTime ?? this.verificationTime,
      quantityVerified: quantityVerified ?? this.quantityVerified,
      varianceReason: varianceReason ?? this.varianceReason,
    );
  }

  @override
  String toString() {
    return 'DeviceItem(model: $model, serialized: $serialized, isVerified: $isVerified, quantityVerified: $quantityVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceItem &&
        other.model == model &&
        other.imei == imei &&
        other.serialNo == serialNo &&
        other.serialized == serialized;
  }

  @override
  int get hashCode {
    return Object.hash(model, imei, serialNo, serialized);
  }
}