class DeliverymanModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? vehicleType;
  String? licensePlate;
  double? averageRating;
  int? totalReviews;
  bool? isAvailable;
  bool? isActive;

  DeliverymanModel({
    this.id,
    this.name = "",
    this.email = "",
    this.phone = "",
    this.vehicleType = "N/A",
    this.licensePlate = "N/A",
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isAvailable = false,
    this.isActive = false,
  });

  DeliverymanModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    vehicleType = json['vehicle_type'];
    licensePlate = json['license_plate'];
    averageRating = json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : 0.0;
    totalReviews = json['total_reviews'] != null ? int.parse(json['total_reviews'].toString()) : 0;
    isAvailable = json['is_available'] == 1 || json['is_available'] == true;
    isActive = json['is_active'] == 1 || json['is_active'] == true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_available': isAvailable,
      'is_active': isActive,
    };
  }
}
