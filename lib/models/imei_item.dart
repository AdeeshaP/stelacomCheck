// IMEI Item Model
class IMEIItem {
  final String imei;
  final String model;
  bool isVerified;
  DateTime? verificationTime;
  String? varianceReason;

  IMEIItem({
    required this.imei,
    required this.model,
    this.isVerified = false,
    this.verificationTime,
    this.varianceReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'imei': imei,
      'model': model,
      'isVerified': isVerified,
      'verificationTime': verificationTime?.toIso8601String(),
      'varianceReason': varianceReason,
    };
  }

  static IMEIItem fromJson(Map<String, dynamic> json) {
    return IMEIItem(
      imei: json['imei'],
      model: json['model'],
      isVerified: json['isVerified'] ?? false,
      verificationTime: json['verificationTime'] != null
          ? DateTime.parse(json['verificationTime'])
          : null,
      varianceReason: json['varianceReason'],
    );
  }
}