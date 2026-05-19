import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/repository/delivery_order_repo.dart';
import '../models/delivery_order_model.dart';
import 'package:flutter/material.dart';

class DeliveryOrderController extends GetxController {
  final DeliveryOrderRepo orderRepo;
  DeliveryOrderController({required this.orderRepo});

  final _storage = GetStorage();
  static const String _activeOrderIdKey = 'delivery_active_order_id';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DeliveryOrderModel> _availableOrders = [];
  List<DeliveryOrderModel> get availableOrders => _availableOrders;

  List<DeliveryOrderModel> _historyOrders = [];
  List<DeliveryOrderModel> get historyOrders => _historyOrders;

  List<DeliveryOrderModel> _activeOrdersList = [];
  List<DeliveryOrderModel> get activeOrdersList => _activeOrdersList;
  
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
      debugPrint("=== DELIVERY getOrders ===");
      
      if (responseAvailable.statusCode == 200) {
        final bodyRaw = responseAvailable.body;
        _availableOrders = _parseOrderList(bodyRaw);
      }

      // 2. Obtener Pedidos en Curso (Active/Running)
      Response responseActive = await orderRepo.getActiveOrders();
      if (responseActive.statusCode == 200) {
        _activeOrdersList = _parseOrderList(responseActive.body);
      }

      await getHistory();

      // 4. Identificar el Pedido Activo principal para la UI destacada
      _updateActiveOrderState();

    } catch (e) {
      debugPrint("ERROR en DeliveryOrderController.getOrders: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  List<DeliveryOrderModel> _parseOrderList(dynamic body) {
    try {
      List<dynamic>? rawOrders;
      if (body is Map) {
        rawOrders = body['data']?['orders'] ?? body['data'] ?? body['orders'];
      } else if (body is List) {
        rawOrders = body;
      }
      
      if (rawOrders != null) {
        return rawOrders.map((o) => DeliveryOrderModel.fromJson(Map<String, dynamic>.from(o))).toList();
      }
    } catch (e) {
      debugPrint("Error parsing order list: $e");
    }
    return [];
  }

  void _updateActiveOrderState() {
    DeliveryOrderModel? foundActive;
    
    // Prioridad 1: Lista de activos del endpoint oficial
    if (_activeOrdersList.isNotEmpty) {
      foundActive = _activeOrdersList.first;
    }

    // Prioridad 2: ID guardado localmente
    if (foundActive == null) {
      final storedActiveId = _storage.read<int>(_activeOrderIdKey);
      if (storedActiveId != null) {
        foundActive = [..._availableOrders, ..._historyOrders].firstWhereOrNull((o) => o.id == storedActiveId);
      }
    }

    // Aplicar lógica Sticky
    if (foundActive != null) {
      _activeOrder = foundActive;
      _storage.write(_activeOrderIdKey, _activeOrder!.id);
    } else if (_activeOrder != null) {
      bool isAlreadyDelivered = _historyOrders.any((o) => o.id == _activeOrder!.id && o.orderStatus == 'delivered');
      if (isAlreadyDelivered) {
        _activeOrder = null;
        _storage.remove(_activeOrderIdKey);
      }
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
        // Parsear la respuesta para guardar el pedido como activo
        final body = response.body;
        if (body is Map && body['data'] is Map && body['data']['order'] is Map) {
          _activeOrder = DeliveryOrderModel.fromJson(body['data']['order']);
          _storage.write(_activeOrderIdKey, orderId);
        }
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
        _storage.remove(_activeOrderIdKey);
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
