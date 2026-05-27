import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../utils/app_constants.dart';

class ApiClient extends GetConnect implements GetxService {
  late String token;
  final String appBaseUrl;
  final _storage = GetStorage();
  bool isLoggingOut = false;

  ApiClient({required this.appBaseUrl}) {
    baseUrl = appBaseUrl;
    timeout = const Duration(seconds: 30);
    token = '';
  }

  Map<String, String> get _mainHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  void updateToken(String newToken) {
    token = newToken;
  }

  /// Maneja respuestas con código 401 (token expirado) y 500 (error servidor).
  /// Redirige al login correcto según el tipo de token activo.
  void _handleHttpError(Response response, {bool handleError = true}) {
    if (isLoggingOut) return;

    if (response.statusCode == 401) {
      if (token.isEmpty) return; // Ya estaba deslogueado
      isLoggingOut = true;

      final bool isDeliveryToken =
          _storage.read<String>(AppConstants.DELIVERY_TOKEN) != null &&
          _storage.read<String>(AppConstants.DELIVERY_TOKEN)!.isNotEmpty;

      // Limpiar tokens
      _storage.remove(AppConstants.DELIVERY_TOKEN);
      _storage.remove(AppConstants.TOKEN);
      token = '';

      Get.snackbar(
        'Sesión expirada',
        'Por favor vuelve a iniciar sesión',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (isDeliveryToken) {
          Get.offAllNamed('/delivery-login');
        } else {
          Get.offAllNamed('/login');
        }
        isLoggingOut = false; // Reset para futuras sesiones
      });
    } else if ((response.statusCode == 500 || response.statusCode == 503) && handleError) {
      Get.snackbar(
        'Error del servidor',
        'Ocurrió un error inesperado. Intenta de nuevo.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<Response> getData(String uri, {bool handleError = true}) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String cacheBustUri = uri.contains('?') ? '$uri&_t=$timestamp' : '$uri?_t=$timestamp';
      
      final Response response = await get(cacheBustUri, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      debugPrint('[ApiClient] GET error $uri: $e');
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> postData(String uri, dynamic body, {bool handleError = true}) async {
    try {
      final Response response = await post(uri, body, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      debugPrint('[ApiClient] POST error $uri: $e');
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> putData(String uri, dynamic body, {bool handleError = true}) async {
    try {
      final Response response = await put(uri, body, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      debugPrint('[ApiClient] PUT error $uri: $e');
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> deleteData(String uri, {bool handleError = true}) async {
    try {
      final Response response = await delete(uri, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      debugPrint('[ApiClient] DELETE error $uri: $e');
      return Response(statusCode: 1, statusText: e.toString());
    }
  }
}
