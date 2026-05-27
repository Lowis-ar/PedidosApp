import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/api/api_client.dart';
import '../data/repository/auth_repo.dart';
import 'package:pedidosapp/models/user_model.dart';
import 'package:pedidosapp/models/deliveryman_model.dart';
import 'package:pedidosapp/utils/app_constants.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';

import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/helper/dependencies.dart' as dep;

class AuthController extends GetxController {
  final AuthRepo authRepo;
  AuthController({required this.authRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _token = '';
  String get token => _token;

  UserModel? _user;
  UserModel? get user => _user;

  String _userType = 'customer'; // 'customer' or 'delivery'
  String get userType => _userType;

  final _storage = GetStorage();

  bool get isLoggedIn => _token.isNotEmpty;

  bool get isDelivery => _userType == 'delivery' || _user?.role == 'delivery' || _user?.role == 'deliveryman';

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
      _userType = _storage.read<String>('user_type') ?? 'customer';
      final userData = _storage.read('user');
      if (userData != null) {
        _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
    }
  }

  void setUserType(String type) {
    _userType = type;
    update();
  }

  void _saveSession(String token, UserModel user, String type, {Map<String, dynamic>? rawJson}) {
    _token = token;
    _user = user;
    _userType = type;
    _storage.write('token', token);
    _storage.write('user', user.toJson());
    _storage.write('user_type', type);
    Get.find<ApiClient>().updateToken(token);

    if (type == 'delivery') {
      final deliveryAuthController = Get.find<DeliveryAuthController>();
      
      final dm = rawJson != null 
          ? DeliverymanModel.fromJson(rawJson)
          : DeliverymanModel(
              id: user.id,
              name: user.name,
              email: user.email,
              phone: user.phone,
              isAvailable: true,
            );

      deliveryAuthController.syncSession(token, dm);
      Get.offAllNamed(RouteHelper.getDeliveryDashboard());
    } else {
      Get.offAllNamed(RouteHelper.getInitial());
    }
    update();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    update();

    try {
      Response response;
      if (_userType == 'delivery') {
        response = await authRepo.apiClient.postData(AppConstants.DELIVERY_LOGIN_URI, {
          'email': email,
          'password': password,
        });
      } else {
        response = await authRepo.login(email, password);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body != null) {
          final String? token = body['data']?['token'] ?? body['token'] ?? body['access_token'];
          final dynamic userJson = body['data']?['deliveryman'] ?? body['user'] ?? body['data']?['user'] ?? body['data'];

          if (token != null && userJson != null) {
            final userMap = Map<String, dynamic>.from(userJson);
            final user = UserModel.fromJson(userMap);
            _saveSession(token, user, _userType, rawJson: userMap);
          } else {
            _showError('El servidor no envió datos válidos');
          }
        }
      } else {
        _handleApiError(response, 'Error al iniciar sesión');
      }
    } catch (e) {
      _showError('Error de conexión');
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
            _saveSession(token, user, _userType);
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

  Future<void> getProfile() async {
    try {
      Response response = await authRepo.getProfile();
      if (response.statusCode == 200) {
        final body = response.body;
        final dynamic userData = body['data'] ?? body;
        if (userData != null) {
          _user = UserModel.fromJson(Map<String, dynamic>.from(userData));
          _storage.write('user', _user!.toJson());
          update();
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> updateProfile(String phone) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.updateProfile({
        'f_name': _user?.name,
        'phone': phone,
      });
      if (response.statusCode == 200) {
        _user?.phone = phone;
        _storage.write('user', _user?.toJson());
        Get.snackbar('Éxito', 'Teléfono actualizado',
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        update();
      } else {
        _handleApiError(response, 'No se pudo actualizar el perfil');
      }
    } catch (e) {
      _showError('Error al actualizar');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.changePassword(currentPassword, newPassword);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Contraseña actualizada',
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      } else {
        _handleApiError(response, 'No se pudo cambiar la contraseña');
      }
    } catch (e) {
      _showError('Error al cambiar la contraseña');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.forgotPassword(email);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Código enviado a tu correo',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return true;
      } else {
        _handleApiError(response, 'No se pudo enviar el código');
        return false;
      }
    } catch (e) {
      _showError('Error de conexión');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> resetPassword(String email, String otp, String password) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.resetPassword(email, otp, password);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Contraseña restablecida correctamente',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return true;
      } else {
        _handleApiError(response, 'No se pudo restablecer la contraseña');
        return false;
      }
    } catch (e) {
      _showError('Error de conexión');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> verifyEmail(String otp) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.verifyEmail(otp);
      if (response.statusCode == 200) {
        Get.snackbar('Éxito', 'Correo verificado',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return true;
      } else {
        _handleApiError(response, 'Código inválido');
        return false;
      }
    } catch (e) {
      _showError('Error de conexión');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _handleApiError(Response response, String fallback) {
    String message = fallback;
    if (response.body != null && response.body is Map) {
      final body = response.body as Map<String, dynamic>;
      if (body['errors'] != null) {
        var errors = body['errors'];
        if (errors is Map) {
          message = errors.values.first[0].toString();
        } else if (errors is List && errors.isNotEmpty) {
          message = errors[0].toString();
        }
      } else if (body['message'] != null) {
        message = body['message'];
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

  void logout() async {
    Get.find<ApiClient>().isLoggingOut = true;
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().stopPolling();
    }

    _token = '';
    _user = null;
    _storage.erase();
    
    // Limpieza total de controladores de la memoria (sin destruir el enrutador)
    Get.deleteAll(force: true);
    
    // Al limpiar dependencias, volvemos a inicializar las esenciales
    await dep.init();

    Get.offAllNamed(RouteHelper.getLogin());

    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<ApiClient>()) {
        Get.find<ApiClient>().isLoggingOut = false;
      }
    });
  }
}