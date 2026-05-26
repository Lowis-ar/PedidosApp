import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
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
                'Verificar Correo',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBlackColor,
                ),
              ),
              SizedBox(height: Dimensions.height10),
              Text(
                'Hemos enviado un codigo de 6 digitos a tu correo electronico para activar tu cuenta.',
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
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: "",
                    prefixIcon: Icon(Icons.verified_user_outlined, color: AppColors.mainColor),
                    hintText: 'Codigo de 6 digitos',
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
                          final otp = _otpController.text.trim();
                          if (otp.length != 6) {
                            Get.snackbar('Aviso', 'Ingresa el codigo de 6 digitos',
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                            return;
                          }
                          bool success = await authController.verifyEmail(otp);
                          if (success) {
                            Get.offAllNamed(RouteHelper.getInitial());
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
                              'Verificar',
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
