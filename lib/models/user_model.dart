class UserModel {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? role;
  int? orderCount;
  String? createdAt;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.role,
    this.orderCount,
    this.createdAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    role = json['role']; // Puede ser 'delivery', 'customer', etc.
    orderCount = json['order_count'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'order_count': orderCount,
      'created_at': createdAt,
    };
  }
}
