class OrderModel {
  int? id;
  int? userId;
  String? orderAmount;
  String? orderStatus;
  String? orderNote;
  String? deliveryAddress;
  String? otp;
  String? createdAt;
  List<OrderDetail>? details;

  OrderModel({
    this.id,
    this.userId,
    this.orderAmount,
    this.orderStatus,
    this.orderNote,
    this.deliveryAddress,
    this.otp,
    this.createdAt,
    this.details,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    orderAmount = json['order_amount']?.toString() ?? json['total']?.toString();
    orderStatus = json['order_status'] ?? json['status'];
    orderNote = json['order_note'] ?? json['notes'];
    
    // Parse address
    if (json['delivery_address'] != null) {
      deliveryAddress = json['delivery_address'];
    } else if (json['address'] != null) {
      if (json['address'] is Map) {
        deliveryAddress = json['address']['street'] ?? json['address']['address'] ?? json['address']['label'];
      } else {
        deliveryAddress = json['address'].toString();
      }
    }
    
    otp = json['otp'];
    createdAt = json['created_at'];

    var detailsList = json['details'] ?? json['items'];
    if (detailsList != null && detailsList is Iterable) {
      details = <OrderDetail>[];
      for (var v in detailsList) {
        details!.add(OrderDetail.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_amount': orderAmount,
      'order_status': orderStatus,
      'order_note': orderNote,
      'delivery_address': deliveryAddress,
      'otp': otp,
      'created_at': createdAt,
      'details': details?.map((v) => v.toJson()).toList(),
    };
  }
}

class OrderDetail {
  int? id;
  int? orderId;
  int? foodId;
  String? price;
  int? quantity;
  String? name;
  String? img;

  OrderDetail({
    this.id,
    this.orderId,
    this.foodId,
    this.price,
    this.quantity,
    this.name,
    this.img,
  });

  OrderDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    foodId = json['product_id'] ?? json['food_id'];
    price = json['unit_price']?.toString() ?? json['price']?.toString();
    quantity = json['quantity'];
    name = json['product_name'] ?? json['name'];
    img = json['img'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'food_id': foodId,
      'price': price,
      'quantity': quantity,
      'name': name,
      'img': img,
    };
  }
}

class AddressModel {
  int? id;
  String? addressType;
  String? contactPersonNumber;
  String? address;
  String? latitude;
  String? longitude;
  int? userId;
  String? contactPersonName;

  AddressModel({
    this.id,
    this.addressType,
    this.contactPersonNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.userId,
    this.contactPersonName,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addressType = json['address_type'];
    contactPersonNumber = json['contact_person_number'];
    address = json['address'];
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    userId = json['user_id'];
    contactPersonName = json['contact_person_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address_type': addressType,
      'contact_person_number': contactPersonNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contact_person_name': contactPersonName,
    };
  }
}
