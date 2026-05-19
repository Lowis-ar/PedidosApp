import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/models/delivery_order_model.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

class ActiveOrdersView extends StatelessWidget {
  const ActiveOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeliveryOrderController>(builder: (controller) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: RefreshIndicator(
          onRefresh: () => controller.getOrders(),
          color: AppColors.mainColor,
          child: controller.isLoading && controller.activeOrdersList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.activeOrdersList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.activeOrdersList.length,
                      itemBuilder: (context, index) {
                        return _buildActiveOrderCard(controller.activeOrdersList[index]);
                      },
                    ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return ListView( // Usamos ListView para que el RefreshIndicator funcione
      children: [
        SizedBox(height: Get.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const BigText(text: "No tienes pedidos en curso", color: Colors.grey),
              const SizedBox(height: 8),
              SmallText(text: "Los pedidos aceptados aparecerán aquí", color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOrderCard(DeliveryOrderModel order) {
    bool isOnWay = order.orderStatus == 'on_way';
    Color statusColor = isOnWay ? AppColors.mainColor : Colors.orange;
    String statusLabel = isOnWay ? 'En Camino' : 'Asignado';

    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getDeliveryOrderDetail(), arguments: order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BigText(text: "Pedido #${order.id}", size: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person_outline, "Cliente", order.customer?.name ?? "N/A"),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, "Entrega", order.deliveryAddress ?? "N/A"),
                  const Divider(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(RouteHelper.getDeliveryOrderDetail(), arguments: order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("VER DETALLES", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallText(text: label, color: Colors.grey, size: 12),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
