import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';
import 'package:pedidosapp/pages/delivery/active_orders_view.dart';
import 'package:pedidosapp/controllers/delivery_auth_controller.dart';
import 'package:pedidosapp/controllers/delivery_order_controller.dart';
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
    if (Get.isRegistered<DeliveryOrderController>()) {
      Get.find<DeliveryOrderController>().getOrders();
    }
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
        final type = message.data['type'] ?? '';
        final isAvailable =
            Get.find<DeliveryAuthController>().deliveryman?.isAvailable ?? false;

        debugPrint('[FCM] Mensaje recibido: type=$type');

        if (type == 'ready_to_go' || type == 'new_order_available' || type == 'ORDER_READY') {
          // Pedido listo para tomar — actualizar lista de disponibles
          if (isAvailable) {
            Get.find<DeliveryOrderController>().getOrders(showLoading: false);
            Get.snackbar(
              '¡Nuevo pedido disponible!',
              'Hay un pedido listo para ser tomado',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.delivery_dining, color: Colors.white),
            );
          }
        } else if (type == 'new_order' || type == 'assigned') {
          // Pedido asignado al repartidor
          Get.find<DeliveryOrderController>().showNewOrderDialog(message.data);
          Get.find<DeliveryOrderController>().getOrders(showLoading: false);
        } else if (type == 'on_way') {
          // Confirmación visual: pedido en camino
          Get.snackbar(
            'Pedido en camino',
            'Ya estás en camino con el pedido',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            icon: const Icon(Icons.directions_bike, color: Colors.white),
          );
          Get.find<DeliveryOrderController>().getOrders(showLoading: false);
        }
      });
    } catch (e) {
      debugPrint('[FCM] Inicialización fallida o saltada: $e');
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
        final int activeCount = orderController.activeOrdersList.length;
        final bool atLimit = activeCount >= 3;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BigText(text: "Pedidos Disponibles", size: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: atLimit ? Colors.red.shade100 : AppColors.mainColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: atLimit ? Colors.red.shade400 : AppColors.mainColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: atLimit ? Colors.red.shade600 : AppColors.mainColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En curso: $activeCount / 3',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: atLimit ? Colors.red.shade600 : AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (atLimit)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Límite alcanzado. Completa un pedido antes de aceptar otro.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (orderController.availableOrdersError)
                _buildErrorState(orderController)
              else if (orderController.availableOrders.isEmpty)
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
                    return _buildAvailableOrderCard(orderController.availableOrders[index], atLimit);
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(DeliveryOrderController controller) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 50, color: Colors.red.shade400),
          const SizedBox(height: 12),
          const BigText(text: "Error de conexión", size: 18),
          const SizedBox(height: 6),
          SmallText(
            text: "No pudimos conectar con el servidor. Revisa tu internet.",
            color: Colors.grey.shade600,
            size: 13,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => controller.getOrders(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "REINTENTAR",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvailableOrderCard(dynamic order, bool atLimit) {
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
              onPressed: atLimit
                  ? null
                  : () => Get.find<DeliveryOrderController>().acceptOrder(order.id!),
              style: ElevatedButton.styleFrom(
                backgroundColor: atLimit ? Colors.grey.shade300 : AppColors.mainColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radius15)),
              ),
              child: Text(
                atLimit ? "LÍMITE ALCANZADO" : "ACEPTAR PEDIDO",
                style: TextStyle(
                  color: atLimit ? Colors.grey.shade600 : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
