import 'dart:async';
import 'package:get/get.dart';

import '../data/repository/delivery_order_repo.dart';
import '../models/delivery_order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'delivery_auth_controller.dart';

class DeliveryOrderController extends GetxController {
  final DeliveryOrderRepo orderRepo;
  DeliveryOrderController({required this.orderRepo});

  Timer? _pollingTimer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  bool _availableOrdersError = false;
  bool get availableOrdersError => _availableOrdersError;

  bool _activeOrdersError = false;
  bool get activeOrdersError => _activeOrdersError;

  bool _historyError = false;
  bool get historyError => _historyError;

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
      if (Get.isRegistered<DeliveryAuthController>() && Get.find<DeliveryAuthController>().isLoggedIn) {
        getOrders(showLoading: false);
      } else {
        stopPolling();
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<Response> _safeRequest(Future<Response> call) async {
    try {
      return await call.timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("[safeRequest] Error en petición: $e");
      return const Response(statusCode: 503, statusText: "Service Unavailable");
    }
  }

  Future<void> getOrders({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    // Siempre restablecemos los flags de error para permitir un intento limpio en reintentos
    _availableOrdersError = false;
    _activeOrdersError = false;
    _historyError = false;
    _hasError = false;
    update();

    final List<int> oldAvailableIds = _availableOrders.map((o) => o.id ?? 0).toList();
    final List<int> oldActiveIds = _activeOrdersList.map((o) => o.id ?? 0).toList();

    try {
      debugPrint("=== INICIO CARGA DE PEDIDOS ===");

      final results = await Future.wait([
        _safeRequest(orderRepo.getAvailableOrders(handleError: showLoading)),
        _safeRequest(orderRepo.getActiveOrders(handleError: showLoading)),
        // El historial siempre se pide silenciosamente: su error 500 se maneja internamente
        _safeRequest(orderRepo.getOrderHistory(handleError: false)),
      ]);

      Response respAvail = results[0];
      Response respActive = results[1];
      Response respHistory = results[2];

      // Procesar Pedidos Disponibles
      if (respAvail.statusCode == 200) {
        _availableOrders = _parseOrderList(respAvail.body);
        _availableOrdersError = false;
      } else if (respAvail.statusCode == 403) {
        _availableOrders = [];
        _availableOrdersError = false; // 403 es un estado de negocio válido (sin disponibilidad)
        if (showLoading) {
          final msg = respAvail.body is Map
              ? (respAvail.body['message'] ?? 'No tienes disponibilidad activa')
              : 'No tienes disponibilidad activa';
          Get.snackbar('Sin disponibilidad', msg.toString(),
              backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        _availableOrdersError = true;
      }

      // Procesar Pedidos Activos
      if (respActive.statusCode == 200) {
        _activeOrdersList = _parseOrderList(respActive.body);
        _activeOrdersError = false;
      } else {
        _activeOrdersError = true;
      }

      // Procesar Historial y Ganancias
      if (respHistory.statusCode == 200) {
        final body = respHistory.body;
        bool historyParsed = false;
        
        // Estructura 1: { success:true, data: { total_earnings, today_earnings, orders:[] } }
        if (body is Map && body['success'] == true && body['data'] is Map) {
          final data = body['data'] as Map;
          _totalEarnings = data['total_earnings'] != null ? double.tryParse(data['total_earnings'].toString()) ?? 0.0 : 0.0;
          _todayEarnings = data['today_earnings'] != null ? double.tryParse(data['today_earnings'].toString()) ?? 0.0 : 0.0;
          var rawOrders = data['orders'];
          if (rawOrders is List) {
            _historyOrders = rawOrders.map((o) => DeliveryOrderModel.fromJson(o)).toList();
          }
          historyParsed = true;
        }
        // Estructura 2: { success:true, data: [] } — lista plana
        else if (body is Map && body['data'] is List) {
          final rawOrders = body['data'] as List;
          _historyOrders = rawOrders.map((o) => DeliveryOrderModel.fromJson(o)).toList();
          historyParsed = true;
        }
        // Estructura 3: lista plana directa
        else if (body is List) {
          _historyOrders = (body as List).map((o) => DeliveryOrderModel.fromJson(o)).toList();
          historyParsed = true;
        }
        
        _historyError = !historyParsed;
        if (!historyParsed) {
          debugPrint('[History] Formato desconocido: ${body.runtimeType} keys=${body is Map ? body.keys.toList() : 'list'}');
        }
      } else {
        _historyError = true;
        debugPrint('[History] Error HTTP ${respHistory.statusCode} — historial no disponible (no crítico)');
      }

      // Si cualquiera de las dos consultas principales falla por error del servidor/red
      if (_availableOrdersError || _activeOrdersError) {
        _hasError = true;
      }

      _updateActiveOrderState();
      
      // Feedback visual/háptico sutil e inteligente para actualización en segundo plano
      if (!showLoading) {
        final List<int> newAvailableIds = _availableOrders.map((o) => o.id ?? 0).toList();
        final List<int> newActiveIds = _activeOrdersList.map((o) => o.id ?? 0).toList();

        bool availableChanged = newAvailableIds.length != oldAvailableIds.length ||
            !newAvailableIds.every((id) => oldAvailableIds.contains(id));
        bool activeChanged = newActiveIds.length != oldActiveIds.length ||
            !newActiveIds.every((id) => oldActiveIds.contains(id));
        bool listsChanged = availableChanged || activeChanged;

        if (!_availableOrdersError && !_activeOrdersError) {
          if (listsChanged) {
            // Vibración media si entraron pedidos nuevos o cambiaron de estado
            HapticFeedback.mediumImpact();
          } else {
            // Click muy sutil si se completó la recarga periódica silenciosa sin cambios
            HapticFeedback.selectionClick();
          }
        }
      }

      debugPrint("=== FIN CARGA DE PEDIDOS === dispCount=${_availableOrders.length} actCount=${_activeOrdersList.length} availErr=$_availableOrdersError actErr=$_activeOrdersError histErr=$_historyError");
    } catch (e, stack) {
      debugPrint("Error en getOrders: $e\n$stack");
      _availableOrdersError = true;
      _activeOrdersError = true;
      _historyError = true;
      _hasError = true;
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
      // handleError:false para suprimir el snackbar global del 500 del backend
      Response response = await orderRepo.getOrderHistory(handleError: false);
      if (response.statusCode == 200) {
        final body = response.body;
        bool historyParsed = false;
        
        if (body is Map && body['success'] == true && body['data'] is Map) {
          final data = body['data'] as Map;
          _totalEarnings = data['total_earnings'] != null ? double.tryParse(data['total_earnings'].toString()) ?? 0.0 : 0.0;
          _todayEarnings = data['today_earnings'] != null ? double.tryParse(data['today_earnings'].toString()) ?? 0.0 : 0.0;
          var rawOrders = data['orders'];
          if (rawOrders is List) {
            _historyOrders = rawOrders.map((o) => DeliveryOrderModel.fromJson(o)).toList();
          }
          historyParsed = true;
        } else if (body is Map && body['data'] is List) {
          _historyOrders = (body['data'] as List).map((o) => DeliveryOrderModel.fromJson(o)).toList();
          historyParsed = true;
        } else if (body is List) {
          _historyOrders = (body as List).map((o) => DeliveryOrderModel.fromJson(o)).toList();
          historyParsed = true;
        }
        
        _historyError = !historyParsed;
      } else {
        _historyError = true;
        debugPrint('[getHistory] HTTP ${response.statusCode} — historial no disponible en el servidor');
      }
    } catch (e) {
      debugPrint("Error en getHistory: $e");
      _historyError = true;
    }
    update();
  }

  Future<void> acceptOrder(int orderId) async {
    // ─── 1. Verificar límite de 3 pedidos activos ──────────────────────────
    if (_activeOrdersList.length >= 3) {
      Get.snackbar(
        'Límite alcanzado',
        'Ya tienes 3 pedidos en curso. Completa uno antes de aceptar otro.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // ─── 2. Validación de distancia GPS (informativa, no bloqueante) ───────
    final order = _availableOrders.firstWhereOrNull((o) => o.id == orderId);
    if (order != null && order.restaurant?.lat != null && order.restaurant?.lng != null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
                locationSettings:
                    const LocationSettings(accuracy: LocationAccuracy.high));
            double distanceInMeters = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              double.parse(order.restaurant!.lat!),
              double.parse(order.restaurant!.lng!),
            );
            // Aviso informativo si está muy lejos (>5 km), pero no bloquea
            if (distanceInMeters > 5000) {
              Get.snackbar(
                'Aviso de distancia',
                'Estás a ${(distanceInMeters / 1000).toStringAsFixed(1)} km del restaurante.',
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Error GPS (no crítico): $e");
        // No bloqueamos si el GPS falla
      }
    }

    // ─── 3. Enviar solicitud de aceptación ───────────────────────────────
    _isLoading = true;
    update();
    try {
      Response response = await orderRepo.acceptOrder(orderId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('¡Pedido aceptado!', 'El pedido #$orderId fue aceptado exitosamente.',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
        await getOrders();
      } else {
        // Extraer el mensaje real del servidor
        String serverMessage = 'No se pudo aceptar el pedido.';
        if (response.body != null && response.body is Map) {
          final body = response.body as Map;
          serverMessage = body['message']?.toString() ??
              body['error']?.toString() ??
              serverMessage;
          // Si hay errores de validación con detalle
          if (body['errors'] != null && body['errors'] is Map) {
            final errors = body['errors'] as Map;
            List<String> msgs = [];
            errors.forEach((k, v) {
              if (v is List) msgs.addAll(v.map((e) => e.toString()));
              else msgs.add(v.toString());
            });
            if (msgs.isNotEmpty) serverMessage = msgs.join(' | ');
          }
        } else if (response.body is String && (response.body as String).isNotEmpty) {
          serverMessage = response.body as String;
        }
        debugPrint('[acceptOrder] Error ${response.statusCode}: $serverMessage');
        Get.snackbar(
          'No se pudo aceptar',
          serverMessage,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint('Error en acceptOrder: $e');
      Get.snackbar('Error de conexión', 'No se pudo conectar con el servidor.',
          backgroundColor: Colors.red.shade600, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
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
