import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/repository/delivery_order_repo.dart';
import '../models/delivery_order_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryOrderController extends GetxController {
  final DeliveryOrderRepo orderRepo;
  DeliveryOrderController({required this.orderRepo});

  final _storage = GetStorage();
  Timer? _pollingTimer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DeliveryOrderModel> _availableOrders = [];
  List<DeliveryOrderModel> get availableOrders => _availableOrders.where((o) => o.orderStatus == 'ready_to_go' || o.orderStatus == 'pending').toList();

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

      final results = await Future.wait([
        orderRepo.getAvailableOrders(),
        orderRepo.getActiveOrders(),
        orderRepo.getOrderHistory(),
      ]);

      Response respAvail = results[0];
      if (respAvail.statusCode == 200) {
        _availableOrders = _parseOrderList(respAvail.body);
      } else if (respAvail.statusCode == 403) {
        _availableOrders = [];
        if (showLoading) {
          final msg = respAvail.body is Map
              ? (respAvail.body['message'] ?? 'No tienes disponibilidad activa')
              : 'No tienes disponibilidad activa';
          Get.snackbar('Sin disponibilidad', msg.toString(),
              backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        }
      }

      Response respActive = results[1];
      if (respActive.statusCode == 200) {
        _activeOrdersList = _parseOrderList(respActive.body);
      }

      Response respHistory = results[2];
      if (respHistory.statusCode == 200) {
        final body = respHistory.body;
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

      _updateActiveOrderState();
      debugPrint("=== FIN CARGA DE PEDIDOS === disponibles=${_availableOrders.length} activos=${_activeOrdersList.length}");
    } catch (e, stack) {
      debugPrint("Error en getOrders: $e\n$stack");
      if (showLoading) {
        Get.snackbar('Error de conexión', 'No se pudo cargar los pedidos. Verifica tu conexión.',
            backgroundColor: Colors.red.shade600, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
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
    if (_activeOrdersList.isNotEmpty) {
      _activeOrder = _activeOrdersList.firstWhereOrNull(
        (o) => o.orderStatus == 'assigned' || o.orderStatus == 'on_way' || o.orderStatus == 'picked_up' || o.orderStatus == 'accepted'
      ) ?? _activeOrdersList.first;
    } else {
      _activeOrder = null;
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
    final order = _availableOrders.firstWhereOrNull((o) => o.id == orderId);
    if (order != null && order.restaurant?.lat != null && order.restaurant?.lng != null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          Get.snackbar('GPS Desactivado', 'Activa la ubicación para validar la distancia.', backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            Get.snackbar('Permiso denegado', 'Debes dar permiso de ubicación.', backgroundColor: Colors.orange, colorText: Colors.white);
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          Get.snackbar('Permiso', 'Permisos de ubicación denegados permanentemente.', backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          double.parse(order.restaurant!.lat!),
          double.parse(order.restaurant!.lng!)
        );

        if (distanceInMeters > 1000) { // 1 km threshold
          Get.snackbar('Lejos del restaurante', 'Debes estar cerca del restaurante para aceptar.', backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
      } catch (e) {
        debugPrint("Error GPS: $e");
        Get.snackbar('Error', 'No se pudo validar la ubicación.', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    }

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
