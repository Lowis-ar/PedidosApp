class DeliveryOrderModel {
  int? id;
  int? userId;
  String? orderStatus;
  double? total;
  double? deliveryFee;
  String? deliveryAddress;
  String? addressReferences;
  String? createdAt;
  String? otp;
  Restaurant? restaurant;
  Customer? customer;
  List<DeliveryOrderDetail>? details;

  DeliveryOrderModel({
    this.id,
    this.userId,
    this.orderStatus,
    this.total,
    this.deliveryFee,
    this.deliveryAddress,
    this.addressReferences,
    this.createdAt,
    this.otp,
    this.restaurant,
    this.customer,
    this.details,
  });

  DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];

    orderStatus = json['order_status'] ?? json['status'];
    total = json['total'] != null ? double.parse(json['total'].toString()) : null;
    deliveryFee = json['delivery_fee'] != null ? double.parse(json['delivery_fee'].toString()) : 0.0;

    if (json['address'] is Map) {
      final addr = json['address'] as Map;
      deliveryAddress = addr['street']?.toString() ?? addr['address']?.toString();
      addressReferences = addr['references']?.toString();
    } else {
      deliveryAddress = json['delivery_address']?.toString() ?? json['address']?.toString();
      addressReferences = null;
    }

    createdAt = json['created_at'] ?? json['delivered_at'];
    otp = json['otp']?.toString();

    restaurant = json['branch'] != null
        ? Restaurant.fromJson(json['branch'])
        : (json['restaurant'] != null ? Restaurant.fromJson(json['restaurant']) : null);

    customer = json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : (json['user'] != null ? Customer.fromJson(json['user']) : null);

    // Inyectar coordenadas desde address si no vienen en user
    if (customer != null && json['address'] is Map) {
      customer!.lat = json['address']['latitude']?.toString() ?? json['address']['lat']?.toString() ?? customer!.lat;
      customer!.lng = json['address']['longitude']?.toString() ?? json['address']['lng']?.toString() ?? customer!.lng;
    }

    if (json['details'] != null || json['items'] != null) {
      details = <DeliveryOrderDetail>[];
      var list = json['details'] ?? json['items'];
      if (list is List) {
        for (var v in list) {
          details!.add(DeliveryOrderDetail.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_status': orderStatus,
      'total': total,
      'delivery_fee': deliveryFee,
      'delivery_address': deliveryAddress,
      'address_references': addressReferences,
      'created_at': createdAt,
      'otp': otp,
      'restaurant': restaurant?.toJson(),
      'customer': customer?.toJson(),
      'details': details?.map((v) => v.toJson()).toList(),
    };
  }
}

class DeliveryOrderDetail {
  int? id;
  int? orderId;
  int? foodId;
  String? name;
  String? img;
  int? quantity;
  String? price;

  DeliveryOrderDetail({this.id, this.orderId, this.foodId, this.name, this.img, this.quantity, this.price});

  DeliveryOrderDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    foodId = json['product_id'] ?? json['food_id']; 
    name = json['product_name'] ?? json['name'];
    quantity = json['quantity'];
    price = json['price']?.toString();
    img = json['product_image'] ?? json['img'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': foodId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'img': img,
    };
  }
}

class Restaurant {
  String? name;
  String? address;
  String? phone;
  String? lat;
  String? lng;

  Restaurant({this.name, this.address, this.phone, this.lat, this.lng});

  Restaurant.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? json['branch_name'] ?? json['restaurant_name'];
    address = json['address'] ?? json['branch_address'];
    phone = json['phone'] ?? json['branch_phone'];
    lat = json['latitude'] ?? json['lat'];
    lng = json['longitude'] ?? json['lng'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': lat,
      'longitude': lng,
    };
  }
}

class Customer {
  String? name;
  String? phone;
  String? lat;
  String? lng;

  Customer({this.name, this.phone, this.lat, this.lng});

  Customer.fromJson(Map<String, dynamic> json) {
    name = json['f_name'] ?? json['name'] ?? json['full_name'];
    phone = json['phone'];
    lat = json['latitude'] ?? json['lat'];
    lng = json['longitude'] ?? json['lng'];
  }

  Map<String, dynamic> toJson() {
    return {
      'f_name': name,
      'phone': phone,
      'latitude': lat,
      'longitude': lng,
    };
  }
}
