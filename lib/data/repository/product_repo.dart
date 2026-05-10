import 'package:get/get.dart';
import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class ProductRepo extends GetxService {
  final ApiClient apiClient;
  ProductRepo({required this.apiClient});

  Future<Response> getProductList({
    required int branchId,
    int? categoryId,
    String? search,
    String? sortBy,
  }) async {
    String uri = "${AppConstants.ALL_PRODUCTS_URI}?branch_id=$branchId";
    if (categoryId != null) uri += "&category_id=$categoryId";
    if (search != null && search.isNotEmpty) uri += "&search=$search";
    if (sortBy != null) uri += "&sort_by=$sortBy";
    
    return await apiClient.getData(uri);
  }

  Future<Response> getCategoryList(int branchId) async {
    return await apiClient.getData("${AppConstants.CATEGORIES_URI}?branch_id=$branchId");
  }
}
