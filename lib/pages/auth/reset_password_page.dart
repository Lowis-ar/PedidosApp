import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../utils/app_snackbar.dart';

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

  double _passwordStrength = 0.0;
  String _strengthText = '';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final text = _passwordController.text;
    double strength = 0.0;
    if (text.isNotEmpty) {
      if (text.length >= 8) strength += 0.25;
      if (text.contains(RegExp(r'[a-z]'))) strength += 0.25;
      if (text.contains(RegExp(r'[A-Z]'))) strength += 0.25;
      if (text.contains(RegExp(r'[0-9]')) || text.contains(RegExp(r'[!@#\$&*~]'))) strength += 0.25;
    }
    
    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) {
        _strengthText = 'Débil';
        _strengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _strengthText = 'Media';
        _strengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _strengthText = 'Buena';
        _strengthColor = Colors.blue;
      } else {
        _strengthText = 'Fuerte';
        _strengthColor = Colors.green;
      }
    });
  }

  void _handleReset() async {
    final authController = Get.find<AuthController>();
    if (authController.isLoading) return;

    HapticFeedback.lightImpact();
    final otp = _otpController.text.trim();
    final pass = _passwordController.text.trim();
    if (otp.length != 6 || pass.isEmpty) {
      AppSnackbar.warning('Aviso', 'Ingresa el código válido y la contraseña');
      return;
    }
    bool success = await authController.resetPassword(widget.email, otp, pass);
    if (success) {
      Get.offAllNamed(RouteHelper.getLogin());
    }
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
          child: AutofillGroup(
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
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textInputAction: TextInputAction.next,
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
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleReset(),
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
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _passwordStrength,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _strengthText,
                              style: TextStyle(
                                color: _strengthColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mínimo 8 caracteres, números, mayúsculas y minúsculas.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: Dimensions.height30 * 2),
                GetBuilder<AuthController>(builder: (authController) {
                  return GestureDetector(
                    onTap: authController.isLoading ? null : _handleReset,
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
    ),
  );
  }
}
