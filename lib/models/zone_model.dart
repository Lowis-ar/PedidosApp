class ZoneModel {
  int id;
  String name;
  String city;
  String deliveryFee;
  bool isDeliverable;
  bool isActive;

  ZoneModel({
    required this.id,
    required this.name,
    required this.city,
    required this.deliveryFee,
    required this.isDeliverable,
    required this.isActive,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'],
      name: json['name'],
      city: json['city'] ?? "",
      deliveryFee: json['delivery_fee']?.toString() ?? "0.00",
      isDeliverable: json['is_deliverable'] == 1 || json['is_deliverable'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
