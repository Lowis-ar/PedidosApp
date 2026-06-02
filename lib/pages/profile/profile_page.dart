import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

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
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
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
                      child: ClipOval(
                        child: authController.pickedImage != null
                            ? Image.file(
                                File(authController.pickedImage!.path),
                                width: Dimensions.screenHeight * 0.15,
                                height: Dimensions.screenHeight * 0.15,
                                fit: BoxFit.cover,
                              )
                            : (user.image != null && user.image!.isNotEmpty)
                                ? Image.network(
                                    user.image!,
                                    width: Dimensions.screenHeight * 0.15,
                                    height: Dimensions.screenHeight * 0.15,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          (user.name ?? 'U').substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: Dimensions.font26 * 2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      (user.name ?? 'U').substring(0, 1).toUpperCase(),
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          authController.pickImage();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (authController.pickedImage != null) ...[
                SizedBox(height: Dimensions.height10),
                ElevatedButton.icon(
                  onPressed: () {
                    authController.updateProfile(user.name ?? '', user.phone ?? '');
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                  label: const Text('Guardar Imagen', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
              SizedBox(height: Dimensions.height15),
              Text(
                user.name ?? '',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: Dimensions.font26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBlackColor,
                ),
              ),
              SizedBox(height: Dimensions.height30 * 1.5),
              // Info rows
              _profileRowEditable(
                Icons.person_outline,
                user.name ?? 'Sin nombre',
                'Editar Nombre',
                () => _showEditNameDialog(context, authController),
              ),
              _profileRow(Icons.email_outlined, user.email ?? 'Sin correo'),
              _profileRowEditable(
                Icons.phone_outlined,
                user.phone ?? 'Sin telefono',
                'Editar Teléfono',
                () => _showEditPhoneDialog(context, authController),
              ),

              SizedBox(height: Dimensions.height20),
              // Change password button
              GestureDetector(
                onTap: () => _showChangePasswordDialog(context, authController),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.width20,
                    vertical: Dimensions.height15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radius15),
                    border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.mainColor, size: Dimensions.iconSize24),
                      SizedBox(width: Dimensions.width15),
                      Expanded(
                        child: Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: Dimensions.font16,
                            color: AppColors.mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: AppColors.mainColor, size: 16),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Dimensions.height30),
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
                      Get.back(); // Cerramos el modal primero
                      authController.logout(); // El controlador ya se encarga de redirigir al login
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

  Widget _profileRowEditable(IconData icon, String text, String editLabel, VoidCallback onEdit) {
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
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Editar',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthController authController) {
    final nameController = TextEditingController(text: authController.user?.name);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            labelText: 'Nuevo nombre',
            prefixIcon: Icon(Icons.person, color: AppColors.mainColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.mainColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Get.back();
                authController.updateProfile(nameController.text, authController.user?.phone ?? '');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, AuthController authController) {
    final phoneController = TextEditingController(text: authController.user?.phone);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Teléfono', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Nuevo teléfono',
            prefixIcon: Icon(Icons.phone, color: AppColors.mainColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.mainColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.isNotEmpty) {
                Get.back();
                authController.updateProfile(authController.user?.name ?? '', phoneController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthController authController) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.mainColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock, color: AppColors.mainColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: Icon(Icons.lock, color: AppColors.mainColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (currentPassController.text.isEmpty || newPassController.text.isEmpty) {
                Get.snackbar('Error', 'Todos los campos son obligatorios',
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                return;
              }
              if (newPassController.text != confirmPassController.text) {
                Get.snackbar('Error', 'Las contraseñas no coinciden',
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                return;
              }
              if (newPassController.text.length < 6) {
                Get.snackbar('Error', 'La contraseña debe tener al menos 6 caracteres',
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                return;
              }
              Get.back();
              authController.changePassword(currentPassController.text, newPassController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: const Text('Cambiar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
