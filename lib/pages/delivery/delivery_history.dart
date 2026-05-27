import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<DeliveryOrderController>()) {
        final ctrl = Get.find<DeliveryOrderController>();
        // Solo volver a pedir si no hay datos o si hubo error y el usuario regresó
        if (ctrl.historyOrders.isEmpty || ctrl.historyError) {
          ctrl.getHistory();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const BigText(text: "Historial de Entregas"),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.mainColor,
            labelColor: AppColors.mainColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Completados"),
              Tab(text: "Cancelados"),
            ],
          ),
        ),
        body: GetBuilder<DeliveryOrderController>(builder: (controller) {
          // Si el historial no está disponible en el servidor, mostrar estado amigable
          if (controller.historyError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 70, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const BigText(text: "Historial no disponible", color: Colors.grey),
                    const SizedBox(height: 8),
                    SmallText(
                      text: "El historial de entregas no está disponible por ahora. Intenta más tarde.",
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => controller.getHistory(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reintentar"),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Earnings Summary
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.mainColor.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _earningsItem("Total Ganancias", "\$${controller.totalEarnings.toStringAsFixed(2)}"),
                    _earningsItem("Hoy", "\$${controller.todayEarnings.toStringAsFixed(2)}"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOrderList(controller.historyOrders.where((o) => o.orderStatus == 'delivered').toList()),
                    _buildOrderList(controller.historyOrders.where((o) => o.orderStatus == 'cancelled' || o.orderStatus == 'canceled').toList()),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _earningsItem(String label, String amount) {
    return Column(
      children: [
        SmallText(text: label, color: Colors.black54),
        BigText(text: amount, color: AppColors.mainColor, size: 24),
      ],
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(child: SmallText(text: "Sin registros"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        var order = orders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigText(text: "Orden #${order.id}", size: 16),
                    SmallText(text: order.createdAt ?? "", color: Colors.grey),
                    SmallText(text: order.deliveryAddress ?? "", color: Colors.black54),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              BigText(text: "\$${order.deliveryFee}", color: Colors.green),
            ],
          ),
        );
      },
    );
  }
}
