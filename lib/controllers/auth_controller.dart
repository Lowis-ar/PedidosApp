import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/api/api_client.dart';
import '../data/repository/auth_repo.dart';
import '../models/user_model.dart';
import 'cart_controller.dart';
import 'popular_product_controller.dart';
import 'recommended_product_controller.dart';

class AuthController extends GetxController {
  final AuthRepo authRepo;
  AuthController({required this.authRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _token = '';
  String get token => _token;

  UserModel? _user;
  UserModel? get user => _user;

  final _storage = GetStorage();

  bool get isLoggedIn => _token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  void _loadToken() {
    final saved = _storage.read<String>('token');
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      Get.find<ApiClient>().updateToken(_token);
      final userData = _storage.read('user');
      if (userData != null) {
        _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
    }
  }

  void _saveSession(String token, UserModel user) {
    _token = token;
    _user = user;
    _storage.write('token', token);
    _storage.write('user', user.toJson());
    Get.find<ApiClient>().updateToken(token);

    // Sincronizar productos y carrito tras login exitoso
    if (Get.isRegistered<PopularProductController>()) {
      Get.find<PopularProductController>().getPopularProductList();
    }
    if (Get.isRegistered<RecommendedProductController>()) {
      Get.find<RecommendedProductController>().getRecommendedProductList();
    }
    Get.find<CartController>().getCartData();
    update();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    update();

    try {
      Response response = await authRepo.login(email, password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body != null) {
          // Búsqueda flexible de token y usuario
          final String? token = body['token'] ?? body['access_token'] ?? body['data']?['token'];
          final dynamic userJson = body['user'] ?? body['data']?['user'] ?? body['data'];

          if (token != null && userJson != null) {
            final user = UserModel.fromJson(userJson is Map<String, dynamic> ? userJson : Map<String, dynamic>.from(userJson));
            _saveSession(token, user);
          } else {
            _showError('El servidor no envió datos de usuario o token válidos');
          }
        }
      } else {
        _handleApiError(response, 'Error al iniciar sesión');
      }
    } catch (e) {
      _showError('Ocurrió un error inesperado. Revisa tu conexión.');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> register(String name, String phone, String email, String password) async {
    _isLoading = true;
    update();

    try {
      Response response = await authRepo.register(name, phone, email, password);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.body;
        if (body != null) {
          final String? token = body['token'] ?? body['access_token'] ?? body['data']?['token'];
          final dynamic userJson = body['user'] ?? body['data']?['user'] ?? body['data'];

          if (token != null && userJson != null) {
            final user = UserModel.fromJson(userJson is Map<String, dynamic> ? userJson : Map<String, dynamic>.from(userJson));
            _saveSession(token, user);
          } else {
            _showError('Registro exitoso, pero hubo un problema al obtener tus datos.');
          }
        }
      } else {
        _handleApiError(response, 'Error al registrarse');
      }
    } catch (e) {
      _showError('No se pudo completar el registro. Verifica los datos.');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _handleApiError(Response response, String fallback) {
    String message = fallback;
    if (response.body != null && response.body is Map) {
      final body = response.body as Map<String, dynamic>;
      if (body['message'] != null) {
        message = body['message'];
      } else if (body['errors'] != null) {
        var errors = body['errors'];
        if (errors is Map) {
          message = errors.values.first[0].toString();
        } else if (errors is List) {
          message = errors[0].toString();
        }
      }
    } else if (response.statusText != null) {
      message = response.statusText!;
    }
    _showError(message);
  }

  void _showError(String message) {
    Get.snackbar(
      'Aviso',
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void logout() {
    _token = '';
    _user = null;
    _storage.remove('token');
    _storage.remove('user');
    Get.find<ApiClient>().updateToken('');
    Get.find<CartController>().clear();
    Get.find<CartController>().getCartData();
    update();
  }
}