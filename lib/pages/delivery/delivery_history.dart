import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/delivery_order_controller.dart';
import '../../utils/colors.dart';
import '../../widgets/big_text.dart';
import '../../widgets/small_text.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Forzar la carga de datos al entrar a la pantalla
    Get.find<DeliveryOrderController>().getHistory();
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
          return Column(
            children: [
              // Earnings Summary
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.mainColor.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _earningsItem("Total Ganancias", "\$${controller.totalEarnings}"),
                    _earningsItem("Hoy", "\$${controller.todayEarnings}"),
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
