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

  // Cargar y validar el token ANTES de evaluar isLoggedIn.
  // Esto corrige el race condition donde isLoggedIn se leía como false
  // aunque hubiera un token guardado (porque _loadToken() es async).
  final authController = Get.find<AuthController>();
  await authController.loadToken();

  if (authController.isLoggedIn && !authController.isDelivery) {
    Get.find<CartController>();
    Get.find<PopularProductController>().getPopularProductList();
    Get.find<RecommendedProductController>().getRecommendedProductList();
  }

  runApp(MyApp(isLoggedIn: authController.isLoggedIn, isDelivery: authController.isDelivery));
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isDelivery;
  const MyApp({super.key, required this.isLoggedIn, required this.isDelivery});

  @override
  Widget build(BuildContext context) {
    String initialRoute = RouteHelper.login;
    if (isLoggedIn) {
      initialRoute = isDelivery ? RouteHelper.deliveryDashboard : RouteHelper.initial;
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PedidosApp',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF89dad0)),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      getPages: RouteHelper.routes,
    );
  }
}
