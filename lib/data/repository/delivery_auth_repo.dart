import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class DeliveryAuthRepo {
  final ApiClient apiClient;
  DeliveryAuthRepo({required this.apiClient});

  Future<Response> login(String email, String password) async {
    return await apiClient.postData(AppConstants.DELIVERY_LOGIN_URI, {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getProfile() async {
    return await apiClient.getData(AppConstants.DELIVERY_PROFILE_URI);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await apiClient.postData(AppConstants.DELIVERY_UPDATE_PROFILE_URI, FormData(data));
  }

  Future<Response> logout() async {
    return await apiClient.postData(AppConstants.DELIVERY_LOGOUT_URI, {});
  }
}
