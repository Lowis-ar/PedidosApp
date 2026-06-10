import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repository/order_repo.dart';
import '../models/order_model.dart';
import 'package:pedidosapp/utils/app_snackbar.dart';

/// Controls the pending-review lifecycle.
/// - Detects orders that need a review (delivered < 24h ago, not yet reviewed).
/// - Triggers the floating banner once per order.
/// - Sends the review payload to the API.
class ReviewController extends GetxController {
  final OrderRepo orderRepo;
  ReviewController({required this.orderRepo});

  // Orders that still need a review
  final RxList<OrderModel> pendingReviews = <OrderModel>[].obs;

  // IDs of orders for which we already showed the floating banner this session
  final Set<int> _notifiedIds = {};

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Call this after loading the order list to refresh pending reviews.
  void updatePendingReviews(List<OrderModel> orders) {
    pendingReviews.assignAll(orders.where((o) => o.needsReview).toList());
  }

  /// Shows a floating banner once per order per session.
  /// [onReview] is called when the user taps "Calificar" in the banner.
  void maybeShowBanner(OrderModel order, {required VoidCallback onReview}) {
    if (_notifiedIds.contains(order.id)) return;
    _notifiedIds.add(order.id!);

    // Small delay so the page has time to render
    Future.delayed(const Duration(milliseconds: 600), () {
      Get.snackbar(
        '¡Tu pedido fue entregado! ⭐',
        '¿Cómo estuvo tu experiencia? Tu opinión nos ayuda a mejorar.',
        duration: const Duration(seconds: 6),
        isDismissible: true,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(14),
        borderRadius: 16,
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: Colors.white,
        icon: const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 28),
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // close snackbar
            onReview();
          },
          child: const Text(
            'Calificar',
            style: TextStyle(
              color: Color(0xFF4DC9BD),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }

  /// Submits the review to the backend.
  /// [productRatings] → { productId: { 'rating': int, 'comment': String? } }
  /// [deliverymanRating] → { 'rating': int, 'comment': String? } or null
  Future<bool> submitReview({
    required int orderId,
    required Map<int, Map<String, dynamic>> productRatings,
    Map<String, dynamic>? deliverymanRating,
  }) async {
    _isSubmitting = true;
    update();

    try {
      final List<Map<String, dynamic>> products = productRatings.entries
          .where((e) => (e.value['rating'] as int? ?? 0) > 0)
          .map((e) => {
                'product_id': e.key,
                'rating': e.value['rating'],
                'comment': e.value['comment'],
              })
          .toList();

      final body = <String, dynamic>{
        if (products.isNotEmpty) 'products': products,
        if (deliverymanRating != null &&
            (deliverymanRating['rating'] as int? ?? 0) > 0)
          'deliveryman': deliverymanRating,
      };

      // Skip if nothing to send
      if (body.isEmpty) return true;

      final response = await orderRepo.submitReview(orderId, body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Remove from pending list
        pendingReviews.removeWhere((o) => o.id == orderId);
        AppSnackbar.success('¡Gracias!', 'Tu reseña ha sido enviada.',
            duration: const Duration(seconds: 3));
        return true;
      } else {
        String msg = 'No se pudo enviar la reseña.';
        if (response.body != null && response.body is Map) {
          msg = response.body['message'] ?? msg;
        } else if (response.statusText != null) {
          msg = response.statusText!;
        }

        String lowerMsg = msg.toLowerCase();
        if (lowerMsg.contains('exception') || 
            lowerMsg.contains('sql') || 
            lowerMsg.contains('server') || 
            lowerMsg.contains('connection') || 
            lowerMsg.contains('timeout') ||
            lowerMsg.contains('error') && msg.contains('errno')) {
          msg = 'Ocurrió un error inesperado, intenta nuevamente.';
        }

        AppSnackbar.error('Error', msg);
        return false;
      }
    } catch (e) {
      AppSnackbar.error('Error de conexión', 'Inténtalo de nuevo.');
      return false;
    } finally {
      _isSubmitting = false;
      update();
    }
  }
}
