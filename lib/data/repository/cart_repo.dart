import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/cart_model.dart';
import '../../controllers/auth_controller.dart';

class CartRepo {
  final _storage = GetStorage();

  String _getCartKey() {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.id;
      if (userId != null) {
        return 'cart-list-$userId';
      }
    } catch (e) {
      // Ignorar si no se puede obtener el authController
    }
    return 'cart-list-guest';
  }

  String _getTimeKey() {
    return '${_getCartKey()}-time';
  }

  void addToCartList(List<CartModel> cartList) {
    var time = DateTime.now().toString();
    var cart = [];
    cartList.forEach((element) {
      cart.add(jsonEncode(element.toJson()));
    });
    
    _storage.write(_getCartKey(), cart);
    _storage.write(_getTimeKey(), time);
  }

  List<CartModel> getCartList() {
    List<String>? carts = _storage.read<List<dynamic>>(_getCartKey())?.cast<String>();
    String? timeStr = _storage.read<String>(_getTimeKey());
    
    if (carts != null && timeStr != null) {
      DateTime time = DateTime.parse(timeStr);
      // Check if 1 hour has passed
      if (DateTime.now().difference(time).inHours >= 1) {
        clearCartHistory();
        return [];
      }
      
      List<CartModel> cartList = [];
      carts.forEach((element) {
        cartList.add(CartModel.fromJson(jsonDecode(element)));
      });
      return cartList;
    }
    return [];
  }

  void clearCartHistory() {
    _storage.remove(_getCartKey());
    _storage.remove(_getTimeKey());
  }
}