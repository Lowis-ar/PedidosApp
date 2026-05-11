import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/delivery_auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

class DeliveryLoginPage extends StatefulWidget {
  const DeliveryLoginPage({super.key});

  @override
  State<DeliveryLoginPage> createState() => _DeliveryLoginPageState();
}

class _DeliveryLoginPageState extends State<DeliveryLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: Dimensions.screenHeight * 0.1),
            // Logo
            SizedBox(
              height: Dimensions.screenHeight * 0.15,
              child: Image.asset('assets/image/logo.png', fit: BoxFit.contain),
            ),
            SizedBox(height: Dimensions.height20),
            Text(
              'Panel de Repartidor',
              style: TextStyle(
                fontSize: Dimensions.font26,
                fontWeight: FontWeight.bold,
                color: AppColors.mainColor,
              ),
            ),
            SizedBox(height: Dimensions.height10),
            Text(
              'Inicia sesión para comenzar a entregar',
              style: TextStyle(fontSize: Dimensions.font16, color: Colors.grey),
            ),
            SizedBox(height: Dimensions.height45),
            _buildTextField(
              controller: _emailController,
              hint: 'Correo corporativo',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: Dimensions.height20),
            _buildTextField(
              controller: _passwordController,
              hint: 'Contraseña',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.mainColor,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            SizedBox(height: Dimensions.height45),
            GetBuilder<DeliveryAuthController>(builder: (authController) {
              return GestureDetector(
                onTap: authController.isLoading
                    ? null
                    : () async {
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();
                        if (email.isEmpty || password.isEmpty) {
                          Get.snackbar('Campos requeridos', 'Ingresa tus credenciales');
                          return;
                        }
                        await authController.login(email, password);
                        if (authController.isLoggedIn) {
                          Get.offAllNamed(RouteHelper.getDeliveryDashboard());
                        }
                      },
                child: Container(
                  width: Dimensions.screenWidth * 0.7,
                  height: Dimensions.screenHeight / 13,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radius30),
                    color: AppColors.mainColor,
                  ),
                  child: Center(
                    child: authController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              );
            }),
            SizedBox(height: Dimensions.height20),
            TextButton(
              onPressed: () => Get.offAllNamed(RouteHelper.getLogin()),
              child: Text(
                '¿No eres repartidor? Inicia como cliente',
                style: TextStyle(color: Colors.grey, fontSize: Dimensions.font16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radius30),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.mainColor),
            suffixIcon: suffixIcon,
            hintText: hint,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: Dimensions.height15, horizontal: Dimensions.width20),
          ),
        ),
      ),
    );
  }
}
