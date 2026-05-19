import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';
import 'package:pedidosapp/pages/delivery/active_orders_view.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
import 'package:pedidosapp/models/delivery_order_model.dart';
import 'package:pedidosapp/routes/route_helper.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/utils/dimensions.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  
  @override
  void initState() {
    super.initState();
    _setupFCM();
    _loadData();
  }

  Future<void> _loadData() async {
    final authController = Get.find<DeliveryAuthController>();
    debugPrint("=== DASHBOARD _loadData START ===");
    debugPrint("DeliveryAuthController._token: ${authController.token.isNotEmpty ? 'SET' : 'EMPTY'}");
    debugPrint("DeliveryAuthController._deliveryman: ${authController.deliveryman != null ? 'SET' : 'NULL'}");
    
    await authController.getProfile();
    
    final dm = authController.deliveryman;
    debugPrint("After getProfile: dm=${dm?.name}, isAvailable=${dm?.isAvailable}, branchId=${dm?.branchId}");
    
    debugPrint("Calling getOrders()...");
    Get.find<DeliveryOrderController>().getOrders();
    debugPrint("=== DASHBOARD _loadData END ===");
  }

  void _setupFCM() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        bool isAvailable = Get.find<DeliveryAuthController>().deliveryman?.isAvailable ?? false;
        if (isAvailable && message.data['type'] == 'new_order') {
          Get.find<DeliveryOrderController>().showNewOrderDialog(message.data);
        }
      });
    } catch (e) {
      debugPrint("FCM initialization skipped or failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: GetBuilder<DeliveryAuthController>(builder: (auth) {
          final dm = auth.deliveryman;
          final branchId = dm?.branchId;
          String branchName = "Cargando...";
          try {
            final bc = Get.find<BranchController>();
            if (bc.isLoaded && branchId != null) {
              final match = bc.branchList.where((b) => b.id == branchId);
              branchName = match.isNotEmpty ? match.first.name : "Sucursal #$branchId";
            } else if (branchId != null) {
              branchName = "Sucursal #$branchId";
            }
          } catch (_) {}
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BigText(text: dm?.name ?? "Repartidor", size: 18),
              SmallText(text: branchName, size: 12, color: Colors.grey),
            ],
          );
        }),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          GetBuilder<DeliveryAuthController>(builder: (auth) {
            return Switch(
              value: auth.deliveryman?.isAvailable ?? false,
              activeTrackColor: AppColors.mainColor,
              onChanged: (val) async {
                await auth.updateAvailability(val);
                if (val) {
                  Get.find<DeliveryOrderController>().getOrders();
                }
              },
            );
          }),
          const SizedBox(width: 10),
        ],
      ),
      body: GetBuilder<DeliveryAuthController>(builder: (auth) {
        bool isAvailable = auth.deliveryman?.isAvailable ?? false;
        
        if (!isAvailable) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 100, color: Colors.grey.shade300),
                BigText(text: "Estás desconectado", color: Colors.grey),
                SmallText(text: "Conéctate para recibir pedidos", color: Colors.grey),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  indicatorColor: AppColors.mainColor,
                  labelColor: AppColors.mainColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "DISPONIBLES"),
                    Tab(text: "EN CURSO"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAvailableOrdersList(),
                    const ActiveOrdersView(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.mainColor,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Get.toNamed(RouteHelper.getDeliveryHistory());
          if (index == 2) Get.toNamed(RouteHelper.getDeliveryProfile());
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historial"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (Get.isRegistered<DeliveryOrderController>()) {
          await Get.find<DeliveryOrderController>().getOrders();
        }
      },
      child: GetBuilder<DeliveryOrderController>(builder: (orderController) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BigText(text: "Pedidos Disponibles", size: 18),
              const SizedBox(height: 10),
              if (orderController.availableOrders.isEmpty)
                SizedBox(
                  height: 200,
                  child: Center(child: SmallText(text: "No hay pedidos nuevos por ahora", size: 14)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderController.availableOrders.length,
                  itemBuilder: (context, index) {
                    return _buildAvailableOrderCard(orderController.availableOrders[index]);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActiveOrderCard(DeliveryOrderModel order) {
    String statusLabel = "En curso";
    if (order.orderStatus == 'accepted') statusLabel = "Aceptado - Ir al restaurante";
    if (order.orderStatus == 'picked_up' || order.orderStatus == 'on_the_way') statusLabel = "En camino al cliente";

    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getDeliveryOrderDetail(), arguments: order),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.mainColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radius20),
          border: Border.all(color: AppColors.mainColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.delivery_dining, size: 40, color: AppColors.mainColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigText(text: "Orden #${order.id}", size: 18),
                  SmallText(text: "${order.restaurant?.name}", color: Colors.black87, size: 14),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: SmallText(text: statusLabel.toUpperCase(), color: Colors.white, size: 10),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20, color: AppColors.mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrderCard(dynamic order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radius20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: BigText(text: "Nueva Orden #${order.id}", size: 16)),
              BigText(text: "\$${order.deliveryFee}", color: Colors.green),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.store, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: SmallText(text: order.restaurant?.name ?? "Restaurante", size: 14)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: SmallText(text: order.deliveryAddress ?? "Dirección", size: 14)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.find<DeliveryOrderController>().acceptOrder(order.id!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radius15)),
              ),
              child: const Text("ACEPTAR PEDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
