import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pedidosapp/controllers/auth_controller.dart';
import 'package:pedidosapp/controllers/popular_product_controller.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';
import 'package:pedidosapp/controllers/search_product_controller.dart';
import 'package:pedidosapp/controllers/order_controller.dart';
import 'package:pedidosapp/data/api/api_client.dart';
import 'package:pedidosapp/data/repository/auth_repo.dart';
import 'package:pedidosapp/data/repository/branch_repo.dart';
import 'package:pedidosapp/data/repository/product_repo.dart';
import 'package:pedidosapp/data/repository/order_repo.dart';
import 'package:pedidosapp/data/repository/delivery_auth_repo.dart';
import 'package:pedidosapp/data/repository/delivery_order_repo.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';

import '../controllers/cart_controller.dart';
import '../controllers/recommended_product_controller.dart';
import '../data/repository/cart_repo.dart';
import '../data/repository/popular_product_repo.dart';
import '../data/repository/recommended_product_repo.dart';
import '../utils/app_constants.dart';

Future<void> init() async {
  await GetStorage.init();

  // Api Client
  Get.lazyPut(() => ApiClient(appBaseUrl: AppConstants.BASE_URL));

  // Repos
  Get.lazyPut(() => AuthRepo(apiClient: Get.find()));
  Get.lazyPut(() => BranchRepo(apiClient: Get.find()));
  Get.lazyPut(() => PopularProductRepo(apiClient: Get.find()));
  Get.lazyPut(() => RecommendedProductRepo(apiClient: Get.find()));
  Get.lazyPut(() => ProductRepo(apiClient: Get.find())); 
  Get.lazyPut(() => CartRepo());
  Get.lazyPut(() => OrderRepo(apiClient: Get.find()));
  Get.lazyPut(() => DeliveryAuthRepo(apiClient: Get.find()));
  Get.lazyPut(() => DeliveryOrderRepo(apiClient: Get.find()));

  // Controllers
  Get.lazyPut(() => AuthController(authRepo: Get.find()));
  Get.lazyPut(() => BranchController(branchRepo: Get.find()), fenix: true);
  Get.lazyPut(() => PopularProductController(popularProductRepo: Get.find()));
  Get.lazyPut(() => RecommendedProductController(recommendedProductRepo: Get.find()));
  Get.lazyPut(() => SearchProductController(productRepo: Get.find()), fenix: true);
  Get.lazyPut(() => CartController(cartRepo: Get.find()), fenix: true);
  Get.lazyPut(() => OrderController(orderRepo: Get.find()), fenix: true);
  Get.lazyPut(() => DeliveryAuthController(deliveryAuthRepo: Get.find()));
  Get.lazyPut(() => DeliveryOrderController(orderRepo: Get.find()));
}
