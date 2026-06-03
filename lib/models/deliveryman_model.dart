class DeliverymanModel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? image;
  String? vehicleType;
  String? licensePlate;
  int? branchId;
  double? averageRating;
  int? totalReviews;
  bool? isAvailable;
  bool? isActive;

  DeliverymanModel({
    this.id,
    this.name = "",
    this.email = "",
    this.phone = "",
    this.image,
    this.vehicleType = "N/A",
    this.licensePlate = "N/A",
    this.branchId,
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
    // Prioritize absolute URLs starting with http/https over relative paths
    final String? rawImage = json['image']?.toString();
    final String? imageUrl = json['image_url']?.toString();
    final String? profilePhoto = json['profile_photo']?.toString();

    if (imageUrl != null && imageUrl.startsWith('http')) {
      image = imageUrl;
    } else if (profilePhoto != null && profilePhoto.startsWith('http')) {
      image = profilePhoto;
    } else if (rawImage != null && rawImage.startsWith('http')) {
      image = rawImage;
    } else {
      image = rawImage ?? imageUrl ?? profilePhoto;
    }
    vehicleType = json['vehicle_type'];
    licensePlate = json['license_plate'];
    branchId = json['branch_id'];
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
      'image': image,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'branch_id': branchId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_available': isAvailable,
      'is_active': isActive,
    };
  }
}
