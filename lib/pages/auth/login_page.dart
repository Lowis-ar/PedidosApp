import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../widgets/shimmer_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      return AppLoadingOverlay(
        isLoading: authController.isLoading,
        label: 'Iniciando sesión...',
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
            child: Column(
              children: [
                SizedBox(height: Dimensions.screenHeight * 0.08),
                // Logo
                SizedBox(
                  height: Dimensions.screenHeight * 0.18,
                  child: Image.asset('assets/image/logo.png', fit: BoxFit.contain),
                ),
                SizedBox(height: Dimensions.height20),
                // Title
                Padding(
                  padding: EdgeInsets.only(left: Dimensions.width20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hello',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: Dimensions.font26 * 1.8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainBlackColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: Dimensions.width20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Inicia sesion en tu cuenta',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: Dimensions.font16,
                        color: AppColors.paraColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.height30 * 1.5),
                // Role Selector
                GetBuilder<AuthController>(builder: (auth) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(Dimensions.radius30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => auth.setUserType('customer'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: auth.userType == 'customer' ? AppColors.mainColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(Dimensions.radius30),
                                ),
                                child: Center(
                                  child: Text(
                                    "Cliente",
                                    style: TextStyle(
                                      color: auth.userType == 'customer' ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => auth.setUserType('delivery'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: auth.userType == 'delivery' ? AppColors.mainColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(Dimensions.radius30),
                                ),
                                child: Center(
                                  child: Text(
                                    "Repartidor",
                                    style: TextStyle(
                                      color: auth.userType == 'delivery' ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: Dimensions.height20),
                // Email field
                _buildTextField(
                  controller: _emailController,
                  hint: 'Correo electronico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: Dimensions.height20),
                // Password field
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Contrasena',
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
                SizedBox(height: Dimensions.height10),
                // Subtext & Forgot Password
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Inicia sesion en tu cuenta',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16 * 0.85,
                            color: AppColors.paraColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: Dimensions.width10),
                      GestureDetector(
                        onTap: () => Get.toNamed(RouteHelper.getForgotPassword()),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16 * 0.85,
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.height30),
                // Login button
                GetBuilder<AuthController>(builder: (authController) {
                  return GestureDetector(
                    onTap: authController.isLoading
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            final email = _emailController.text.trim();
                            final pass = _passwordController.text.trim();
                            if (email.isEmpty || pass.isEmpty) {
                              Get.snackbar('Campos requeridos', 'Ingresa correo y contrasena',
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16));
                              return;
                            }
                            await authController.login(email, pass);
                            // La redirección ahora la maneja internamente _saveSession
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: Dimensions.screenWidth * 0.5,
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
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Sign in',
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
                SizedBox(height: Dimensions.height30),
                // Register link
                if (authController.userType == 'customer')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No tienes una cuenta? ",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: Dimensions.font16,
                          color: AppColors.paraColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(RouteHelper.getRegister()),
                        child: Text(
                          'Crear',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainBlackColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (authController.userType == 'customer') ...[
                  SizedBox(height: Dimensions.height20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Dimensions.width10),
                          child: Text(
                            "o",
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: AppColors.paraColor,
                              fontSize: Dimensions.font16 * 0.9,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                      ],
                    ),
                  ),
                  SizedBox(height: Dimensions.height20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                    child: GestureDetector(
                      onTap: authController.isLoading
                          ? null
                          : () async {
                              await authController.signInWithGoogle();
                            },
                      child: Container(
                        height: Dimensions.screenHeight / 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Dimensions.radius30),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/image/google.png',
                              width: Dimensions.iconSize24,
                              height: Dimensions.iconSize24,
                            ),
                            SizedBox(width: Dimensions.width15),
                            Text(
                              "Continuar con Google",
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: Dimensions.font18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5F6368),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Dimensions.height30),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
    });
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
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(Dimensions.radius30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: 'Roboto', fontSize: Dimensions.font16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.mainColor),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textColor, fontFamily: 'Roboto'),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: Dimensions.height15,
              horizontal: Dimensions.width20,
            ),
          ),
        ),
      ),
    );
  }
}
