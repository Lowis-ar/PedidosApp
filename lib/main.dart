import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/popular_product_controller.dart';
import 'package:pedidosapp/controllers/recommended_product_controller.dart';
import 'package:pedidosapp/pages/cart/cart_page.dart';
import 'package:pedidosapp/pages/home/main_food_page.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'helper/dependencies.dart' as dep;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dep.init();
  // Cargamos los datos después de inicializar las dependencias
  Get.find<PopularProductController>().getPopularProductList();
  Get.find<RecommendedProductController>().getRecommendedProductList();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: RouteHelper.initial,
      getPages: RouteHelper.routes,
    );
  }
}
