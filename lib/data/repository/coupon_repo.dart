import 'package:get/get.dart';
import '../api/api_client.dart';
import '../../utils/app_constants.dart';

class CouponRepo {
  final ApiClient apiClient;
  CouponRepo({required this.apiClient});

  Future<Response> validateCoupon(String code, double orderAmount, int branchId) async {
    return await apiClient.postData(AppConstants.VALIDATE_COUPON_URI, {
      'code': code,
      'order_amount': orderAmount,
      'branch_id': branchId,
    });
  }

  Future<Response> getLoyaltyProfile() async {
    return await apiClient.getData(AppConstants.LOYALTY_PROFILE_URI);
  }

  Future<Response> getLoyaltyTransactions({int perPage = 15}) async {
    return await apiClient.getData('${AppConstants.LOYALTY_TRANSACTIONS_URI}?per_page=$perPage');
  }

  Future<Response> getUserCoupons() async {
    return await apiClient.getData(AppConstants.LOYALTY_COUPONS_URI);
  }
}
