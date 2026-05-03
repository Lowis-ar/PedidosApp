import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
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
    _phoneController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                SizedBox(height: Dimensions.screenHeight * 0.06),
                // Logo
                SizedBox(
                  height: Dimensions.screenHeight * 0.15,
                  child: Image.asset('assets/image/logo.png', fit: BoxFit.contain),
                ),
                SizedBox(height: Dimensions.height20),
                // Email
                _buildTextField(
                  controller: _emailController,
                  hint: 'Correo electronico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: Dimensions.height15),
                // Password
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
                SizedBox(height: Dimensions.height15),
                // Phone
                _buildTextField(
                  controller: _phoneController,
                  hint: 'Telefono',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: Dimensions.height15),
                // Name
                _buildTextField(
                  controller: _nameController,
                  hint: 'Nombre',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: Dimensions.height30 * 1.2),
                // Register button
                GetBuilder<AuthController>(builder: (authController) {
                  return GestureDetector(
                    onTap: authController.isLoading
                        ? null
                        : () async {
                            final email = _emailController.text.trim();
                            final pass = _passwordController.text.trim();
                            final phone = _phoneController.text.trim();
                            final name = _nameController.text.trim();
                            if (email.isEmpty || pass.isEmpty || phone.isEmpty || name.isEmpty) {
                              Get.snackbar(
                                'Campos requeridos',
                                'Todos los campos son obligatorios',
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                              );
                              return;
                            }
                            await authController.register(name, phone, email, pass);
                            if (authController.isLoggedIn) {
                              Get.offAllNamed(RouteHelper.getInitial());
                            }
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
                                'Sign up',
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
                SizedBox(height: Dimensions.height20),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ya tienes una cuenta? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: Dimensions.font16,
                        color: AppColors.paraColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Inicia sesion',
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
                SizedBox(height: Dimensions.height30),
                // Social media section
                Text(
                  'Registrate con alguno de los siguientes',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: Dimensions.font16 * 0.85,
                    color: AppColors.paraColor,
                  ),
                ),
                SizedBox(height: Dimensions.height15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(Icons.g_mobiledata_rounded, const Color(0xFFDB4437)),
                    SizedBox(width: Dimensions.width20),
                    _socialIcon(Icons.flutter_dash, const Color(0xFF1DA1F2)),
                    SizedBox(width: Dimensions.width20),
                    _socialIcon(Icons.facebook_rounded, const Color(0xFF4267B2)),
                  ],
                ),
                SizedBox(height: Dimensions.height30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
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
