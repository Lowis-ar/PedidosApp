import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/models/delivery_order_model.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';
import 'qr_scanner_page.dart';

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
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
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
              
              const SizedBox(height: 20),

              // 3. Payment Method Section
              _buildSectionTitle("FORMA DE PAGO:"),
              _buildPaymentMethodCard(order.paymentMethod),

              const SizedBox(height: 30),

              // 4. Action Buttons
              if (order.orderStatus == 'accepted')
                _actionButton(
                  "MARCAR EN CAMINO",
                  AppColors.mainColor,
                  () {
                    HapticFeedback.lightImpact();
                    controller.markAsOnWay(order.id!);
                  },
                ),
              
              if (order.orderStatus == 'on_the_way' || order.orderStatus == 'picked_up')
                _actionButton(
                  "ENTREGAR PEDIDO (OTP)",
                  Colors.green,
                  () {
                    HapticFeedback.lightImpact();
                    _showOTPDialog(context, controller);
                  },
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

  Widget _buildPaymentMethodCard(String? paymentMethod) {
    final bool isCash = paymentMethod == null ||
        paymentMethod == 'cash_on_delivery' ||
        paymentMethod == 'cash';
    final Color bgColor = isCash ? Colors.green.shade50 : Colors.blue.shade50;
    final Color borderColor =
        isCash ? Colors.green.shade300 : Colors.blue.shade300;
    final Color iconColor = isCash ? Colors.green.shade700 : Colors.blue.shade700;
    final IconData icon = isCash ? Icons.payments_outlined : Icons.credit_card;
    final String label = isCash ? 'Contra Entrega (Efectivo)' : 'Tarjeta de Crédito/Débito';
    final String subtitle = isCash
        ? 'El cliente pagará en efectivo al recibir'
        : 'El cliente ya pagó con tarjeta';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: iconColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: iconColor.withValues(alpha: 0.8))),
              ],
            ),
          ),
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const BigText(text: "Código PIN de Entrega"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SmallText(text: "Pide al cliente su código de 4 dígitos", color: Colors.grey),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 10),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "0000",
                        hintStyle: TextStyle(color: Colors.grey.shade300),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botón escanear QR
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final String? scanned = await Get.to(
                        () => const QRScannerPage(),
                        fullscreenDialog: true,
                      );
                      if (scanned != null && scanned.isNotEmpty) {
                        otpController.text = scanned;
                      }
                    },
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final String? errorMsg =
                    await controller.verifyDeliveryOtp(order.id!, otpController.text);
                if (errorMsg == null) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Cerrar diálogo
                  }
                  Get.back(); // Volver al dashboard
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("VERIFICAR"),
            ),
          ],
        );
      },
    );
  }

}
