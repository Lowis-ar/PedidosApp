import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/api/api_client.dart';
import '../data/repository/delivery_auth_repo.dart';
import '../models/deliveryman_model.dart';
import '../utils/app_constants.dart';
import 'delivery_order_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pedidosapp/utils/colors.dart';

class DeliveryAuthController extends GetxController {
  final DeliveryAuthRepo deliveryAuthRepo;
  DeliveryAuthController({required this.deliveryAuthRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final XFile? cropped = await _cropImage(image.path);
      if (cropped != null) {
        _pickedImage = cropped;
        update();
        if (_deliveryman != null) {
          await updateProfile(_deliveryman!.name ?? '', _deliveryman!.phone ?? '');
        }
      }
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

  bool get isLoggedIn => _token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  void _loadSession() {
    final savedToken = _storage.read<String>(AppConstants.DELIVERY_TOKEN);
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      // Inyectar el token antes de cualquier petición
      Get.find<ApiClient>().updateToken(_token);
      final userData = _storage.read(AppConstants.DELIVERY_USER_KEY);
      if (userData != null) {
        _deliveryman = DeliverymanModel.fromJson(Map<String, dynamic>.from(userData));
      }
      // Token ya inyectado: iniciar polling para sesión restaurada
      if (Get.isRegistered<DeliveryOrderController>()) {
        Get.find<DeliveryOrderController>().startPolling();
      }
    }
  }

  void _saveSession(String token, DeliverymanModel deliveryman) {
    _token = token;
    _deliveryman = deliveryman;
    _storage.write(AppConstants.DELIVERY_TOKEN, token);
    _storage.write(AppConstants.DELIVERY_USER_KEY, deliveryman.toJson());
    Get.find<ApiClient>().updateToken(token);
    update();
    
    // El token ya está inyectado: es seguro iniciar el polling y cargar pedidos
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().startPolling();
      Get.find<DeliveryOrderController>().getOrders();
    }
  }

  void syncSession(String token, DeliverymanModel deliveryman) {
    _token = token;
    _deliveryman = deliveryman;
    _storage.write(AppConstants.DELIVERY_TOKEN, token);
    _storage.write(AppConstants.DELIVERY_USER_KEY, deliveryman.toJson());
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
      Response response = await deliveryAuthRepo.updateProfile({'is_available': available});
      if (response.statusCode == 200) {
        _deliveryman?.isAvailable = available;
        _storage.write(AppConstants.DELIVERY_USER_KEY, _deliveryman?.toJson());
        update();
      }
    } catch (e) {
      _showError('No se pudo actualizar el estado');
    }
  }

  Future<void> getProfile() async {
    try {
      Response response = await deliveryAuthRepo.getProfile();
      debugPrint("Profile API Raw: ${response.body}");
      if (response.statusCode == 200) {
        final body = response.body;
        // La API devuelve { success: true, data: { deliveryman: { ... } } }
        final dynamic dmJson = body['data']?['deliveryman'] ?? body['deliveryman'] ?? body['data'] ?? body;
        if (dmJson != null) {
          _deliveryman = DeliverymanModel.fromJson(Map<String, dynamic>.from(dmJson));
          _storage.write(AppConstants.DELIVERY_USER_KEY, _deliveryman?.toJson());
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
      Map<String, dynamic> data = {'name': name, 'phone': phone};
      
      if (_pickedImage != null) {
        data['image'] = MultipartFile(
          await _pickedImage!.readAsBytes(),
          filename: _pickedImage!.name,
        );
      }

      Response response = await deliveryAuthRepo.updateProfile(data);
      if (response.statusCode == 200) {
        await getProfile();
        _pickedImage = null; // Clear after success
        Get.back();
        Get.snackbar('Éxito', 'Perfil actualizado');
      }
    } catch (e) {
      _showError('Error al actualizar');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void logout() async {
    Get.find<ApiClient>().isLoggingOut = true;
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().stopPolling();
    }

    await deliveryAuthRepo.logout();
    _token = '';
    _deliveryman = null;
    _storage.erase();
    Get.find<ApiClient>().updateToken('');
    update();

    Get.offAllNamed('/delivery-login');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<ApiClient>()) {
        Get.find<ApiClient>().isLoggingOut = false;
      }
    });
  }

  void _handleApiError(Response response, String fallback) {
    String message = fallback;
    if (response.body != null && response.body is Map) {
      message = response.body['message'] ?? fallback;
    }
    _showError(message);
  }

  void _showError(String message) {
    Get.snackbar('Aviso', message, backgroundColor: Colors.redAccent, colorText: Colors.white);
  }
}
