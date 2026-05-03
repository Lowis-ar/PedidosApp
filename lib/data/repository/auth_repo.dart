import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class AuthRepo extends GetxService {
  final ApiClient apiClient;
  AuthRepo({required this.apiClient});

  Future<Response> login(String email, String password) async {
    return await apiClient.postData(AppConstants.LOGIN_URI, {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String name, String phone, String email, String password) async {
    return await apiClient.postData(AppConstants.REGISTER_URI, {
      'f_name': name,
      'phone': phone,
      'email': email,
      'password': password,
    });
  }
}
