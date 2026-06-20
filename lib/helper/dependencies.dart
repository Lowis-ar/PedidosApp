import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pedidosapp/controllers/auth_controller.dart';
import 'package:pedidosapp/controllers/popular_product_controller.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';
import 'package:pedidosapp/controllers/search_product_controller.dart';
import 'package:pedidosapp/controllers/order_controller.dart';
import 'package:pedidosapp/controllers/review_controller.dart';
import 'package:pedidosapp/controllers/coupon_controller.dart';
import 'package:pedidosapp/data/api/api_client.dart';
import 'package:pedidosapp/data/repository/auth_repo.dart';
import 'package:pedidosapp/data/repository/branch_repo.dart';
import 'package:pedidosapp/data/repository/product_repo.dart';
import 'package:pedidosapp/data/repository/order_repo.dart';
import 'package:pedidosapp/data/repository/coupon_repo.dart';
import 'package:pedidosapp/data/repository/delivery_auth_repo.dart';
import 'package:pedidosapp/data/repository/delivery_order_repo.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';

import '../controllers/cart_controller.dart';
import '../controllers/recommended_product_controller.dart';
import '../data/repository/cart_repo.dart';
import '../data/repository/popular_product_repo.dart';
import '../data/repository/recommended_product_repo.dart';
import '../data/repository/zone_repo.dart';
import '../controllers/zone_controller.dart';
import '../utils/app_constants.dart';

Future<void> init() async {
  await GetStorage.init();
  const secureStorage = FlutterSecureStorage();
  
  final String? deliveryToken = await secureStorage.read(key: AppConstants.DELIVERY_TOKEN);
  final String? customerToken = await secureStorage.read(key: AppConstants.TOKEN) ?? await secureStorage.read(key: 'token');
  
  String initialToken = '';
  if (deliveryToken != null && deliveryToken.isNotEmpty) {
      initialToken = deliveryToken;
  } else if (customerToken != null && customerToken.isNotEmpty) {
      initialToken = customerToken;
  }

  // Api Client
  final apiClient = ApiClient(appBaseUrl: AppConstants.BASE_URL);
  apiClient.updateToken(initialToken);
  Get.lazyPut(() => apiClient, fenix: true);

  // Repos
  Get.lazyPut(() => AuthRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => BranchRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => PopularProductRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => RecommendedProductRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => ProductRepo(apiClient: Get.find<ApiClient>()), fenix: true); 
  Get.lazyPut(() => CartRepo(), fenix: true);
  Get.lazyPut(() => OrderRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => ZoneRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => CouponRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => DeliveryAuthRepo(apiClient: Get.find<ApiClient>()), fenix: true);
  Get.lazyPut(() => DeliveryOrderRepo(apiClient: Get.find<ApiClient>()), fenix: true);

  // Controllers
  Get.put(AuthController(authRepo: Get.find<AuthRepo>()), permanent: true);
  Get.put(BranchController(branchRepo: Get.find<BranchRepo>()), permanent: true);
  Get.put(PopularProductController(popularProductRepo: Get.find<PopularProductRepo>()), permanent: true);
  Get.put(RecommendedProductController(recommendedProductRepo: Get.find<RecommendedProductRepo>()), permanent: true);
  Get.put(SearchProductController(productRepo: Get.find<ProductRepo>()), permanent: true);
  Get.put(CartController(cartRepo: Get.find<CartRepo>()), permanent: true);
  Get.put(OrderController(orderRepo: Get.find<OrderRepo>()), permanent: true);
  Get.put(ZoneController(zoneRepo: Get.find<ZoneRepo>()), permanent: true);
  Get.put(ReviewController(orderRepo: Get.find<OrderRepo>()), permanent: true);
  Get.put(CouponController(couponRepo: Get.find<CouponRepo>()), permanent: true);
  
  // Usamos Get.put para los controladores de delivery para asegurar persistencia y acceso rápido
  Get.put(DeliveryAuthController(deliveryAuthRepo: Get.find<DeliveryAuthRepo>()), permanent: true);
  Get.put(DeliveryOrderController(orderRepo: Get.find<DeliveryOrderRepo>()), permanent: true);
}

