import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        title: const Text(
          'Perfil',
          style: TextStyle(fontFamily: 'Roboto', color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: GetBuilder<AuthController>(builder: (authController) {
        final user = authController.user;
        if (user == null) {
          return const Center(child: Text('No se pudo cargar la informacion del usuario'));
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: Dimensions.height30),
              // Avatar
              Center(
                child: Container(
                  width: Dimensions.screenHeight * 0.15,
                  height: Dimensions.screenHeight * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mainColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (user.fName ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: Dimensions.font26 * 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.height15),
              Text(
                user.fName ?? '',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBlackColor,
                ),
              ),
              SizedBox(height: Dimensions.height30 * 1.5),
              // Info rows
              _profileRow(Icons.person_outline, user.fName ?? 'Sin nombre'),
              _profileRow(Icons.email_outlined, user.email ?? 'Sin correo'),
              _profileRow(Icons.phone_outlined, user.phone ?? 'Sin telefono'),
              _profileRow(Icons.shopping_bag_outlined, '${user.orderCount ?? 0} pedidos realizados'),
              SizedBox(height: Dimensions.height30 * 2),
              // Logout button
              GestureDetector(
                onTap: () {
                  Get.defaultDialog(
                    title: 'Cerrar sesion',
                    middleText: 'Seguro que deseas cerrar sesion?',
                    textCancel: 'Cancelar',
                    textConfirm: 'Cerrar sesion',
                    confirmTextColor: Colors.white,
                    buttonColor: AppColors.mainColor,
                    cancelTextColor: AppColors.mainBlackColor,
                    onConfirm: () {
                      authController.logout();
                      Get.offAllNamed(RouteHelper.getLogin());
                    },
                  );
                },
                child: Container(
                  width: Dimensions.screenWidth * 0.5,
                  height: Dimensions.screenHeight / 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radius30),
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Cerrar sesion',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: Dimensions.font20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.height30),
            ],
          ),
        );
      }),
    );
  }

  Widget _profileRow(IconData icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimensions.width20,
        vertical: Dimensions.height10 * 0.6,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.width20,
        vertical: Dimensions.height15,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Dimensions.radius15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mainColor, size: Dimensions.iconSize24),
          SizedBox(width: Dimensions.width15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: Dimensions.font16,
                color: AppColors.mainBlackColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
