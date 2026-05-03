import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/auth_controller.dart';
import 'package:pedidosapp/controllers/cart_controller.dart';
import 'package:pedidosapp/controllers/popular_product_controller.dart';
import 'package:pedidosapp/controllers/recommended_product_controller.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'helper/dependencies.dart' as dep;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dep.init();

  // Initialize controllers
  final authController = Get.find<AuthController>();
  Get.find<CartController>();
  Get.find<PopularProductController>().getPopularProductList();
  Get.find<RecommendedProductController>().getRecommendedProductList();

  runApp(MyApp(isLoggedIn: authController.isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PedidosApp',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF89dad0)),
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? RouteHelper.initial : RouteHelper.login,
      getPages: RouteHelper.routes,
    );
  }
}
