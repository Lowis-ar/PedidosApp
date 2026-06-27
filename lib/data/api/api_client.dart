import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../utils/secure_storage_web.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/app_snackbar.dart';

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
  /// Cuando [handleError] es false, solo limpia el estado local sin redirigir
  /// (usado durante la validación de token en el arranque de la app).
  void _handleHttpError(Response response, {bool handleError = true}) async {
    if (isLoggingOut) return;

    if (response.statusCode == 401) {
      if (token.isEmpty) return; // Ya estaba deslogueado

      // Si handleError es false, el llamador maneja el 401 manualmente.
      // No redirigir al login ni mostrar snackbar — solo limpiar el token en memoria.
      if (!handleError) {
        token = '';
        return;
      }

      isLoggingOut = true;

      final secureStorage = SecureStorageWeb();
      final String? deliveryTokenStr = await secureStorage.read(
        key: AppConstants.DELIVERY_TOKEN,
      );
      final bool isDeliveryToken =
          deliveryTokenStr != null && deliveryTokenStr.isNotEmpty;

      // Limpiar TODOS los datos de sesión del almacenamiento seguro
      await secureStorage.delete(key: AppConstants.DELIVERY_TOKEN);
      await secureStorage.delete(key: AppConstants.TOKEN);
      await secureStorage.delete(key: 'token');
      await secureStorage.delete(key: 'user');
      await secureStorage.delete(key: 'user_type');
      token = '';

      AppSnackbar.error(
        'Sesión expirada',
        'Por favor vuelve a iniciar sesión',
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
    } else if ((response.statusCode == 500 || response.statusCode == 503) &&
        handleError) {
      AppSnackbar.error(
        'Error del servidor',
        'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
  }


  Future<Response> getData(String uri, {bool handleError = true}) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String cacheBustUri = uri.contains('?')
          ? '$uri&_t=$timestamp'
          : '$uri?_t=$timestamp';

      final Response response = await get(cacheBustUri, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('[ApiClient] GET error $uri: $e');
      }
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> postData(
    String uri,
    dynamic body, {
    bool handleError = true,
  }) async {
    try {
      final Map<String, String> headers = Map<String, String>.from(
        _mainHeaders,
      );
      if (body is FormData) {
        headers.remove('Content-Type');
      }
      final Response response = await post(uri, body, headers: headers);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('[ApiClient] POST error $uri: $e');
      }
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {
    bool handleError = true,
  }) async {
    try {
      final Map<String, String> headers = Map<String, String>.from(
        _mainHeaders,
      );
      if (body is FormData) {
        headers.remove('Content-Type');
      }
      final Response response = await put(uri, body, headers: headers);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('[ApiClient] PUT error $uri: $e');
      }
      return Response(statusCode: 1, statusText: e.toString());
    }
  }

  Future<Response> deleteData(String uri, {bool handleError = true}) async {
    try {
      final Response response = await delete(uri, headers: _mainHeaders);
      _handleHttpError(response, handleError: handleError);
      return response;
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('[ApiClient] DELETE error $uri: $e');
      }
      return Response(statusCode: 1, statusText: e.toString());
    }
  }
}
