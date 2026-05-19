import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class DeliveryOrderRepo {
  final ApiClient apiClient;
  DeliveryOrderRepo({required this.apiClient});

  Future<Response> getAvailableOrders() async {
    return await apiClient.getData(AppConstants.DELIVERY_AVAILABLE_ORDERS_URI);
  }

  Future<Response> getOrderHistory() async {
    return await apiClient.getData(AppConstants.DELIVERY_HISTORY_ORDERS_URI);
  }

  Future<Response> getRunningOrders() async {
    return await apiClient.getData(AppConstants.DELIVERY_ORDER_LIST_URI);
  }

  Future<Response> getActiveOrders() async {
    return await apiClient.getData(AppConstants.DELIVERY_ACTIVE_ORDERS_URI);
  }

  Future<Response> acceptOrder(int orderId) async {
    return await apiClient.postData("${AppConstants.DELIVERY_ACCEPT_ORDER_URI}$orderId/accept", {});
  }

  Future<Response> updateOrderStatus(int orderId, String status) async {
    // status should be 'on_the_way' or similar based on API requirements
    return await apiClient.putData("${AppConstants.DELIVERY_ORDER_STATUS_UPDATE_URI}$orderId/status", {
      'status': status
    });
  }

  Future<Response> verifyOtp(int orderId, String otp) async {
    return await apiClient.postData("${AppConstants.DELIVERY_VERIFY_OTP_URI}$orderId/verify-otp", {
      'otp_code': otp
    });
  }
}
