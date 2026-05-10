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

  Product.fromJson(dynamic json) {
    _products = <ProductModel>[];
    if (json is Map) {
      // Soporte para meta data si existe
      if (json['meta'] != null && json['meta'] is Map) {
        _totalSize = json['meta']['total'];
        _offset = json['meta']['current_page'];
      } else {
        _totalSize = json['total_size'] ?? 0;
        _offset = json['offset'] ?? 0;
      }

      _typeId = json['type_id'] ?? 0;

      // Soporte para 'data' (Laravel Resource) o 'products' (Tutorial)
      var list = json['data'] ?? json['products'];
      if (list != null && list is Iterable) {
        for (var v in list) {
          _products.add(ProductModel.fromJson(v));
        }
      }
    } else if (json is Iterable) {
      for (var v in json) {
        _products.add(ProductModel.fromJson(v));
      }
    }
  }
}

class ProductModel {
  int? id;
  String? name;
  String? description;
  int? price;
  double? stars;
  String? timePreparation;
  String? img;
  String? location;
  String? createdAt;
  String? updatedAt;
  int? typeId;
  String? typeName;
  bool? isRecommended;
  bool? isPopular;
  CategoryModel? category;

  ProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.stars,
    this.timePreparation,
    this.img,
    this.location,
    this.createdAt,
    this.updatedAt,
    this.typeId,
    this.typeName,
    this.isRecommended,
    this.isPopular,
    this.category,
  });

  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description']?.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');
    
    // Precio
    var priceValue = json['base_price'] ?? json['price'];
    if (priceValue != null) {
      price = double.tryParse(priceValue.toString())?.toInt() ?? 0;
    }

    // Estrellas
    stars = double.tryParse(json['stars']?.toString() ?? "") ?? 5;

    // Tiempo de preparación
    timePreparation = json['time_preparation'];

    // Imagen
    img = json['image'] ?? json['img'];

    // Ubicación / Categoría
    location = json['location'] ?? "No especificada";
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    // Booleano de Laravel
    isRecommended = json['is_recommended'] == 1 || json['is_recommended'] == true;
    isPopular = json['is_popular'] == 1 || json['is_popular'] == true;

    // Categoría
    if (json['category'] != null) {
      category = CategoryModel.fromJson(json['category']);
      typeName = category?.name;
    } else {
      typeName = isRecommended! ? "Recomendado" : (isPopular! ? "Popular" : "Normal");
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stars': stars,
      'time_preparation': timePreparation,
      'img': img,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_recommended': isRecommended,
      'is_popular': isPopular,
      'category': category?.toJson(),
    };
  }
}

class CategoryModel {
  int? id;
  String? name;

  CategoryModel({this.id, this.name});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
