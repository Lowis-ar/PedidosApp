import 'package:get/get.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';

import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class PopularProductRepo extends GetxService {
  final ApiClient apiClient;
  PopularProductRepo({required this.apiClient});

  Future<Response> getPopularProductList() async {
    String uri = AppConstants.POPULAR_PRODUCT_URI;
    try {
      if (Get.isRegistered<BranchController>()) {
        final controller = Get.find<BranchController>();
        final branchId = controller.isLoaded ? controller.branchId : 2;
        uri += "&branch_id=$branchId";
      }
    } catch (_) {}
    return await apiClient.getData(uri);
  }
}
