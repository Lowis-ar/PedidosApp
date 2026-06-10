import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../utils/app_snackbar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.mainBlackColor),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.height30),
              Text(
                'Recuperar Contrasena',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBlackColor,
                ),
              ),
              SizedBox(height: Dimensions.height10),
              Text(
                'Ingresa tu correo electronico asociado a tu cuenta. Te enviaremos un codigo OTP de 6 digitos para restablecer tu contrasena.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font16,
                  color: AppColors.paraColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: Dimensions.height30 * 1.5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(Dimensions.radius30),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.mainColor),
                    hintText: 'Correo electronico',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: Dimensions.height15,
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.height30 * 2),
              GetBuilder<AuthController>(builder: (authController) {
                return GestureDetector(
                  onTap: authController.isLoading
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          final email = _emailController.text.trim();
                          if (email.isEmpty) {
                            AppSnackbar.warning('Aviso', 'Ingresa tu correo');
                            return;
                          }
                          bool success = await authController.forgotPassword(email);
                          if (success) {
                            Get.toNamed(RouteHelper.getResetPassword(email));
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.maxFinite,
                    height: Dimensions.screenHeight / 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radius30),
                      color: AppColors.mainColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mainColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: authController.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Enviar Codigo',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: Dimensions.font20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
