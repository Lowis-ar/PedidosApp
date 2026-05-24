import 'package:get/get.dart';
import '../../utils/app_constants.dart';
import '../api/api_client.dart';

class ProductRepo extends GetxService {
  final ApiClient apiClient;
  ProductRepo({required this.apiClient});

  Future<Response> getProductList({
    int? branchId,
    int? categoryId,
    String? search,
    String? sortBy,
    int? typeId,
  }) async {
    String uri = AppConstants.ALL_PRODUCTS_URI;
    List<String> params = [];
    
    if (typeId != null) params.add("type_id=$typeId");
    if (branchId != null) params.add("branch_id=$branchId");
    if (categoryId != null) params.add("category_id=$categoryId");
    if (search != null && search.isNotEmpty) params.add("search=$search");
    if (sortBy != null) params.add("sort_by=$sortBy");
    
    if (params.isNotEmpty) {
      uri += "?${params.join('&')}";
    }
    
    return await apiClient.getData(uri);
  }

  Future<Response> getCategoryList(int branchId) async {
    return await apiClient.getData("${AppConstants.CATEGORIES_URI}?branch_id=$branchId");
  }

  Future<Response> getProductDetail(int productId) async {
    return await apiClient.getData("${AppConstants.PRODUCT_DETAIL_URI}$productId");
  }

  Future<Response> getProductReviews(int productId, {int page = 1, int perPage = 20}) async {
    return await apiClient.getData(
      "${AppConstants.PRODUCT_REVIEWS_URI}$productId/reviews?page=$page&per_page=$perPage",
    );
  }
}
