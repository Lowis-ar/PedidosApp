import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/order_controller.dart';
import 'package:pedidosapp/controllers/review_controller.dart';
import 'package:pedidosapp/models/order_model.dart';
import 'package:pedidosapp/utils/colors.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/shimmer_widgets.dart';
import 'package:pedidosapp/widgets/small_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders({bool force = false}) async {
    final orderCtrl = Get.find<OrderController>();
    if (force || orderCtrl.orderList.isEmpty) {
      await orderCtrl.getOrderList();
    }

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: SizedBox(
            height: 40.0,
            child: Image.asset(
              'assets/image/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.mainColor,
            labelColor: AppColors.mainColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Activos"),
              Tab(text: "Historial"),
            ],
          ),
        ),
        body: GetBuilder<OrderController>(builder: (orderController) {
          if (orderController.isLoading) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(3, (_) => const OrderCardSkeleton()),
            );
          }

          return TabBarView(
            children: [
              _buildOrderList(orderController.activeOrderList, orderController, isActive: true),
              _buildOrderList(orderController.historyOrderList, orderController, isActive: false),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, OrderController orderController, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            BigText(text: "Sin pedidos", color: Colors.grey, size: 20),
            const SizedBox(height: 8),
            SmallText(text: "Tus pedidos aparecerán aquí", color: Colors.grey),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(force: true),
      color: AppColors.mainColor,
      child: Obx(() {
        final reviewCtrl = Get.isRegistered<ReviewController>()
            ? Get.find<ReviewController>()
            : null;
        // Siempre acceder al observable para que Obx pueda rastrearlo,
        // independientemente de la condición `isActive`.
        final pendingCount = reviewCtrl?.pendingReviews.length ?? 0;
        final pendingReviews = reviewCtrl?.pendingReviews ?? <OrderModel>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isActive && pendingCount > 0) ...[
              _PendingReviewsBanner(
                pendingOrders: pendingReviews,
                onTap: (order) => _openReviewPage(order),
              ),
              const SizedBox(height: 12),
            ],

            ...orders.map((order) => _buildOrderCard(order, orderController)),
          ],
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
                    BigText(text: "Detalle de Pedido", size: 16),
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
          // ── Desglose completo (Estilo Original + Detalles Extra) ────
          if (order.details != null && order.details!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Detalle del pedido',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items
                  ...order.details!.map((detail) {
                    final unitPrice =
                        double.tryParse(detail.price ?? '0') ?? 0.0;
                    final qty = detail.quantity ?? 1;
                    final lineTotal = double.tryParse(detail.totalPrice ?? '') ?? (unitPrice * qty);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Qty badge
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Center(
                              child: Text('$qty',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mainColor)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Name + details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(detail.name ?? 'Producto',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87)),
                                    ),
                                    Text(
                                      '\$${lineTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${unitPrice.toStringAsFixed(2)} c/u',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                                if (detail.variantName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '• ${detail.variantName}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    ),
                                  ),
                                if (detail.extras != null && detail.extras!.isNotEmpty)
                                  ...detail.extras!.map((extra) {
                                    final extraQty = extra.quantity ?? 1;
                                    final extraPriceVal = double.tryParse(extra.price ?? '') ?? 0.0;
                                    final priceInfo = extraPriceVal > 0 
                                        ? ' (+\$${extraPriceVal.toStringAsFixed(2)} c/u)' 
                                        : '';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '+$extraQty ${extra.name ?? ''}$priceInfo',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Divider
                  Divider(color: Colors.grey.shade300, height: 16),

                  // Subtotal de productos, Envío, Total
                  Builder(builder: (_) {
                    final double productsSubtotal = double.tryParse(order.subtotal ?? '') ?? 
                        order.details!.fold<double>(0.0,
                            (double sum, d) =>
                                sum +
                                (double.tryParse(d.totalPrice ?? '') ??
                                    ((double.tryParse(d.price ?? '0') ?? 0.0) * (d.quantity ?? 1))));
                    
                    double deliveryFeeVal =
                        double.tryParse(order.deliveryFee ?? '') ?? 0.0;

                    final zoneLabel = order.zoneName != null
                        ? 'Envío (${order.zoneName})'
                        : 'Envío';

                    return Column(
                      children: [
                        _breakdownRow('Subtotal productos',
                            '\$${productsSubtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _breakdownRow(zoneLabel,
                            '\$${deliveryFeeVal.toStringAsFixed(2)}'),
                        if ((double.tryParse(order.discountAmount ?? '0') ?? 0.0) > 0) ...[
                          const SizedBox(height: 4),
                          _breakdownRow('Descuento Cupón',
                              '-\$${(double.tryParse(order.discountAmount ?? '0') ?? 0.0).toStringAsFixed(2)}',
                              color: Colors.green),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.mainBlackColor)),
                            Text('\$${order.orderAmount}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.mainColor)),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),


          // ── Action buttons ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Review button
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
                if (order.orderStatus == 'pending') ...[
                  if (needsReview) const SizedBox(width: 8),
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
                ],

                // OTP badge
                if (order.otp != null &&
                    (order.orderStatus == 'pending' ||
                        order.orderStatus == 'confirmed' ||
                        order.orderStatus == 'preparing' ||
                        order.orderStatus == 'ready_to_go' ||
                        order.orderStatus == 'assigned' ||
                        order.orderStatus == 'accepted' ||
                        order.orderStatus == 'on_way' ||
                        order.orderStatus == 'on_the_way')) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showOtpDialog(order.otp!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.mainColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin, size: 14, color: AppColors.mainColor),
                          const SizedBox(width: 4),
                          Text('Ver PIN',
                              style: TextStyle(
                                  color: AppColors.mainColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper para filas de desglose (subtotal, envío)
  Widget _breakdownRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87)),
      ],
    );
  }

  /// Muestra el código OTP en un diálogo grande con QR y permite copiarlo
  void _showOtpDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_open_rounded,
                      color: AppColors.mainColor, size: 48),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Código de Entrega',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Muéstrale el QR o el código al repartidor',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(
                      data: otp,
                      version: QrVersions.auto,
                      size: 180,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            "No se pudo cargar el QR",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        );
                      },
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.mainColor,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Código numérico (toca para copiar)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: otp));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El código PIN fue copiado al portapapeles'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.mainColor, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          otp,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                            letterSpacing: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy_rounded, color: AppColors.mainColor, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toca el código para copiarlo',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cerrar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
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
