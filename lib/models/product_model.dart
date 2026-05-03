class Product {
  int? _totalSize;
  int? _typeId;
  int? _offset;
  late List<ProductModel> _products;
  List<ProductModel> get products => _products;

  Product({required totalSize, required typeId, required offset, required products}) {
    _totalSize = totalSize;
    _typeId = typeId;
    _offset = offset;
    _products = products;
  }

  Product.fromJson(Map<String, dynamic> json) {
    _totalSize = json['total_size'];
    _typeId = json['type_id'];
    _offset = json['offset'];
    _products = <ProductModel>[];
    if (json['products'] != null) {
      json['products'].forEach((v) {
        _products.add(ProductModel.fromJson(v));
      });
    }
  }
}

class ProductModel {
  int? id;
  String? name;
  String? description;
  int? price;
  int? stars;
  String? img;
  String? location;
  String? createdAt;
  String? updatedAt;
  int? typeId;
  String? typeName;

  ProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.stars,
    this.img,
    this.location,
    this.createdAt,
    this.updatedAt,
    this.typeId,
    this.typeName,
  });

  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    // Handle price as int, double, or string from API
    if (json['price'] != null) {
      if (json['price'] is int) {
        price = json['price'];
      } else if (json['price'] is double) {
        price = (json['price'] as double).toInt();
      } else if (json['price'] is String) {
        price = double.tryParse(json['price'])?.toInt();
      }
    }
    stars = json['stars'];
    img = json['img'];
    location = json['location'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    typeId = json['type_id'];
    typeName = json['type_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stars': stars,
      'img': img,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'type_id': typeId,
      'type_name': typeName,
    };
  }
}