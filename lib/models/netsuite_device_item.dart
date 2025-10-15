class NetsuiteDeviceItem {
  final int id; 
  final String itemCode; 
  final String model; 
  final String? number; // Serial Number or IMEI (from "Number" field)
  final String itemCategory; 
  final String location;
  final String onHand;
  final String available; 
  bool isVerified;
  DateTime? verificationTime;
  String? varianceReason; 

  NetsuiteDeviceItem({
    required this.id,
    required this.itemCode,
    required this.model,
    this.number,
    required this.itemCategory,
    required this.location,
    required this.onHand,
    required this.available,
    this.isVerified = false,
    this.verificationTime,
    this.varianceReason,
  });

  // Helper method to get the scannable identifier (Number field)
  String? get scannableIdentifier {
    return number; // The "Number" field contains Serial/IMEI
  }

  // Helper method to determine if item is serialized
  bool get serialized {
    return number != null && number!.isNotEmpty;
  }

  // Helper method to determine device type based on Number format
  String get deviceType {
    if (number == null || number!.isEmpty) return 'Non-Serialized';
    
    // Check if it's likely an IMEI (15 digits)
    if (RegExp(r'^\d{15}$').hasMatch(number!)) {
      return 'IMEI Device';
    }
    
    // Otherwise treat as Serial Number
    return 'Serial Number Device';
  }

  // Helper method to get display identifier
  String get displayIdentifier {
    if (number != null && number!.isNotEmpty) {
      if (deviceType == 'IMEI Device') {
        return 'IMEI: $number';
      }
      return 'Serial: $number';
    }
    return 'Item Code: $itemCode';
  }

  // Helper method to check if verification is complete
  bool get isFullyVerified {
    return isVerified;
  }

  // Helper method to get verification progress
  double get verificationProgress {
    return isVerified ? 1.0 : 0.0;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_code': itemCode,
      'model': model,
      'number': number,
      'item_category': itemCategory,
      'location': location,
      'on_hand': onHand,
      'available': available,
      'is_verified': isVerified,
      'verification_time': verificationTime?.toIso8601String(),
      'variance_reason': varianceReason,
    };
  }

  // Create from JSON (for loading saved data)
  factory NetsuiteDeviceItem.fromJson(Map<String, dynamic> json) {
    return NetsuiteDeviceItem(
      id: json['id'],
      itemCode: json['item_code'],
      model: json['model'],
      number: json['number'],
      itemCategory: json['item_category'],
      location: json['location'],
      onHand: json['on_hand'],
      available: json['available'],
      isVerified: json['is_verified'] ?? false,
      verificationTime: json['verification_time'] != null
          ? DateTime.parse(json['verification_time'])
          : null,
      varianceReason: json['variance_reason'],
    );
  }

  // Create from NetSuite API JSON format
  factory NetsuiteDeviceItem.fromNetSuiteJson(Map<String, dynamic> json) {
    return NetsuiteDeviceItem(
      id: json['id'],
      itemCode: json['Item Code'] ?? '',
      model: json['Item'] ?? '',
      number: json['Number'], // This is the Serial Number or IMEI
      itemCategory: json['(c)Item Category'] ?? '',
      location: json['Location'] ?? '',
      onHand: json['On Hand']?.toString() ?? '0',
      available: json['Available']?.toString() ?? '0',
      isVerified: false, // Always start unverified
    );
  }

  // Copy with method for updating properties
  NetsuiteDeviceItem copyWith({
    int? id,
    String? itemCode,
    String? model,
    String? number,
    String? itemCategory,
    String? location,
    String? onHand,
    String? available,
    bool? isVerified,
    DateTime? verificationTime,
    String? varianceReason,
  }) {
    return NetsuiteDeviceItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      model: model ?? this.model,
      number: number ?? this.number,
      itemCategory: itemCategory ?? this.itemCategory,
      location: location ?? this.location,
      onHand: onHand ?? this.onHand,
      available: available ?? this.available,
      isVerified: isVerified ?? this.isVerified,
      verificationTime: verificationTime ?? this.verificationTime,
      varianceReason: varianceReason ?? this.varianceReason,
    );
  }

  @override
  String toString() {
    return 'NetsuiteDeviceItem(id: $id, model: $model, number: $number, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetsuiteDeviceItem &&
        other.id == id &&
        other.number == number;
  }

  @override
  int get hashCode {
    return Object.hash(id, number);
  }
}