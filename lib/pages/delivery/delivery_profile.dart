import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

class DeliveryProfilePage extends StatelessWidget {
  const DeliveryProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const BigText(text: "Mi Perfil"),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: GetBuilder<DeliveryAuthController>(builder: (auth) {
        if (auth.deliveryman == null) return const Center(child: CircularProgressIndicator());
        
        var dm = auth.deliveryman!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar & Rating
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.mainColor.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 50, color: AppColors.mainColor),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  BigText(text: "${dm.averageRating} (${dm.totalReviews})", size: 18),
                ],
              ),
              const SizedBox(height: 30),

              // Info Cards
              _infoTile(Icons.person, "Nombre", dm.name ?? ""),
              _infoTile(Icons.email, "Correo", dm.email ?? ""),
              _infoTile(Icons.phone, "Teléfono", dm.phone ?? ""),
              _infoTile(Icons.directions_bike, "Vehículo", "${dm.vehicleType ?? 'N/A'} - ${dm.licensePlate ?? 'N/A'}"),
              
              const SizedBox(height: 20),

              // Edit profile button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context, auth),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("EDITAR PERFIL", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Change password button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, auth),
                  icon: Icon(Icons.lock_outline, color: AppColors.mainColor),
                  label: Text("CAMBIAR CONTRASEÑA", style: TextStyle(color: AppColors.mainColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: AppColors.mainColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    auth.logout();
                    Get.offAllNamed(RouteHelper.getLogin());
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmallText(text: label, color: Colors.grey),
                BigText(text: value, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DeliveryAuthController auth) {
    final nameController = TextEditingController(text: auth.deliveryman?.name);
    final phoneController = TextEditingController(text: auth.deliveryman?.phone);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const BigText(text: "Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Teléfono",
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
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => auth.updateProfile(nameController.text, phoneController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, DeliveryAuthController auth) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const BigText(text: "Cambiar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña actual",
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
                labelText: "Nueva contraseña",
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
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (currentPassController.text.isEmpty || newPassController.text.isEmpty) {
                Get.snackbar('Error', 'Todos los campos son obligatorios',
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                return;
              }
              Get.back();
              // Use the delivery auth repo for password change
              try {
                final response = await auth.deliveryAuthRepo.updateProfile({
                  'current_password': currentPassController.text,
                  'new_password': newPassController.text,
                });
                if (response.statusCode == 200) {
                  Get.snackbar('Éxito', 'Contraseña actualizada',
                    backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                  Get.snackbar('Error', 'No se pudo cambiar la contraseña',
                    backgroundColor: Colors.redAccent, colorText: Colors.white);
                }
              } catch (e) {
                Get.snackbar('Error', 'Error de conexión',
                  backgroundColor: Colors.redAccent, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: const Text("Cambiar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
