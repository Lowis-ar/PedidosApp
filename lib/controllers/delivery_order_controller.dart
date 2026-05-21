import 'dart:async';
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
  Timer? _pollingTimer;

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

  double _totalEarnings = 0.0;
  double get totalEarnings => _totalEarnings;

  double _todayEarnings = 0.0;
  double get todayEarnings => _todayEarnings;

  @override
  void onInit() {
    super.onInit();
    startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getOrders(showLoading: false);
    });
  }

  Future<void> getOrders({bool showLoading = true}) async {
    if (showLoading) _isLoading = true;
    update();
    try {
      debugPrint("=== INICIO CARGA DE PEDIDOS ===");

      // 1. Pedidos Disponibles (status: ready_to_go)
      Response respAvail = await orderRepo.getAvailableOrders();
      debugPrint("[Disponibles] status=${respAvail.statusCode} body=${respAvail.body}");
      if (respAvail.statusCode == 200) {
        _availableOrders = _parseOrderList(respAvail.body);
        debugPrint("[Disponibles] parseados: ${_availableOrders.length}");
      } else if (respAvail.statusCode == 403) {
        _availableOrders = [];
        // Solo mostrar snackbar si no viene del polling silencioso
        if (showLoading) {
          final msg = respAvail.body is Map
              ? (respAvail.body['message'] ?? 'No tienes disponibilidad activa')
              : 'No tienes disponibilidad activa';
          Get.snackbar(
            'Sin disponibilidad',
            msg.toString(),
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      // 2. Pedidos Activos (status: assigned o on_way)
      Response respActive = await orderRepo.getActiveOrders();
      debugPrint("[Activos] status=${respActive.statusCode} body=${respActive.body}");
      if (respActive.statusCode == 200) {
        _activeOrdersList = _parseOrderList(respActive.body);
        debugPrint("[Activos] parseados: ${_activeOrdersList.length}");
      } else {
        debugPrint("[Activos] ERROR status=${respActive.statusCode}");
      }

      await getHistory();

      // 3. Sincronizar Pedido Activo Principal (Persistent/Sticky)
      _updateActiveOrderState();

      debugPrint("=== FIN CARGA DE PEDIDOS === disponibles=${_availableOrders.length} activos=${_activeOrdersList.length}");

    } catch (e, stack) {
      debugPrint("Error en getOrders: $e\n$stack");
      if (showLoading) {
        Get.snackbar(
          'Error de conexión',
          'No se pudo cargar los pedidos. Verifica tu conexión.',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
      debugPrint("[Parse] rawOrders=${rawOrders?.length} keys=${body is Map ? body.keys.toList() : 'list'}");
      if (rawOrders != null) {
        return rawOrders.map((o) => DeliveryOrderModel.fromJson(Map<String, dynamic>.from(o))).toList();
      }
    } catch (e, stack) {
      debugPrint("Error parsing order list: $e\n$stack");
    }
    return [];
  }

  void _updateActiveOrderState() {
    DeliveryOrderModel? found;
    
    // Prioridad 1: Endpoint de Activos
    if (_activeOrdersList.isNotEmpty) {
      found = _activeOrdersList.firstWhereOrNull(
        (o) => o.orderStatus == 'assigned' || o.orderStatus == 'on_way' || o.orderStatus == 'picked_up' || o.orderStatus == 'accepted'
      ) ?? _activeOrdersList.first;
    }

    // Prioridad 2: Buscar en Disponibles por estado
    found ??= _availableOrders.firstWhereOrNull((o) =>
        o.orderStatus == 'assigned' || o.orderStatus == 'on_way' || o.orderStatus == 'picked_up' || o.orderStatus == 'accepted');

    // Prioridad 3: Memoria Local (Persistence)
    final storedId = _storage.read<int>(_activeOrderIdKey);
    if (found == null && storedId != null) {
      found = [..._availableOrders, ..._activeOrdersList, ..._historyOrders].firstWhereOrNull((o) => o.id == storedId);
    }

    if (found != null) {
      _activeOrder = found;
      _storage.write(_activeOrderIdKey, found.id);
      
      // Asegurar que esté en la lista de 'En Curso' para la pestaña
      if (!_activeOrdersList.any((o) => o.id == found!.id)) {
        _activeOrdersList.insert(0, found);
      }
    } else {
      // Verificación de borrado: Solo si el historial o la ausencia total confirma que ya no existe
      if (_activeOrder != null) {
        final all = [..._availableOrders, ..._activeOrdersList, ..._historyOrders];
        bool stillExists = all.any((o) => o.id == storedId && o.orderStatus != 'delivered' && o.orderStatus != 'canceled' && o.orderStatus != 'cancelled');
        
        if (!stillExists) {
          _activeOrder = null;
          _storage.remove(_activeOrderIdKey);
        }
      }
    }
  }

  Future<void> getHistory() async {
    try {
      Response response = await orderRepo.getOrderHistory();
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
        _storage.write(_activeOrderIdKey, orderId);
        await getOrders();
      } else if (response.statusCode == 403) {
        Get.snackbar('Error', 'No puedes aceptar este pedido', backgroundColor: Colors.orange);
      } else {
        Get.snackbar('Error', 'No se pudo aceptar el pedido');
      }
    } catch (e) {
      debugPrint('Error en acceptOrder: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Salir a entregar (PUT /delivery/orders/{id}/status)
  Future<void> markAsOnWay(int orderId) async {
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.updateOrderStatus(orderId, 'on_way');
      if (response.statusCode == 200) {
        Get.snackbar(
          '¡En Camino!',
          'El estado ha cambiado a: En camino',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        await getOrders();
      } else if (response.statusCode == 422) {
        final msg = response.body is Map
            ? (response.body['message'] ?? 'Estado inválido para este pedido')
            : 'Estado inválido para este pedido';
        Get.snackbar('Error de estado', msg.toString(),
            backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        Get.snackbar(
          'Error del servidor',
          'No se pudo actualizar el estado. Intenta de nuevo.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error in markAsOnWay: $e");
      Get.snackbar(
        'Error de conexión',
        'No se pudo conectar con el servidor.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Confirmar entrega con OTP (POST /delivery/orders/{id}/verify-otp)
  // Retorna null en éxito, o el mensaje de error como String para mostrarlo inline.
  Future<String?> verifyDeliveryOtp(int orderId, String otpCode) async {
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.verifyOtp(orderId, otpCode);
      if (response.statusCode == 200) {
        Get.snackbar(
          '¡Pedido Entregado!',
          'La entrega fue confirmada correctamente.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        _activeOrder = null;
        _storage.remove(_activeOrderIdKey);
        await getOrders();
        return null; // éxito
      } else if (response.statusCode == 422) {
        final msg = response.body is Map
            ? (response.body['message'] ?? 'El código proporcionado por el cliente es inválido.')
            : 'El código proporcionado por el cliente es inválido.';
        return msg.toString(); // error inline
      } else if (response.statusCode == 403) {
        return 'No tienes permiso para actualizar este pedido.';
      } else {
        return 'Error del servidor. Intenta de nuevo.';
      }
    } catch (e) {
      return 'Error de conexión. Verifica tu red.';
    } finally {
      _isLoading = false;
      update();
    }
  }

  void showNewOrderDialog(Map<String, dynamic> data) {
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
