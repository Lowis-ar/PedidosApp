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
    image = json['image'] ?? json['image_url'] ?? json['profile_photo'];
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
