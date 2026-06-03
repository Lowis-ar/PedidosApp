class UserModel {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? image;
  String? role;
  int? orderCount;
  String? createdAt;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.image,
    this.role,
    this.orderCount,
    this.createdAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // Support both 'name' and 'f_name' from API
    name = json['name'] ?? json['f_name'];
    phone = json['phone'];
    email = json['email'];
    // Prioritize absolute URLs starting with http/https over relative paths
    final String? imageUrl = json['image_url']?.toString();
    final String? profilePhoto = json['profile_photo']?.toString();
    final String? rawImage = json['image']?.toString();

    if (imageUrl != null && imageUrl.startsWith('http')) {
      image = imageUrl;
    } else if (profilePhoto != null && profilePhoto.startsWith('http')) {
      image = profilePhoto;
    } else if (rawImage != null && rawImage.startsWith('http')) {
      image = rawImage;
    } else {
      image = imageUrl ?? profilePhoto ?? rawImage;
    }
    role = json['role'];
    orderCount = json['order_count'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'image': image,
      'role': role,
      'order_count': orderCount,
      'created_at': createdAt,
    };
  }
}
