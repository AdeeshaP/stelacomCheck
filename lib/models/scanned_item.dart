// Scanned Item Model
class ScannedItem {
  final String barcode;
  final String imei;
  final DateTime timestamp;
  final String? deviceModel;

  ScannedItem({
    required this.barcode,
    required this.imei,
    required this.timestamp,
    this.deviceModel,
  });
}
