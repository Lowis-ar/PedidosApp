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

  Future<Response> googleLogin(String idToken, {String? phone}) async {
    String? formattedPhone;
    if (phone != null) {
      formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
      if (formattedPhone.length == 8) {
        formattedPhone = '+503$formattedPhone';
      }
    }
    final Map<String, dynamic> body = {
      'id_token': idToken,
    };
    if (formattedPhone != null) {
      body['phone'] = formattedPhone;
    }
    return await apiClient.postData(AppConstants.GOOGLE_LOGIN_URI, body);
  }

  Future<Response> register(String name, String phone, String email, String password) async {
    String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (formattedPhone.length == 8) {
      formattedPhone = '+503$formattedPhone';
    } else if (formattedPhone.startsWith('+503') && formattedPhone.length == 12) {
      // Backend expects +503XXXXXXXX or +503 XXXXXXXX
      formattedPhone = formattedPhone;
    }

    return await apiClient.postData(AppConstants.REGISTER_URI, {
      'name': name,
      'phone': formattedPhone,
      'email': email,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<Response> getProfile() async {
    return await apiClient.getData(AppConstants.CUSTOMER_INFO_URI);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await apiClient.putData(AppConstants.UPDATE_PROFILE_URI, data);
  }

  Future<Response> changePassword(String currentPassword, String newPassword) async {
    return await apiClient.putData(AppConstants.CHANGE_PASSWORD_URI, {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<Response> forgotPassword(String email) async {
    return await apiClient.postData(AppConstants.FORGOT_PASSWORD_URI, {
      'email': email,
    });
  }

  Future<Response> resetPassword(String email, String otp, String password) async {
    return await apiClient.postData(AppConstants.RESET_PASSWORD_URI, {
      'email': email,
      'otp': otp,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<Response> verifyEmail(String email, String otp) async {
    return await apiClient.postData(AppConstants.VERIFY_EMAIL_URI, {
      'email': email,
      'otp': otp,
    });
  }

  Future<Response> resendVerificationEmail(String email) async {
    return await apiClient.postData('/api/v1/auth/resend-verification-email', {
      'email': email,
    });
  }
}
