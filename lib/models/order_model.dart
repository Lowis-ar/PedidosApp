class OrderModel {
  int? id;
  int? userId;
  String? orderAmount;
  String? discountAmount;
  String? deliveryFee;
  String? subtotal;
  String? zoneName;
  String? orderStatus;
  String? orderNote;
  String? deliveryAddress;
  String? otp;
  String? createdAt;
  String? deliveredAt;
  String? deliveredAtIso;   // ISO for 24h window check
  String? reviewedAt;       // null = not yet reviewed
  String? cancelledAt;
  OrderDeliveryman? deliveryman;
  List<OrderDetail>? details;

  OrderModel({
    this.id,
    this.userId,
    this.orderAmount,
    this.discountAmount,
    this.deliveryFee,
    this.subtotal,
    this.zoneName,
    this.orderStatus,
    this.orderNote,
    this.deliveryAddress,
    this.otp,
    this.createdAt,
    this.deliveredAt,
    this.deliveredAtIso,
    this.reviewedAt,
    this.cancelledAt,
    this.deliveryman,
    this.details,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    orderAmount = json['order_amount']?.toString() ?? json['total']?.toString();
    discountAmount = json['discount_amount']?.toString() ?? '0';
    deliveryFee = json['delivery_fee']?.toString() ?? json['shipping_fee']?.toString();
    subtotal = json['subtotal']?.toString() ?? json['products_amount']?.toString();
    // Nombre de zona — puede venir como objeto o string directo
    if (json['zone'] != null && json['zone'] is Map) {
      zoneName = json['zone']['name']?.toString();
    } else {
      zoneName = json['zone_name']?.toString() ?? json['zone']?.toString();
    }
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
    
    otp = json['otp']?.toString();
    createdAt = json['created_at_fmt'] ?? json['created_at'];
    deliveredAt = json['delivered_at'];
    deliveredAtIso = json['delivered_at_iso'];
    reviewedAt = json['reviewed_at'];
    cancelledAt = json['cancelled_at'];

    if (json['deliveryman'] != null && json['deliveryman'] is Map) {
      deliveryman = OrderDeliveryman.fromJson(json['deliveryman']);
    }

    var detailsList = json['details'] ?? json['items'];
    if (detailsList != null && detailsList is Iterable) {
      details = <OrderDetail>[];
      for (var v in detailsList) {
        details!.add(OrderDetail.fromJson(v));
      }
    }
  }

  /// Returns true if this order needs a review (delivered, not reviewed, within 24h)
  bool get needsReview {
    if (orderStatus != 'delivered') return false;
    if (reviewedAt != null) return false;
    if (deliveredAtIso == null) return false;
    final deliveredTime = DateTime.tryParse(deliveredAtIso!);
    if (deliveredTime == null) return false;
    return DateTime.now().difference(deliveredTime).inHours < 24;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_amount': orderAmount,
      'delivery_fee': deliveryFee,
      'subtotal': subtotal,
      'zone_name': zoneName,
      'order_status': orderStatus,
      'order_note': orderNote,
      'delivery_address': deliveryAddress,
      'otp': otp,
      'created_at': createdAt,
      'delivered_at': deliveredAt,
      'delivered_at_iso': deliveredAtIso,
      'reviewed_at': reviewedAt,
      'deliveryman': deliveryman?.toJson(),
      'details': details?.map((v) => v.toJson()).toList(),
    };
  }
}

class OrderDetail {
  int? id;
  int? orderId;
  int? productId;
  String? price;          // precio unitario base (sin variante)
  String? totalPrice;     // precio total de esta línea
  int? quantity;
  String? name;
  String? img;
  String? variantName;
  String? variantPriceModifier; // modificador de precio de variante
  List<OrderDetailExtra>? extras;

  OrderDetail({
    this.id,
    this.orderId,
    this.productId,
    this.price,
    this.totalPrice,
    this.quantity,
    this.name,
    this.img,
    this.variantName,
    this.variantPriceModifier,
    this.extras,
  });

  OrderDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    productId = json['product_id'] ?? json['food_id'];
    price = json['unit_price']?.toString() ?? json['price']?.toString();
    totalPrice = json['total_price']?.toString() ?? json['line_total']?.toString() ?? json['subtotal']?.toString();
    quantity = json['quantity'];
    name = json['product_name'] ?? json['name'];
    img = json['product_image'] ?? json['img'];
    variantName = json['variant_name'];
    variantPriceModifier = json['variant_price_modifier']?.toString()
        ?? json['variant_price']?.toString();
    // Extras detallados
    var extrasRaw = json['extras'] ?? json['order_extras'];
    if (extrasRaw != null && extrasRaw is List) {
      extras = extrasRaw
          .map((e) => OrderDetailExtra.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'price': price,
      'quantity': quantity,
      'name': name,
      'img': img,
    };
  }
}

/// Extra individual dentro de un OrderDetail
class OrderDetailExtra {
  int? id;
  String? name;
  String? price;
  int? quantity;

  OrderDetailExtra({this.id, this.name, this.price, this.quantity});

  OrderDetailExtra.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? json['extra_id'];
    name = json['name'] ?? json['extra_name'];
    price = json['price']?.toString() ?? json['unit_price']?.toString();
    quantity = json['quantity'] ?? 1;
  }
}

/// Minimal deliveryman data returned with an order
class OrderDeliveryman {
  int? id;
  String? name;
  String? photo;

  OrderDeliveryman({this.id, this.name, this.photo});

  OrderDeliveryman.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    photo = json['photo'];
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'photo': photo};
}

class AddressModel {
  int? id;
  String? addressType;
  String? contactPersonNumber;
  String? address;
  String? references;
  String? latitude;
  String? longitude;
  int? userId;
  String? contactPersonName;
  int? zoneId;

  AddressModel({
    this.id,
    this.addressType,
    this.contactPersonNumber,
    this.address,
    this.references,
    this.latitude,
    this.longitude,
    this.userId,
    this.contactPersonName,
    this.zoneId = 1,
  });

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addressType = json['address_type'] ?? json['label'];
    contactPersonNumber = json['contact_person_number'] ?? json['phone'];
    address = json['address'] ?? json['street_address'] ?? json['street'];
    references = json['references'];
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    userId = json['user_id'];
    contactPersonName = json['contact_person_name'] ?? json['name'];
    zoneId = json['zone_id'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': addressType, 
      'street': address,
      'references': references,
      'zone_id': zoneId ?? 1,
      'latitude': latitude,
      'longitude': longitude,
      'contact_person_number': contactPersonNumber,
      'contact_person_name': contactPersonName,
    };
  }
}
