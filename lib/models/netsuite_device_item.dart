class NetsuiteDeviceItem {
  final int id;
  final String itemCode;
  final String item;
  final String? serialNumber;
  final String itemCategory;
  final String location;
  final bool isSerialized;
  bool isVerified;
  DateTime? verificationTime;
  String? varianceReason;
  int quantityVerified;
  final int? quantity;

  NetsuiteDeviceItem({
    required this.id,
    required this.itemCode,
    required this.item,
    this.serialNumber,
    required this.itemCategory,
    required this.location,
    required this.isSerialized,
    this.isVerified = false,
    this.verificationTime,
    this.varianceReason,
    this.quantityVerified = 0,
    this.quantity,
  });

  // Helper method to get the scannable identifier
  String? get scannableIdentifier {
    // Only serialized items can be scanned
    if (isSerialized) {
      return serialNumber;
    }
    return null;
  }

  // Helper method to check if verification is complete
  bool get isFullyVerified {
    if (isSerialized) {
      return isVerified;
    } else {
      return quantityVerified >= (quantity ?? 0);
    }
  }

  // Helper method to get verification progress
  double get verificationProgress {
    if (isSerialized || quantity == null || quantity == 0) {
      return isVerified ? 1.0 : 0.0;
    }
    return quantityVerified / quantity!;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_code': itemCode,
      'item': item,
      'serial_number': serialNumber,
      'item_category': itemCategory,
      'location': location,
      'isSerialized': isSerialized,
      'is_verified': isVerified,
      'verification_time': verificationTime?.toIso8601String(),
      'variance_reason': varianceReason,
      'quantity': quantity,
      'quantity_verified': quantityVerified,
    };
  }

  // Create from JSON (for loading saved data)
  factory NetsuiteDeviceItem.fromJson(Map<String, dynamic> json) {
    return NetsuiteDeviceItem(
      id: json['id'],
      itemCode: json['item_code'],
      item: json['item'],
      serialNumber: json['serial_number'],
      itemCategory: json['item_category'],
      location: json['location'],
      isSerialized: json['isSerialized'] ?? false,
      isVerified: json['is_verified'] ?? false,
      verificationTime: json['verification_time'] != null
          ? DateTime.parse(json['verification_time'])
          : null,
      varianceReason: json['variance_reason'],
      quantity: json['quantity'],
      quantityVerified: json['quantity_verified'] ?? 0,
    );
  }

  // Create from NetSuite API JSON format (device_list2.json)
  factory NetsuiteDeviceItem.fromNetSuiteJson(Map<String, dynamic> json) {
    bool isSerialized = json['Is_Serialized'] ?? false;

    // Parse quantity - it comes as string from API
    int? parsedQuantity;
    if (!isSerialized && json['Quantity'] != null) {
      parsedQuantity = int.tryParse(json['Quantity'].toString());
    }

    return NetsuiteDeviceItem(
      id: json['id'],
      itemCode: json['Item_Code'] ?? '',
      item: json['Item'] ?? '',
      serialNumber: json['Serial_Number'],
      itemCategory: json['Item_Category'] ?? '',
      location: json['Location'] ?? '',
      isSerialized: isSerialized,
      isVerified: false,
      quantity: parsedQuantity,
      quantityVerified: 0,
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
    bool? serialized,
    bool? isVerified,
    DateTime? verificationTime,
    String? varianceReason,
    int? quantity,
    int? quantityVerified,
  }) {
    return NetsuiteDeviceItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      item: model ?? this.item,
      serialNumber: number ?? this.serialNumber,
      itemCategory: itemCategory ?? this.itemCategory,
      location: location ?? this.location,
      isSerialized: serialized ?? this.isSerialized,
      isVerified: isVerified ?? this.isVerified,
      verificationTime: verificationTime ?? this.verificationTime,
      varianceReason: varianceReason ?? this.varianceReason,
      quantity: quantity ?? this.quantity,
      quantityVerified: quantityVerified ?? this.quantityVerified,
    );
  }

  @override
  String toString() {
    return 'NetsuiteDeviceItem(id: $id, item: $item, serial_number: $serialNumber, is_serialized: $isSerialized, isVerified: $isVerified, quantityVerified: $quantityVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetsuiteDeviceItem &&
        other.id == id &&
        other.serialNumber == serialNumber &&
        other.isSerialized == isSerialized;
  }

  @override
  int get hashCode {
    return Object.hash(id, serialNumber, isSerialized);
  }
}