import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/cart_controller.dart';

import '../data/repository/popular_product_repo.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../utils/colors.dart';
import '../utils/app_snackbar.dart';

class PopularProductController extends GetxController {
  final PopularProductRepo popularProductRepo;
  PopularProductController({required this.popularProductRepo});
  List<ProductModel> _popularProductList = [];
  List<ProductModel> get popularProductList => _popularProductList;
  late CartController _cart;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  int _quantity = 1;
  int get quantity => _quantity;
  int get inCartItems => _quantity;

  ProductModel? _product;
  ProductModel? get product => _product;

  ProductVariant? _selectedVariant;
  ProductVariant? get selectedVariant => _selectedVariant;

  final Map<int, int> _extraQuantities = {};
  Map<int, int> get extraQuantities => _extraQuantities;

  String _notes = "";
  String get notes => _notes;

  double get unitPrice {
    double base = _product?.price ?? 0.0;
    double variantMod = 0.0;
    if (_selectedVariant != null) {
      variantMod = _selectedVariant!.priceModifier ?? 0.0;
    }
    return base + variantMod;
  }

  double get extrasPrice {
    double extrasSum = 0.0;
    if (_product?.extras != null) {
      _extraQuantities.forEach((id, qty) {
        if (qty > 0) {
          try {
            var extra = _product!.extras!.firstWhere((e) => e.id == id);
            extrasSum += (extra.price ?? 0.0) * qty;
          } catch (e) {
            // Extra not found
          }
        }
      });
    }
    return extrasSum;
  }

  void selectVariant(ProductVariant variant) {
    _selectedVariant = variant;
    update();
  }

  void setExtraQuantity(ProductExtra extra, bool isIncrement) {
    int current = _extraQuantities[extra.id!] ?? 0;
    if (isIncrement) {
      if (current < 10) {
        _extraQuantities[extra.id!] = current + 1;
      } else {
        AppSnackbar.info('Extras', 'Máximo 10 unidades por extra');
      }
    } else {
      if (current > 0) {
        _extraQuantities[extra.id!] = current - 1;
      }
    }
    update();
  }

  void updateNotes(String value) {
    _notes = value;
    update();
  }

  Future<void> getPopularProductList() async {
    debugPrint("Fetching popular products...");
    try {
      Response response = await popularProductRepo.getPopularProductList();
      debugPrint("Popular products response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        _popularProductList = [];
        _popularProductList.addAll(Product.fromJson(response.body).products);
      } else {
        debugPrint("Failed to load popular products: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception loading popular products: $e");
    } finally {
      _isLoaded = true;
      update();
    }
  }

  void setQuantity(bool isIncrement) {
    if (isIncrement) {
      _quantity = checkQuantity(_quantity + 1);
    } else {
      _quantity = checkQuantity(_quantity - 1);
    }
    update();
  }

  int checkQuantity(int quantity) {
    if (quantity < 1) {
      AppSnackbar.info('Cantidad', 'La cantidad mínima es 1');
      return 1;
    } else if (quantity > 20) {
      AppSnackbar.info('Cantidad', 'No puedes agregar más de 20 unidades');
      return 20;
    } else {
      return quantity;
    }
  }

  void initProduct(ProductModel product, CartController cart) {
    _product = product;
    _quantity = 1;
    _cart = cart;
    _selectedVariant = null;
    _extraQuantities.clear();
    _notes = "";

    // Set default variant if any
    if (product.variants != null && product.variants!.isNotEmpty) {
      for (var variant in product.variants!) {
        if (variant.isDefault == true) {
          _selectedVariant = variant;
          break;
        }
      }
      _selectedVariant ??= product.variants!.first;
    }
  }

  void addItem(ProductModel product) {
    List<int> extrasList = [];
    _extraQuantities.forEach((id, qty) {
      for (int i = 0; i < qty; i++) {
        extrasList.add(id);
      }
    });

    _cart.addItem(
      product,
      _quantity,
      variantId: _selectedVariant?.id,
      extras: extrasList,
      notes: _notes,
      price: unitPrice,
      extrasPrice: extrasPrice,
    );
    _quantity = 1;
    _extraQuantities.clear();
    _notes = "";
    update();
  }

  int get totalItems {
    return _cart.totalItems;
  }

  List<CartModel> get getItems {
    return _cart.getItems;
  }
}
