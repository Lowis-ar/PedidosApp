import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/api/api_client.dart';
import '../data/repository/auth_repo.dart';
import '../models/user_model.dart';

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
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    update();

    Response response = await authRepo.login(email, password);

    if (response.statusCode == 200) {
      final body = response.body;
      final token = body['token'];
      final user = UserModel.fromJson(body['user']);
      _saveSession(token, user);
    } else {
      String message = 'Error al iniciar sesion';
      if (response.body != null && response.body['errors'] != null) {
        message = response.body['errors'][0]['message'];
      }
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }

    _isLoading = false;
    update();
  }

  Future<void> register(String name, String phone, String email, String password) async {
    _isLoading = true;
    update();

    Response response = await authRepo.register(name, phone, email, password);

    if (response.statusCode == 201) {
      final body = response.body;
      final token = body['token'];
      final user = UserModel.fromJson(body['user']);
      _saveSession(token, user);
    } else {
      String message = 'Error al registrarse';
      if (response.body != null && response.body['errors'] != null) {
        message = response.body['errors'][0]['message'];
      }
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }

    _isLoading = false;
    update();
  }

  void logout() {
    _token = '';
    _user = null;
    _storage.remove('token');
    _storage.remove('user');
    Get.find<ApiClient>().updateToken('');
    update();
  }
}
