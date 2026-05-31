import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class OrderRepo {
  final ApiClient apiClient;
  OrderRepo({required this.apiClient});

  Future<Response> placeOrder(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.PLACE_ORDER_URI, body);
  }

  Future<Response> getOrderList() async {
    return await apiClient.getData(AppConstants.ORDER_LIST_URI);
  }

  Future<Response> getOrderDetail(int orderId) async {
    return await apiClient.getData("${AppConstants.ORDER_DETAIL_URI}$orderId");
  }

  Future<Response> cancelOrder(int orderId) async {
    return await apiClient.postData("${AppConstants.CANCEL_ORDER_URI}$orderId/cancel", {});
  }

  Future<Response> getShippingFee(double lat, double lng, int branchId) async {
    return await apiClient.postData('/api/v1/shipping/fee', {
      'lat': lat,
      'lng': lng,
      'branch_id': branchId,
    });
  }

  // Address endpoints
  Future<Response> getAddressList() async {
    return await apiClient.getData(AppConstants.ADDRESSES_URI);
  }

  Future<Response> addAddress(Map<String, dynamic> body) async {
    return await apiClient.postData(AppConstants.ADDRESSES_URI, body);
  }

  Future<Response> deleteAddress(int addressId) async {
    return await apiClient.deleteData("${AppConstants.ADDRESSES_URI}/$addressId");
  }

  Future<Response> submitReview(int orderId, Map<String, dynamic> body) async {
    return await apiClient.postData(
        "${AppConstants.ORDER_DETAIL_URI}$orderId/review", body);
  }
}
