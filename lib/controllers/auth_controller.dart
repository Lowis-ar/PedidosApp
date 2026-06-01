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
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/utils/dimensions.dart';

import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/helper/dependencies.dart' as dep;

class AuthController extends GetxController {
  final AuthRepo authRepo;
  AuthController({required this.authRepo});

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '256020390313-sfud3k6e9f6dv7s9cot784u917c37i0l.apps.googleusercontent.com',
    scopes: ['email'],
  );

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

  void _saveSession(String token, UserModel user, String type, {Map<String, dynamic>? rawJson, bool navigate = true}) {
    _token = token;
    _user = user;
    _userType = type;
    _storage.write('token', token);
    _storage.write('user', user.toJson());
    _storage.write('user_type', type);
    Get.find<ApiClient>().updateToken(token);

    if (navigate) {
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

  Future<bool> register(String name, String phone, String email, String password) async {
    _isLoading = true;
    update();

    try {
      Response response = await authRepo.register(name, phone, email, password);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        _handleApiError(response, 'Error al registrarse');
        return false;
      }
    } catch (e) {
      _showError('No se pudo completar el registro. Verifica los datos.');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    update();

    try {
      // Intentar forzar el inicio de sesión y desconectar previa cuenta para asegurar selección limpia de cuenta
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint("Error signing out Google before signing in: $e");
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Cancelado por el usuario
        _isLoading = false;
        update();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        update();
        _showError('No se pudo obtener el ID Token de Google.');
        return;
      }

      Response response = await authRepo.googleLogin(idToken);
      await _handleGoogleLoginResponse(response, idToken);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      _showError('Error al iniciar sesión con Google: $e');
      _isLoading = false;
      update();
    }
  }

  Future<void> _handleGoogleLoginResponse(Response response, String idToken) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      if (body != null) {
        final bool requiresPhone = body['data']?['requires_phone'] ?? body['requires_phone'] ?? false;
        if (requiresPhone) {
          _isLoading = false;
          update();
          // Abrir cuadro de diálogo premium para registrar teléfono
          _showPhonePickerDialog(idToken);
        } else {
          final String? token = body['data']?['token'] ?? body['token'] ?? body['access_token'];
          final dynamic userJson = body['user'] ?? body['data']?['user'] ?? body['data'];

          if (token != null && userJson != null) {
            final userMap = Map<String, dynamic>.from(userJson);
            final user = UserModel.fromJson(userMap);
            _saveSession(token, user, 'customer', rawJson: userMap);
          } else {
            _showError('El servidor no envió datos válidos');
          }
        }
      }
    } else {
      _isLoading = false;
      update();
      _handleApiError(response, 'Error de autenticación con Google');
    }
  }

  void _showPhonePickerDialog(String idToken) {
    final TextEditingController phoneController = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius20),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.height20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ilustración de cabecera usando vectores de material design (sin emojis)
                Container(
                  padding: EdgeInsets.all(Dimensions.height15),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    size: Dimensions.iconSize24 * 1.5,
                    color: AppColors.mainColor,
                  ),
                ),
                SizedBox(height: Dimensions.height15),
                Text(
                  "Completa tu perfil",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: Dimensions.font20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainBlackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.height10),
                Text(
                  "Necesitamos tu número de teléfono para que el repartidor pueda comunicarse contigo al entregar tu pedido.",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: Dimensions.font16,
                    color: AppColors.paraColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.height20),
                // Campo de texto de teléfono premium
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: AppColors.mainBlackColor,
                    fontSize: Dimensions.font16,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.phone_rounded,
                      color: AppColors.mainColor,
                    ),
                    hintText: "71234567",
                    hintStyle: TextStyle(
                      color: AppColors.textColor,
                    ),
                    labelText: "Número de Teléfono",
                    labelStyle: TextStyle(
                      color: AppColors.paraColor,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radius15),
                      borderSide: BorderSide(
                        color: AppColors.mainColor,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radius15),
                      borderSide: BorderSide(
                        color: AppColors.textColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.height20),
                // Acciones del modal
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: Dimensions.height15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radius15),
                          ),
                        ),
                        child: Text(
                          "Cancelar",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16,
                            color: AppColors.singColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.width10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            _showError('Por favor ingresa tu número de teléfono.');
                            return;
                          }
                          final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
                          if (cleanPhone.length < 8) {
                            _showError('Por favor ingresa un número de teléfono válido.');
                            return;
                          }
                          Get.back(); // cerrar diálogo
                          
                          _isLoading = true;
                          update();

                          try {
                            Response response = await authRepo.googleLogin(idToken, phone: cleanPhone);
                            await _handleGoogleLoginResponse(response, idToken);
                          } catch (e) {
                            _showError('Error al registrar el teléfono.');
                            _isLoading = false;
                            update();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          padding: EdgeInsets.symmetric(vertical: Dimensions.height15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radius15),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Confirmar",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
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

  Future<bool> verifyEmail(String email, String otp) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.verifyEmail(email, otp);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body != null) {
          final String? token = body['data']?['token'] ?? body['token'] ?? body['access_token'];
          final dynamic userJson = body['user'] ?? body['data']?['user'] ?? body['data'];

          if (token != null && userJson != null) {
            final user = UserModel.fromJson(userJson is Map<String, dynamic> ? userJson : Map<String, dynamic>.from(userJson));
            _saveSession(token, user, _userType, navigate: true);
            Get.snackbar('Éxito', 'Correo verificado y cuenta creada',
                backgroundColor: Colors.green, colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
            return true;
          }
        }
        _showError('Hubo un problema al crear la sesión.');
        return false;
      } else {
        _handleApiError(response, 'Código inválido o caducado');
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

  Future<bool> resendVerificationEmail(String email) async {
    _isLoading = true;
    update();
    try {
      Response response = await authRepo.resendVerificationEmail(email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Éxito', 'Código reenviado. Revisa tu correo.',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return true;
      } else {
        _handleApiError(response, 'No se pudo reenviar el código.');
        return false;
      }
    } catch (e) {
      _showError('Error de conexión al reenviar el código.');
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