import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/delivery_auth_controller.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../widgets/big_text.dart';
import '../../widgets/small_text.dart';

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
              
              const SizedBox(height: 40),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context, auth),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("EDITAR PERFIL", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallText(text: label, color: Colors.grey),
              BigText(text: value, size: 16),
            ],
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
        title: const BigText(text: "Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Teléfono")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => auth.updateProfile(nameController.text, phoneController.text),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
