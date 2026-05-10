import 'package:get/get.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';

import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class RecommendedProductRepo extends GetxService {
  final ApiClient apiClient;
  RecommendedProductRepo({required this.apiClient});

  Future<Response> getRecommendedProductList() async {
    int branchId = Get.find<BranchController>().branchId;
    return await apiClient.getData("${AppConstants.RECOMMENDED_PRODUCT_URI}?branch_id=$branchId");
  }
}
