class DeliveryOrderModel {
  int? id;
  String? orderStatus;
  double? deliveryFee;
  String? deliveryAddress;
  String? createdAt;
  String? otp;
  Restaurant? restaurant;
  Customer? customer;

  DeliveryOrderModel({
    this.id,
    this.orderStatus,
    this.deliveryFee,
    this.deliveryAddress,
    this.createdAt,
    this.otp,
    this.restaurant,
    this.customer,
  });

  DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // Soportar tanto 'order_status' como 'status'
    orderStatus = json['order_status'] ?? json['status'];
    deliveryFee = json['delivery_fee'] != null ? double.parse(json['delivery_fee'].toString()) : 0.0;
    
    // Soportar estructuras anidadas de dirección
    if (json['address'] is Map) {
      deliveryAddress = json['address']['street'] ?? json['address']['address'];
    } else {
      deliveryAddress = json['delivery_address'] ?? json['address'];
    }
    
    createdAt = json['created_at'] ?? json['delivered_at'];
    otp = json['otp'];
    
    restaurant = json['branch'] != null ? Restaurant.fromJson(json['branch']) : 
                 (json['restaurant'] != null ? Restaurant.fromJson(json['restaurant']) : null);
    
    customer = json['customer'] != null ? Customer.fromJson(json['customer']) : 
               (json['user'] != null ? Customer.fromJson(json['user']) : 
               (json['user'] != null ? Customer.fromJson(json['user']) : null));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_status': orderStatus,
      'delivery_fee': deliveryFee,
      'delivery_address': deliveryAddress,
      'created_at': createdAt,
      'otp': otp,
      'restaurant': restaurant?.toJson(),
      'customer': customer?.toJson(),
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
