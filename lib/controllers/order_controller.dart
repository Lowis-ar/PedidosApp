import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/data/repository/order_repo.dart';
import 'package:pedidosapp/models/order_model.dart';
import 'package:pedidosapp/models/cart_model.dart';
import 'package:pedidosapp/controllers/cart_controller.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';

class OrderController extends GetxController {
  final OrderRepo orderRepo;
  OrderController({required this.orderRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<OrderModel> _orderList = [];
  List<OrderModel> get orderList => _orderList;

  List<AddressModel> _addressList = [];
  List<AddressModel> get addressList => _addressList;

  AddressModel? _selectedAddress;
  AddressModel? get selectedAddress => _selectedAddress;

  String? _lastOtp;
  String? get lastOtp => _lastOtp;

  Future<bool> placeOrder({
    required List<CartModel> cartItems,
    required int addressId,
    String? orderNote,
    double? lat,
    double? lng,
  }) async {
    _isLoading = true;
    update();

    try {
      // Obtenemos dinámicamente la sucursal seleccionada actualmente
      int branchId = Get.find<BranchController>().branchId;

      Map<String, dynamic> body = {
        'branch_id': branchId,
        'address_id': addressId,
        'lat': lat,
        'lng': lng,
        'coupon_code': null,
        'use_loyalty_points': false,
        'notes': orderNote ?? '',
        'items': cartItems.map((item) {
          return {
            'product_id': item.product?.id ?? item.id,
            'variant_id': null,
            'quantity': item.quantity,
            'extras': [],
          };
        }).toList(),
      };

      Response response = await orderRepo.placeOrder(body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.body;
        _lastOtp = (data != null && data is Map) 
            ? (data['data']?['otp']?.toString() ?? data['otp']?.toString())
            : null;
        
        // Clear cart after successful order
        Get.find<CartController>().clearCartHistory();
        
        Get.snackbar(
          '¡Pedido realizado!',
          _lastOtp != null 
              ? 'Tu código de entrega es: $_lastOtp'
              : 'Tu pedido ha sido creado con éxito.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        );
        
        await getOrderList();
        return true;
      } else {
        _handleError(response, 'No se pudo realizar el pedido');
        return false;
      }
    } catch (e) {
      _showError('Error de conexión al realizar el pedido');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<double?> getShippingFee(double lat, double lng, int branchId) async {
    try {
      Response response = await orderRepo.getShippingFee(lat, lng, branchId);
      if (response.statusCode == 200) {
        if (response.body['fee'] != null) {
          return double.tryParse(response.body['fee'].toString());
        }
      }
    } catch (e) {
      debugPrint("Error getting shipping fee: $e");
    }
    return null;
  }

  Future<void> getOrderList() async {
    _isLoading = true;
    update();

    try {
      Response response = await orderRepo.getOrderList();
      if (response.statusCode == 200) {
        _orderList = [];
        final body = response.body;
        var orders = body['orders'] ?? body['data'];
        if (orders != null && orders is List) {
          for (var o in orders) {
            _orderList.add(OrderModel.fromJson(o));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading orders: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> cancelOrder(int orderId) async {
    _isLoading = true;
    update();

    try {
      Response response = await orderRepo.cancelOrder(orderId);
      if (response.statusCode == 200) {
        Get.snackbar(
          'Pedido cancelado',
          'El pedido ha sido cancelado exitosamente',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        await getOrderList();
      } else {
        _handleError(response, 'No se pudo cancelar el pedido');
      }
    } catch (e) {
      _showError('Error al cancelar el pedido');
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Address methods
  Future<void> getAddressList() async {
    try {
      Response response = await orderRepo.getAddressList();
      if (response.statusCode == 200) {
        _addressList = [];
        final body = response.body;
        var addresses = body['addresses'] ?? body['data'];
        if (addresses != null && addresses is List) {
          for (var a in addresses) {
            _addressList.add(AddressModel.fromJson(a));
          }
        }
        if (_addressList.isNotEmpty && _selectedAddress == null) {
          _selectedAddress = _addressList.first;
        }
        update();
      }
    } catch (e) {
      debugPrint("Error loading addresses: $e");
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.addAddress(address.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        await getAddressList();
        Get.snackbar('Éxito', 'Dirección agregada', 
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return true;
      } else {
        _handleError(response, 'No se pudo agregar la dirección');
        return false;
      }
    } catch (e) {
      _showError('Error al agregar la dirección');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> deleteAddress(int addressId) async {
    try {
      Response response = await orderRepo.deleteAddress(addressId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _addressList.removeWhere((a) => a.id == addressId);
        if (_selectedAddress?.id == addressId) {
          _selectedAddress = _addressList.isNotEmpty ? _addressList.first : null;
        }
        update();
      }
    } catch (e) {
      debugPrint("Error deleting address: $e");
    }
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    update();
  }

  void _handleError(Response response, String fallback) {
    String message = fallback;
    if (response.body != null && response.body is Map) {
      final body = response.body as Map<String, dynamic>;
      if (body['message'] != null) {
        message = body['message'];
      }
      if (body['errors'] != null && body['errors'] is Map) {
        final errors = body['errors'] as Map;
        List<String> errMsgs = [];
        errors.forEach((key, value) {
          if (value is List) {
            errMsgs.addAll(value.map((e) => e.toString()));
          } else {
            errMsgs.add(value.toString());
          }
        });
        if (errMsgs.isNotEmpty) {
          message = "$message: ${errMsgs.join(' | ')}";
        }
      }
    }
    _showError(message);
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
