class UserModel {
  int? id;
  String? fName;
  String? phone;
  String? email;
  int? orderCount;
  String? createdAt;

  UserModel({
    this.id,
    this.fName,
    this.phone,
    this.email,
    this.orderCount,
    this.createdAt,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    phone = json['phone'];
    email = json['email'];
    orderCount = json['order_count'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'f_name': fName,
      'phone': phone,
      'email': email,
      'order_count': orderCount,
      'created_at': createdAt,
    };
  }
}
