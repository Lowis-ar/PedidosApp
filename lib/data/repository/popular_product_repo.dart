import 'package:get/get.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';

import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class PopularProductRepo extends GetxService {
  final ApiClient apiClient;
  PopularProductRepo({required this.apiClient});

  Future<Response> getPopularProductList() async {
    int branchId = Get.find<BranchController>().branchId;
    return await apiClient.getData("${AppConstants.POPULAR_PRODUCT_URI}?branch_id=$branchId");
  }
}
