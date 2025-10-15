class TransferOrderItem {
  final List<String>? imeis;
  final List<String>? serialNos;
  final String model;
  final String brand;
  final int quantity;
  final bool serialized;
  final String category;

  TransferOrderItem({
    this.imeis,
    this.serialNos,
    required this.model,
    required this.brand,
    required this.quantity,
    required this.serialized,
    required this.category,
  });

  factory TransferOrderItem.fromJson(Map<String, dynamic> json) {
    return TransferOrderItem(
      imeis: json['imeis'] != null 
          ? List<String>.from(json['imeis']) 
          : null,
      serialNos: json['serial_nos'] != null 
          ? List<String>.from(json['serial_nos']) 
          : null,
      model: json['model'],
      brand: json['brand'],
      quantity: json['quantity'],
      serialized: json['serialized'],
      category: json['category'],
    );
  }

  // Get all identifiers as a list
  List<String> get identifiers {
    if (imeis != null) return imeis!;
    if (serialNos != null) return serialNos!;
    return [];
  }

  // Get first identifier for display purposes
  String get primaryIdentifier {
    if (imeis != null && imeis!.isNotEmpty) return imeis!.first;
    if (serialNos != null && serialNos!.isNotEmpty) return serialNos!.first;
    return 'N/A';
  }

  // Check if item has valid identifiers when serialized
  bool get hasValidIdentifiers {
    if (!serialized) return true; // Non-serialized items don't need identifiers
    return identifiers.length == quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'imeis': imeis,
      'serial_nos': serialNos,
      'model': model,
      'brand': brand,
      'quantity': quantity,
      'serialized': serialized,
      'category': category,
    };
  }
}

class TransferOrder2 {
  final String transferId;
  final String fromLocation;
  final String toLocation;
  final String assignedDate;
  final String status;
  final List<TransferOrderItem> items;

  TransferOrder2({
    required this.transferId,
    required this.fromLocation,
    required this.toLocation,
    required this.assignedDate,
    required this.status,
    required this.items,
  });

  factory TransferOrder2.fromJson(Map<String, dynamic> json) {
    return TransferOrder2(
      transferId: json['transfer_id'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      assignedDate: json['assigned_date'],
      status: json['status'],
      items: (json['items'] as List)
          .map((item) => TransferOrderItem.fromJson(item))
          .toList(),
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Get total number of serialized items
  int get totalSerializedItems => items
      .where((item) => item.serialized)
      .fold(0, (sum, item) => sum + item.quantity);

  // Get total number of non-serialized items
  int get totalNonSerializedItems => items
      .where((item) => !item.serialized)
      .fold(0, (sum, item) => sum + item.quantity);

  // Check if all serialized items have valid identifiers
  bool get hasValidSerializedItems => items
      .where((item) => item.serialized)
      .every((item) => item.hasValidIdentifiers);

  Map<String, dynamic> toJson() {
    return {
      'transfer_id': transferId,
      'from_location': fromLocation,
      'to_location': toLocation,
      'assigned_date': assignedDate,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}