import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/models/delivery_order_model.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

class ActiveOrdersView extends StatelessWidget {
  const ActiveOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeliveryOrderController>(builder: (controller) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: RefreshIndicator(
          onRefresh: () => controller.getOrders(),
          color: AppColors.mainColor,
          child: controller.isLoading && controller.activeOrdersList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.activeOrdersError && controller.activeOrdersList.isEmpty
                  ? _buildErrorState(controller)
                  : controller.activeOrdersList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.activeOrdersList.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(
                                context, controller.activeOrdersList[index], controller);
                          },
                        ),
        ),
      );
    });
  }

  Widget _buildOrderCard(
      BuildContext context, DeliveryOrderModel order, DeliveryOrderController controller) {
    final bool isAssigned =
        order.orderStatus == 'assigned' || order.orderStatus == 'accepted';
    final Color badgeColor = isAssigned ? const Color(0xFFF59E0B) : Colors.blue;
    final String statusLabel = isAssigned ? 'Asignado' : 'En Camino';

    // Construir dirección completa con referencias
    final String fullAddress = [
      order.deliveryAddress,
      if (order.addressReferences != null && order.addressReferences!.isNotEmpty)
        order.addressReferences,
    ].whereType<String>().join(' — ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Cabecera: ID y Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BigText(text: 'Pedido #${order.id}', size: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          // Información del cliente, dirección y montos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.person, 'Cliente', order.customer?.name ?? 'N/A'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoRow(Icons.location_on, 'Entrega',
                          fullAddress.isNotEmpty ? fullAddress : 'Sin dirección'),
                    ),
                    if (order.customer?.lat != null && order.customer?.lng != null)
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.blueAccent),
                        onPressed: () async {
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=${order.customer!.lat},${order.customer!.lng}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        tooltip: 'Ver en Mapa',
                      ),
                  ],
                ),
                if (order.customer?.phone != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _infoRow(Icons.phone, 'Teléfono', order.customer!.phone!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () async {
                          final url = 'tel:${order.customer!.phone!}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                        tooltip: 'Llamar',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Fila de montos
                Row(
                  children: [
                    Expanded(
                      child: _amountBadge(
                        label: 'Total pedido',
                        amount: order.total != null
                            ? '\$${order.total!.toStringAsFixed(2)}'
                            : 'N/A',
                        color: Colors.grey.shade700,
                        bgColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _amountBadge(
                        label: 'Tu ganancia',
                        amount: '\$${order.deliveryFee?.toStringAsFixed(2) ?? '0.00'}',
                        color: Colors.green.shade700,
                        bgColor: Colors.green.shade50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Acciones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: isAssigned
                  ? ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () => controller.markAsOnWay(order.id!),
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('SALIR A ENTREGAR',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _showOTPModal(context, order, controller),
                      icon: const Icon(Icons.verified),
                      label: const Text('CONFIRMAR ENTREGA',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  void _showOTPModal(
      BuildContext context, DeliveryOrderModel order, DeliveryOrderController controller) {
    final TextEditingController otpInput = TextEditingController();
    // Variable observable para el error dentro del modal
    final RxString otpError = ''.obs;
    final RxBool isSubmitting = false.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      Obx(() => Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.lock_open_rounded, size: 40, color: Colors.green),
                const SizedBox(height: 12),
                const BigText(text: 'Confirmar Entrega'),
                const SizedBox(height: 6),
                SmallText(
                    text: 'Pide al cliente su código de confirmación de 4 dígitos',
                    color: Colors.grey),
                const SizedBox(height: 24),
                // Campo OTP
                TextField(
                  controller: otpInput,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onChanged: (_) => otpError.value = '',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 16),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '0000',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade300, letterSpacing: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: otpError.value.isNotEmpty
                              ? Colors.red
                              : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: otpError.value.isNotEmpty
                              ? Colors.red
                              : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: otpError.value.isNotEmpty
                              ? Colors.red
                              : AppColors.mainColor,
                          width: 2),
                    ),
                  ),
                ),
                // Error inline debajo del input
                if (otpError.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            otpError.value,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting.value
                        ? null
                        : () async {
                            if (otpInput.text.length < 4) {
                              otpError.value = 'Ingresa el código de al menos 4 dígitos';
                              return;
                            }
                            isSubmitting.value = true;
                            otpError.value = '';
                            final String? errorMsg = await controller
                                .verifyDeliveryOtp(order.id!, otpInput.text);
                            isSubmitting.value = false;
                            if (errorMsg == null) {
                              Get.back(); // Cierra modal solo en éxito
                              controller.getOrders(); // Refresh after modal is closed
                            } else {
                              // Error inline — NO cierra el modal
                              otpError.value = errorMsg;
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppColors.mainColor.withValues(alpha: 0.5),
                    ),
                    child: isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('CONFIRMAR',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          )),
    );
  }

  Widget _amountBadge({
    required String label,
    required String amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text(amount,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: Get.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const BigText(text: 'No tienes pedidos en curso', color: Colors.grey),
              SmallText(text: 'Jala hacia abajo para refrescar', color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(DeliveryOrderController controller) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: Get.height * 0.18),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red.shade400),
                ),
                const SizedBox(height: 20),
                const BigText(text: 'Error de conexión', size: 20),
                const SizedBox(height: 8),
                Text(
                  'No fue posible actualizar tus pedidos en curso. Por favor, verifica tu cobertura de red.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.getOrders(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
