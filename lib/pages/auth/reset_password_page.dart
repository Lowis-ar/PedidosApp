import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
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
              SizedBox(height: Dimensions.height20),
              Text(
                'Ingresar Codigo',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBlackColor,
                ),
              ),
              SizedBox(height: Dimensions.height10),
              Text(
                'Hemos enviado un codigo de 6 digitos a ${widget.email}. Ingresalo para establecer tu nueva contrasena.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font16,
                  color: AppColors.paraColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: Dimensions.height30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(Dimensions.radius30),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: "",
                    prefixIcon: Icon(Icons.pin_outlined, color: AppColors.mainColor),
                    hintText: 'Codigo de 6 digitos',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: Dimensions.height15,
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.height20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(Dimensions.radius30),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.mainColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.mainColor,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    hintText: 'Nueva contrasena',
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
                          final otp = _otpController.text.trim();
                          final pass = _passwordController.text.trim();
                          if (otp.length != 6 || pass.isEmpty) {
                            Get.snackbar('Aviso', 'Ingresa el codigo valido y la contrasena',
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                            return;
                          }
                          bool success = await authController.resetPassword(widget.email, otp, pass);
                          if (success) {
                            Get.offAllNamed(RouteHelper.getLogin());
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
                              'Restablecer Contrasena',
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
