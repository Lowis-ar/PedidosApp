import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/cart_controller.dart';
import 'package:pedidosapp/utils/dimensions.dart';
import 'package:pedidosapp/widgets/app_icon.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../widgets/big_text.dart';
import '../../widgets/small_text.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header
          Positioned(
            left: Dimensions.width20,
            right: Dimensions.width20,
            top: Dimensions.height20 * 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: AppIcon(
                    icon: Icons.arrow_back_ios,
                    iconColor: Colors.white,
                    backgroundColor: AppColors.mainColor,
                    iconSize: Dimensions.iconSize24,
                  ),
                ),
                SizedBox(width: Dimensions.width20 * 5),
                GestureDetector(
                  onTap: () => Get.toNamed(RouteHelper.getInitial()),
                  child: AppIcon(
                    icon: Icons.home_outlined,
                    iconColor: Colors.white,
                    backgroundColor: AppColors.mainColor,
                    iconSize: Dimensions.iconSize24,
                  ),
                ),
                SizedBox(width: Dimensions.width20),
                AppIcon(
                  icon: Icons.shopping_cart_outlined,
                  iconColor: Colors.white,
                  backgroundColor: AppColors.mainColor,
                  iconSize: Dimensions.iconSize24,
                ),
              ],
            ),
          ),
          // List
          Positioned(
            left: Dimensions.width20,
            right: Dimensions.width20,
            top: Dimensions.height20 * 5,
            bottom: 0,
            child: Container(
              margin: EdgeInsets.only(top: Dimensions.height15),
              color: Colors.white,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: GetBuilder<CartController>(builder: (cartController) {
                  var cartList = cartController.getItems;
                  if (cartList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: Dimensions.iconSize24 * 3,
                            color: AppColors.textColor,
                          ),
                          SizedBox(height: Dimensions.height20),
                          BigText(
                            text: "Tu carrito esta vacio",
                            color: AppColors.paraColor,
                            size: Dimensions.font20,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: cartList.length,
                    itemBuilder: (_, index) {
                      return Container(
                        height: Dimensions.height20 * 5,
                        margin: EdgeInsets.only(bottom: Dimensions.height10),
                        child: Row(
                          children: [
                            Container(
                              width: Dimensions.height20 * 5,
                              height: Dimensions.height20 * 5,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(cartList[index].img!),
                                ),
                                borderRadius: BorderRadius.circular(Dimensions.radius20),
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: Dimensions.width10),
                            Expanded(
                              child: SizedBox(
                                height: Dimensions.height20 * 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    BigText(
                                      text: cartList[index].name!,
                                      color: Colors.black54,
                                    ),
                                    SmallText(text: cartList[index].product?.location ?? "Local"),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        BigText(
                                          text: "\$ ${cartList[index].price!}",
                                          color: Colors.redAccent,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height10,
                                            horizontal: Dimensions.width10,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(Dimensions.radius20),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  cartController.addItem(cartList[index].product!, -1);
                                                },
                                                child: Icon(
                                                  Icons.remove,
                                                  color: AppColors.singColor,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: Dimensions.width10 / 2),
                                              BigText(
                                                text: cartList[index].quantity.toString(),
                                                size: Dimensions.font18,
                                              ),
                                              SizedBox(width: Dimensions.width10 / 2),
                                              GestureDetector(
                                                onTap: () {
                                                  cartController.addItem(cartList[index].product!, 1);
                                                },
                                                child: Icon(
                                                  Icons.add,
                                                  color: AppColors.singColor,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
        var cartList = cartController.getItems;
        if (cartList.isEmpty) return const SizedBox.shrink();

        double totalAmount = 0;
        for (var item in cartList) {
          totalAmount += (item.price ?? 0) * (item.quantity ?? 0);
        }

        return Container(
          height: Dimensions.bottomHeightBar,
          padding: EdgeInsets.only(
            top: Dimensions.height30,
            bottom: Dimensions.height30,
            left: Dimensions.width20,
            right: Dimensions.width20,
          ),
          decoration: BoxDecoration(
            color: AppColors.buttonBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radius20 * 2),
              topRight: Radius.circular(Dimensions.radius20 * 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.height15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radius20),
                  color: Colors.white,
                ),
                child: BigText(
                  text: "\$ ${totalAmount.toStringAsFixed(1)}",
                  size: Dimensions.font18,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Check if user is logged in before checkout
                  final authController = Get.find<AuthController>();
                  if (!authController.isLoggedIn) {
                    Get.snackbar(
                      'Inicia sesion',
                      'Debes iniciar sesion para realizar un pedido',
                      backgroundColor: AppColors.mainColor,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }
                  Get.snackbar(
                    'Pedido',
                    'Funcionalidad de checkout proximamente',
                    backgroundColor: AppColors.mainColor,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(Dimensions.height15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radius20),
                    color: AppColors.mainColor,
                  ),
                  child: BigText(
                    text: "Check out",
                    color: Colors.white,
                    size: Dimensions.font18,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
