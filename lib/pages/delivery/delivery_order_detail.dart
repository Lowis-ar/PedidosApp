import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/delivery_order_controller.dart';
import '../../models/delivery_order_model.dart';
import '../../utils/colors.dart';
import '../../widgets/big_text.dart';
import '../../widgets/small_text.dart';

class DeliveryOrderDetailPage extends StatefulWidget {
  const DeliveryOrderDetailPage({super.key});

  @override
  State<DeliveryOrderDetailPage> createState() => _DeliveryOrderDetailPageState();
}

class _DeliveryOrderDetailPageState extends State<DeliveryOrderDetailPage> {
  late DeliveryOrderModel order;

  @override
  void initState() {
    super.initState();
    order = Get.arguments as DeliveryOrderModel;
  }

  void _openMap(String? lat, String? lng) async {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: BigText(text: "Orden #${order.id}"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GetBuilder<DeliveryOrderController>(builder: (controller) {
        // Sync order state from controller if it's the active one
        if (controller.activeOrder?.id == order.id) {
          order = controller.activeOrder!;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Restaurant Section
              _buildSectionTitle("RECOGER EN:"),
              _buildLocationCard(
                title: order.restaurant?.name ?? "Restaurante",
                address: order.restaurant?.address ?? "Dirección no disponible",
                phone: order.restaurant?.phone,
                onMap: () => _openMap(order.restaurant?.lat, order.restaurant?.lng),
              ),
              const SizedBox(height: 30),

              // 2. Customer Section
              _buildSectionTitle("ENTREGAR A:"),
              _buildLocationCard(
                title: order.customer?.name ?? "Cliente",
                address: order.deliveryAddress ?? "Dirección de entrega",
                phone: order.customer?.phone,
                onMap: () => _openMap(order.customer?.lat, order.customer?.lng),
              ),
              
              const SizedBox(height: 50),

              // 3. Action Buttons
              if (order.orderStatus == 'accepted')
                _actionButton(
                  "MARCAR EN CAMINO",
                  AppColors.mainColor,
                  () => controller.markAsOnWay(order.id!),
                ),
              
              if (order.orderStatus == 'on_the_way' || order.orderStatus == 'picked_up')
                _actionButton(
                  "ENTREGAR PEDIDO (OTP)",
                  Colors.green,
                  () => _showOTPDialog(context, controller),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SmallText(text: title, color: Colors.grey, size: 12),
    );
  }

  Widget _buildLocationCard({required String title, required String address, String? phone, required VoidCallback onMap}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BigText(text: title, size: 18),
          const SizedBox(height: 5),
          SmallText(text: address, color: Colors.black87),
          const Divider(height: 25),
          Row(
            children: [
              if (phone != null)
                IconButton(
                  onPressed: () => launchUrl(Uri.parse("tel:$phone")),
                  icon:  Icon(Icons.phone, color: AppColors.mainColor),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onMap,
                icon: const Icon(Icons.map, color: Colors.white, size: 18),
                label: const Text("NAVEGAR", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showOTPDialog(BuildContext context, DeliveryOrderController controller) {
    final otpController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const BigText(text: "Código PIN de Entrega"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             SmallText(text: "Pide al cliente su código de 4 dígitos"),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: const InputDecoration(
                counterText: "",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              bool success = await controller.verifyOtp(order.id!, otpController.text);
              if (success) {
                Get.back(); // Close dialog
                Get.back(); // Go back to dashboard
              }
            },
            child: const Text("VERIFICAR"),
          ),
        ],
      ),
    );
  }
}
