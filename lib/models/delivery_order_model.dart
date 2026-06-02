import 'dart:convert';

class DeliveryOrderModel {
  int? id;
  int? userId;
  String? orderStatus;
  String? paymentMethod;
  double? total;
  double? deliveryFee;
  String? deliveryAddress;
  String? addressReferences;
  String? createdAt;
  String? otp;
  Restaurant? restaurant;
  Customer? customer;
  List<DeliveryOrderDetail>? details;

  static const String STATUS_READY_TO_GO = 'ready_to_go';
  bool get isReadyToGo => orderStatus == STATUS_READY_TO_GO || orderStatus == 'pending';

  DeliveryOrderModel({
    this.id,
    this.userId,
    this.orderStatus,
    this.paymentMethod,
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

    orderStatus = (json['order_status'] ?? json['status'])?.toString().toLowerCase();
    paymentMethod = json['payment_method']?.toString() ?? json['payment_type']?.toString();
    
    // Parseo robusto: limpia caracteres no numéricos (comas, $, espacios) antes de parsear
    final totalRaw = json['order_amount'] ?? json['total'];
    if (totalRaw != null) {
      final cleanTotal = totalRaw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      total = double.tryParse(cleanTotal);
    }

    // Extraer la ganancia del repartidor priorizando el nuevo campo del backend.
    // 'deliveryman_payout' = tarifa fija de zona (lo que cobra el repartidor).
    // 'delivery_fee' = lo que paga el cliente (puede ser $0 si aplicó promo de envío gratis).
    // Ambos campos son independientes: los descuentos los absorbe el restaurante.
    final feeRaw = json['deliveryman_payout'] ?? json['delivery_fee'] ?? json['shipping_fee'];
    if (feeRaw != null) {
      final cleanFee = feeRaw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      deliveryFee = double.tryParse(cleanFee) ?? 0.0;
    } else {
      deliveryFee = 0.0;
    }

    restaurant = json['branch'] != null
        ? Restaurant.fromJson(json['branch'])
        : (json['restaurant'] != null ? Restaurant.fromJson(json['restaurant']) : null);

    customer = json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : (json['user'] != null ? Customer.fromJson(json['user']) : null);

    var deliveryAddrData = json['delivery_address'];
    if (deliveryAddrData is String && deliveryAddrData.trim().startsWith('{')) {
      try {
        deliveryAddrData = jsonDecode(deliveryAddrData);
      } catch (e) {
        // ignore
      }
    }

    if (deliveryAddrData is Map) {
      deliveryAddress = deliveryAddrData['address']?.toString() ?? deliveryAddrData['street']?.toString();
      addressReferences = deliveryAddrData['references']?.toString();
      
      customer ??= Customer();
      customer!.name ??= deliveryAddrData['contact_person_name'] ?? deliveryAddrData['name'];
      customer!.phone ??= deliveryAddrData['contact_person_number'] ?? deliveryAddrData['phone'];
      customer!.lat ??= deliveryAddrData['latitude']?.toString() ?? deliveryAddrData['lat']?.toString();
      customer!.lng ??= deliveryAddrData['longitude']?.toString() ?? deliveryAddrData['lng']?.toString();
    } else if (json['address'] is Map) {
      final addr = json['address'] as Map;
      deliveryAddress = addr['street']?.toString() ?? addr['address']?.toString();
      addressReferences = addr['references']?.toString();
      
      customer ??= Customer();
      customer!.lat ??= addr['latitude']?.toString() ?? addr['lat']?.toString();
      customer!.lng ??= addr['longitude']?.toString() ?? addr['lng']?.toString();
    } else {
      deliveryAddress = deliveryAddrData?.toString() ?? json['address']?.toString();
      addressReferences = null;
    }

    createdAt = json['created_at'] ?? json['delivered_at'];
    otp = json['otp']?.toString();

    // Inyectar coordenadas base si aun están nulas
    if (customer != null) {
      customer!.lat ??= json['latitude']?.toString() ?? json['lat']?.toString();
      customer!.lng ??= json['longitude']?.toString() ?? json['lng']?.toString();
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
      'payment_method': paymentMethod,
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
    // Soporta tanto 'unit_price' como 'price' según lo que devuelva el backend
    price = json['unit_price']?.toString() ?? json['price']?.toString();
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
