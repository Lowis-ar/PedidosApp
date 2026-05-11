import 'package:get/get.dart';
import '../data/repository/delivery_order_repo.dart';
import '../models/delivery_order_model.dart';
import 'package:flutter/material.dart';

class DeliveryOrderController extends GetxController {
  final DeliveryOrderRepo orderRepo;
  DeliveryOrderController({required this.orderRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DeliveryOrderModel> _availableOrders = [];
  List<DeliveryOrderModel> get availableOrders => _availableOrders;

  List<DeliveryOrderModel> _historyOrders = [];
  List<DeliveryOrderModel> get historyOrders => _historyOrders;
  
  DeliveryOrderModel? _activeOrder;
  DeliveryOrderModel? get activeOrder => _activeOrder;

  double get dailyEarnings {
    return _historyOrders
        .where((o) => o.orderStatus == 'delivered')
        .fold(0.0, (sum, o) => sum + (o.deliveryFee ?? 0.0));
  }

  Future<void> getOrders() async {
    _isLoading = true;
    update();
    try {
      // 1. Obtener Pedidos Disponibles
      Response responseAvailable = await orderRepo.getAvailableOrders();
      debugPrint("API Available Orders Raw: ${responseAvailable.body}");
      
      if (responseAvailable.statusCode == 200) {
        final body = responseAvailable.body;
        // Acceder a la lista de pedidos dentro de data -> orders o similar
        // Basado en tu estructura de Laravel, suele ser body['data']
        var rawData = body['data'];
        if (rawData is List) {
          _availableOrders = rawData.map((o) => DeliveryOrderModel.fromJson(o)).toList();
        } else if (body is List) {
           _availableOrders = body.map((o) => DeliveryOrderModel.fromJson(o)).toList();
        }
      }

      await getHistory();

      // 2. Identificar Pedido Activo
      _activeOrder = null;
      // Buscamos en disponibles por si alguno ya tiene estado de progreso
      for (var o in _availableOrders) {
        if (o.orderStatus == 'accepted' || o.orderStatus == 'on_way' || o.orderStatus == 'picked_up') {
          _activeOrder = o;
          break;
        }
      }
      // Buscamos en el historial (donde suelen estar los que ya no están 'disponibles' para otros)
      if (_activeOrder == null) {
        for (var o in _historyOrders) {
          if (o.orderStatus == 'accepted' || o.orderStatus == 'on_way' || o.orderStatus == 'picked_up') {
            _activeOrder = o;
            break;
          }
        }
      }

    } catch (e) {
      debugPrint("Error en DeliveryOrderController.getOrders: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  double _totalEarnings = 0.0;
  double get totalEarnings => _totalEarnings;

  double _todayEarnings = 0.0;
  double get todayEarnings => _todayEarnings;

  Future<void> getHistory() async {
    try {
      Response response = await orderRepo.getOrderHistory();
      debugPrint("API History Raw: ${response.body}");
      
      if (response.statusCode == 200) {
        final body = response.body;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          
          _totalEarnings = data['total_earnings'] != null ? double.parse(data['total_earnings'].toString()) : 0.0;
          _todayEarnings = data['today_earnings'] != null ? double.parse(data['today_earnings'].toString()) : 0.0;
          
          var rawOrders = data['orders'];
          if (rawOrders is List) {
            _historyOrders = rawOrders.map((o) => DeliveryOrderModel.fromJson(o)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Error en getHistory: $e");
    }
    update();
  }

  Future<void> acceptOrder(int orderId) async {
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.acceptOrder(orderId);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Pedido aceptado', backgroundColor: Colors.green, colorText: Colors.white);
        await getOrders();
      } else if (response.statusCode == 403) {
        Get.snackbar('Error', 'No puedes aceptar este pedido', backgroundColor: Colors.orange);
      } else {
        Get.snackbar('Error', 'No se pudo aceptar el pedido');
      }
    } catch (e) {} finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> markAsOnWay(int orderId) async {
    _isLoading = true;
    update();
    try {
      // Petición PUT con {"status": "on_way"}
      Response response = await orderRepo.updateOrderStatus(orderId, 'on_way');
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Pedido en camino', backgroundColor: Colors.blue, colorText: Colors.white);
        await getOrders();
      }
    } catch (e) {
      debugPrint("Error in markAsOnWay: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> verifyOtp(int orderId, String otp) async {
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.verifyOtp(orderId, otp);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Pedido entregado correctamente', backgroundColor: Colors.green, colorText: Colors.white);
        _activeOrder = null;
        await getOrders();
        return true;
      } else if (response.statusCode == 422) {
        Get.snackbar('Error', 'Código incorrecto', backgroundColor: Colors.redAccent, colorText: Colors.white);
        return false;
      } else {
        Get.snackbar('Error', 'PIN de entrega inválido', backgroundColor: Colors.redAccent, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  void showNewOrderDialog(Map<String, dynamic> data) {
    // Logic to show dialog when FCM message arrives
    Get.dialog(
      AlertDialog(
        title: const Text("¡Nuevo Pedido!"),
        content: Text("Tienes un nuevo pedido disponible #${data['order_id']}"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("IGNORAR")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              acceptOrder(int.parse(data['order_id'].toString()));
            },
            child: const Text("ACEPTAR"),
          ),
        ],
      ),
    );
  }
}
