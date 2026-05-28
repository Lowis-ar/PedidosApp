import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/models/product_model.dart';

import '../data/repository/cart_repo.dart';
import '../models/cart_model.dart';
import '../utils/colors.dart';

class CartController extends GetxController{
  final CartRepo cartRepo;
  CartController({required this.cartRepo});
  final Map<String, CartModel> _items = {};
  Map<String, CartModel> get items => _items;

  String _generateKey(ProductModel product, int? variantId, List<int>? extras) {
    String key = "${product.id}";
    if (variantId != null) key += "_$variantId";
    if (extras != null && extras.isNotEmpty) {
      var sortedExtras = List<int>.from(extras)..sort();
      key += "_${sortedExtras.join('-')}";
    }
    return key;
  }

  @override
  void onInit() {
    super.onInit();
    getCartData();
  }

  void getCartData() {
    setCart = cartRepo.getCartList();
  }

  set setCart(List<CartModel> items) {
    _items.clear();
    for (int i = 0; i < items.length; i++) {
      String key = _generateKey(items[i].product!, items[i].variantId, items[i].extras);
      _items.putIfAbsent(key, () => items[i]);
    }
    Future.microtask(() => update());
  }


  void addItem(
    ProductModel product,
    int quantity, {
    int? variantId,
    List<int>? extras,
    String? notes,
    double? price,
    double? extrasPrice,
  }) {
    var totalQuantity = 0;
    double finalPrice = price ?? product.price ?? 0.0;
    double finalExtrasPrice = extrasPrice ?? 0.0;

    String key = _generateKey(product, variantId, extras);

    if (_items.containsKey(key)) {
      _items.update(key, (value) {
        totalQuantity = value.quantity! + quantity;
        return CartModel(
          id: value.id,
          name: value.name,
          price: price ?? value.price,
          img: value.img,
          quantity: value.quantity! + quantity,
          isExist: true,
          time: DateTime.now().toString(),
          product: product,
          variantId: variantId ?? value.variantId,
          extras: extras ?? value.extras,
          notes: notes ?? value.notes,
          extrasPrice: extrasPrice ?? value.extrasPrice,
        );
      });

      if (totalQuantity <= 0) {
        _items.remove(key);
      }
    } else {
      if (quantity > 0) {
        _items.putIfAbsent(key, () {
          return CartModel(
            id: product.id,
            name: product.name,
            price: finalPrice,
            img: product.img,
            quantity: quantity,
            isExist: true,
            time: DateTime.now().toString(),
            product: product,
            variantId: variantId,
            extras: extras,
            notes: notes,
            extrasPrice: finalExtrasPrice,
          );
        });
      } else {
        Get.snackbar(
          "Cantidad",
          "Debes agregar al menos un producto",
          backgroundColor: AppColors.mainColor,
          colorText: Colors.white,
        );
      }
    }
    cartRepo.addToCartList(getItems);
    update();
  }

  bool existInCart(ProductModel product){
    bool exists = false;
    _items.forEach((key, value) {
      if (value.product!.id == product.id) {
        exists = true;
      }
    });
    return exists;
  }

  int getQuantity(ProductModel product){
    var quantity = 0;
    _items.forEach((key, value) {
      if (value.product!.id == product.id) {
        quantity += value.quantity!;
      }
    });
    return quantity;
  }

  int get totalItems{
    var totalQuantity = 0;
    _items.forEach((key, value) {
      totalQuantity += value.quantity!;
    });
    return totalQuantity;
  }


  List<CartModel> get getItems{
   return _items.entries.map((e){
      return e.value;
    }).toList();
  }

  /// Removes all cart items whose product ID is in [productIds].
  /// Returns the list of removed item names for display purposes.
  List<String> removeItemsByProductIds(List<int> productIds) {
    final Set<int> toRemove = productIds.toSet();
    final List<String> removedNames = [];

    _items.removeWhere((key, value) {
      final id = value.product?.id;
      if (id != null && toRemove.contains(id)) {
        removedNames.add(value.name ?? 'Producto desconocido');
        return true;
      }
      return false;
    });

    cartRepo.addToCartList(getItems);
    update();
    return removedNames;
  }

  void clear() {
    _items.clear();
    update();
  }

  void clearCartHistory() {
    cartRepo.clearCartHistory();
    clear();
  }
}