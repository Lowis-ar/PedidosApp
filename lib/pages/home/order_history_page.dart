import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/order_controller.dart';
import 'package:pedidosapp/controllers/review_controller.dart';
import 'package:pedidosapp/models/order_model.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/utils/dimensions.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

import '../review/review_order_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orderCtrl = Get.find<OrderController>();
    await orderCtrl.getOrderList();

    // Update pending reviews & maybe show floating banner
    if (Get.isRegistered<ReviewController>()) {
      final reviewCtrl = Get.find<ReviewController>();
      reviewCtrl.updatePendingReviews(orderCtrl.orderList);

      // Show banner for first pending review not yet notified
      if (reviewCtrl.pendingReviews.isNotEmpty) {
        final first = reviewCtrl.pendingReviews.first;
        reviewCtrl.maybeShowBanner(
          first,
          onReview: () => _openReviewPage(first),
        );
      }
    }
  }

  void _openReviewPage(OrderModel order) {
    Get.to(
      () => ReviewOrderPage(order: order),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: BigText(
            text: "Mis Pedidos",
            color: AppColors.mainBlackColor,
            size: Dimensions.font20),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: GetBuilder<OrderController>(builder: (orderController) {
        if (orderController.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.mainColor));
        }

        if (orderController.orderList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                BigText(text: "Sin pedidos", color: Colors.grey, size: 20),
                const SizedBox(height: 8),
                SmallText(
                    text: "Tus pedidos aparecerán aquí", color: Colors.grey),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          color: AppColors.mainColor,
          child: Obx(() {
            final pendingReviews = Get.isRegistered<ReviewController>()
                ? Get.find<ReviewController>().pendingReviews
                : <OrderModel>[].obs;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Pending Reviews Banner ──────────────────────────
                if (pendingReviews.isNotEmpty) ...[
                  _PendingReviewsBanner(
                    pendingOrders: pendingReviews,
                    onTap: (order) => _openReviewPage(order),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Order list ──────────────────────────────────────
                ...orderController.orderList
                    .map((order) => _buildOrderCard(order, orderController)),
              ],
            );
          }),
        );
      }),
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderController controller) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (order.orderStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusLabel = 'Aceptado';
        statusIcon = Icons.thumb_up;
        break;
      case 'on_the_way':
      case 'on_way':
        statusColor = AppColors.mainColor;
        statusLabel = 'En Camino';
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusLabel = 'Entregado';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
      case 'canceled':
        statusColor = Colors.red;
        statusLabel = 'Cancelado';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = order.orderStatus ?? 'Desconocido';
        statusIcon = Icons.info;
    }

    final needsReview = order.needsReview;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: needsReview
            ? Border.all(color: Colors.orange.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigText(text: "Pedido #${order.id}", size: 16),
                    const SizedBox(height: 4),
                    SmallText(
                        text: order.createdAt ?? '',
                        color: Colors.grey,
                        size: 12),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Items
          if (order.details != null && order.details!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: order.details!.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('${detail.quantity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainColor)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(detail.name ?? 'Producto',
                                style: const TextStyle(fontSize: 13))),
                        Text('\$${detail.price}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BigText(
                    text: "Total: \$${order.orderAmount}",
                    size: 16,
                    color: AppColors.mainColor),

                // ── Review button ────────────────────────────────────
                if (needsReview)
                  GestureDetector(
                    onTap: () => _openReviewPage(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.orange.shade600, size: 14),
                          const SizedBox(width: 4),
                          Text('Calificar',
                              style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // Cancel button
                if (order.orderStatus == 'pending')
                  GestureDetector(
                    onTap: () {
                      Get.defaultDialog(
                        title: 'Cancelar Pedido',
                        middleText:
                            '¿Seguro que deseas cancelar este pedido?',
                        textCancel: 'No',
                        textConfirm: 'Sí, cancelar',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.redAccent,
                        cancelTextColor: Colors.black54,
                        onConfirm: () {
                          Get.back();
                          controller.cancelOrder(order.id!);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text('Cancelar',
                          style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                // OTP badge
                if (order.otp != null &&
                    (order.orderStatus == 'pending' ||
                        order.orderStatus == 'accepted' ||
                        order.orderStatus == 'on_the_way'))
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pin, size: 14, color: AppColors.mainColor),
                        const SizedBox(width: 4),
                        Text('PIN: ${order.otp}',
                            style: TextStyle(
                                color: AppColors.mainColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Reviews Banner ────────────────────────────────────────────────────

class _PendingReviewsBanner extends StatelessWidget {
  final List<OrderModel> pendingOrders;
  final void Function(OrderModel) onTap;

  const _PendingReviewsBanner({
    required this.pendingOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendingOrders.length == 1
                      ? '¡1 pedido sin calificar!'
                      : '¡${pendingOrders.length} pedidos sin calificar!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tienes 24 h para compartir tu experiencia.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          GestureDetector(
            onTap: () => onTap(pendingOrders.first),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.orange.shade600, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
