import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:pedidosapp/controllers/popular_product_controller.dart';
import 'package:pedidosapp/data/api/api_client.dart';

import '../data/repository/popular_product_repo.dart';

Future<void> init()async{

  Get.lazyPut(() => ApiClient(appBaseUrl: "https://mvs.bslmeiyu.com"));
  Get.lazyPut(() => PopularProductRepo(apiClient: Get.find()));
  Get.lazyPut(() => PopularProductController(popularProductRepo: Get.find()));

}