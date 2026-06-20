import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/api/api_client.dart';
import '../data/repository/delivery_auth_repo.dart';
import '../models/deliveryman_model.dart';
import '../utils/app_constants.dart';
import 'delivery_order_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/utils/app_snackbar.dart';
import 'dart:io';

class DeliveryAuthController extends GetxController {
  final DeliveryAuthRepo deliveryAuthRepo;
  DeliveryAuthController({required this.deliveryAuthRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    debugPrint("[DeliveryAuthController] Launching ImagePicker...");
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      debugPrint("[DeliveryAuthController] Image picked: ${image.path}, launching image cropper...");
      final XFile? cropped = await _cropImage(image.path);
      if (cropped != null) {
        debugPrint("[DeliveryAuthController] Image crop completed: ${cropped.path}");
        _pickedImage = cropped;
        update();
        if (_deliveryman != null) {
          debugPrint("[DeliveryAuthController] Triggering updateProfile automatic upload...");
          await updateProfile(_deliveryman!.name ?? '', _deliveryman!.phone ?? '');
        } else {
          debugPrint("[DeliveryAuthController] Deliveryman is null, cannot upload profile picture.");
        }
      } else {
        debugPrint("[DeliveryAuthController] Image crop cancelled by user.");
      }
    } else {
      debugPrint("[DeliveryAuthController] Image picking cancelled by user.");
    }
  }

  Future<XFile?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar Imagen',
          toolbarColor: AppColors.mainColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Recortar Imagen',
          aspectRatioLockEnabled: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );
    if (croppedFile != null) {
      return XFile(croppedFile.path);
    }
    return null;
  }

  DeliverymanModel? _deliveryman;
  DeliverymanModel? get deliveryman => _deliveryman;

  String _token = '';
  String get token => _token;

  final _storage = GetStorage();
  final _secureStorage = const FlutterSecureStorage();

  bool get isLoggedIn => _token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final savedToken = await _secureStorage.read(key: AppConstants.DELIVERY_TOKEN);
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      // Inyectar el token antes de cualquier petición
      Get.find<ApiClient>().updateToken(_token);
      final userDataStr = await _secureStorage.read(key: AppConstants.DELIVERY_USER_KEY);
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          _deliveryman = DeliverymanModel.fromJson(Map<String, dynamic>.from(userData));
        } catch (e) {
          debugPrint('Error decoding delivery user: $e');
        }
      }
      // Token ya inyectado: iniciar polling para sesión restaurada
      if (Get.isRegistered<DeliveryOrderController>()) {
        Get.find<DeliveryOrderController>().startPolling();
      }
      update();
    }
  }

  Future<void> _saveSession(String token, DeliverymanModel deliveryman) async {
    _token = token;
    _deliveryman = deliveryman;
    await _secureStorage.write(key: AppConstants.DELIVERY_TOKEN, value: token);
    await _secureStorage.write(key: AppConstants.DELIVERY_USER_KEY, value: jsonEncode(deliveryman.toJson()));
    Get.find<ApiClient>().updateToken(token);
    update();
    
    // El token ya está inyectado: es seguro iniciar el polling y cargar pedidos
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().startPolling();
      Get.find<DeliveryOrderController>().getOrders();
    }
  }

  Future<void> syncSession(String token, DeliverymanModel deliveryman) async {
    _token = token;
    _deliveryman = deliveryman;
    await _secureStorage.write(key: AppConstants.DELIVERY_TOKEN, value: token);
    await _secureStorage.write(key: AppConstants.DELIVERY_USER_KEY, value: jsonEncode(deliveryman.toJson()));
    Get.find<ApiClient>().updateToken(token);
    update();
    
    // El token ya está inyectado: es seguro iniciar el polling y cargar pedidos
    Get.find<DeliveryOrderController>().startPolling();
    Get.find<DeliveryOrderController>().getOrders();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    update();

    try {
      Response response = await deliveryAuthRepo.login(email, password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body['success'] == true && body['data'] != null) {
          final String? token = body['data']['token'];
          final dynamic dmJson = body['data']['deliveryman'];

          if (token != null && dmJson != null) {
            final deliveryman = DeliverymanModel.fromJson(Map<String, dynamic>.from(dmJson));
            _saveSession(token, deliveryman);
          } else {
            _showError('No se recibieron credenciales válidas');
          }
        }
      } else {
        _handleApiError(response, 'Error de autenticación');
      }
    } catch (e) {
      _showError('Error de conexión');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> updateAvailability(bool available) async {
    try {
      final data = {
        'is_available': available ? 1 : 0,
        'is_active': available ? 1 : 0,
      };
      
      Response response = await deliveryAuthRepo.updateProfile(data);
      if (response.statusCode == 200) {
        _deliveryman?.isAvailable = available;
        _storage.write(AppConstants.DELIVERY_USER_KEY, _deliveryman?.toJson());
        update();
      } else {
      if (kDebugMode) {
        debugPrint('Error toggle status: ${response.body}');
      }
        _handleApiError(response, 'No se pudo cambiar el estado.');
      }
    } catch (e) {
      debugPrint('Exception toggle status: $e');
      _showError('Error de conexión');
    }
  }

  Future<void> getProfile() async {
    try {
      Response response = await deliveryAuthRepo.getProfile();
      if (kDebugMode) {
        debugPrint("Profile API Raw: ${response.body}");
      }
      if (response.statusCode == 200) {
        final body = response.body;
        // La API devuelve { success: true, data: { deliveryman: { ... } } }
        final dynamic dmJson = body['data']?['deliveryman'] ?? body['deliveryman'] ?? body['data'] ?? body;
        if (dmJson != null) {
          _deliveryman = DeliverymanModel.fromJson(Map<String, dynamic>.from(dmJson));
          await _secureStorage.write(key: AppConstants.DELIVERY_USER_KEY, value: jsonEncode(_deliveryman?.toJson()));
          update();
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    _isLoading = true;
    update();
    try {
      final Map<String, dynamic> data = {'name': name, 'phone': phone};

      Response response = await deliveryAuthRepo.updateProfile(data);
      if (response.statusCode == 200) {
        await getProfile();
        _pickedImage = null;
        Get.back();
        AppSnackbar.success('Éxito', 'Perfil actualizado');
      } else {
        _showError('No se pudo actualizar el perfil. Intenta de nuevo.');
      }
    } catch (e) {
      _showError('Error al actualizar');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> logout() async {
    Get.find<ApiClient>().isLoggingOut = true;
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().stopPolling();
    }

    try {
      await deliveryAuthRepo.logout();
    } catch(e) {
      debugPrint("Logout error: $e");
    }
    _token = '';
    _deliveryman = null;
    await _secureStorage.deleteAll();
    Get.find<ApiClient>().updateToken('');
    update();

    Get.offAllNamed('/delivery-login');

    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().isLoggingOut = false;
    }
  }

  void _handleApiError(Response response, String fallback) {
    String message = fallback;
    if (response.body != null && response.body is Map) {
      message = response.body['message'] ?? fallback;
    } else if (response.statusText != null) {
      if (message == fallback) {
        message = response.statusText!;
      }
    }

    String lowerMsg = message.toLowerCase();
    if (lowerMsg.contains('exception') || 
        lowerMsg.contains('sql') || 
        lowerMsg.contains('server') || 
        lowerMsg.contains('connection') || 
        lowerMsg.contains('timeout') ||
        lowerMsg.contains('error') && message.contains('errno')) {
      message = 'Ocurrió un error inesperado, intenta nuevamente.';
    }

    _showError(message);
  }

  void _showError(String message) {
    AppSnackbar.error('Aviso', message);
  }
}
