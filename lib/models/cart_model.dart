import 'package:pedidosapp/models/product_model.dart';

class CartModel {
  int? id;
  String? name;
  double? price;
  String? img;
  int? quantity;
  bool? isExist;
  String? time;
  ProductModel? product;
  int? variantId;
  List<int>? extras;
  String? notes;
  double? extrasPrice;

  CartModel({
    this.id,
    this.name,
    this.price,
    this.img,
    this.quantity,
    this.isExist,
    this.time,
    this.product,
    this.variantId,
    this.extras,
    this.notes,
    this.extrasPrice,
  });

  CartModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = json['price'] != null ? double.tryParse(json['price'].toString()) : null;
    img = json['img'];
    quantity = json['quantity'];
    isExist = json['isExist'];
    time = json['time'];
    product = json['product'] != null ? ProductModel.fromJson(json['product']) : null;
    variantId = json['variant_id'];
    extras = json['extras'] != null ? List<int>.from(json['extras']) : [];
    notes = json['notes'];
    extrasPrice = json['extras_price'] != null ? double.tryParse(json['extras_price'].toString()) : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'img': img,
      'quantity': quantity,
      'isExist': isExist,
      'time': time,
      'product': product?.toJson(),
      'variant_id': variantId,
      'extras': extras,
      'notes': notes,
      'extras_price': extrasPrice,
    };
  }
}