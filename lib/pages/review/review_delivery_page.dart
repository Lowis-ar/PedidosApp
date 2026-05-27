import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/review_controller.dart';
import '../../models/order_model.dart';
import '../../utils/colors.dart';
import '../../widgets/animated_star_rating.dart';

class ReviewDeliveryPage extends StatefulWidget {
  const ReviewDeliveryPage({super.key});

  @override
  State<ReviewDeliveryPage> createState() => _ReviewDeliveryPageState();
}

class _ReviewDeliveryPageState extends State<ReviewDeliveryPage> {
  late OrderModel _order;
  late Map<int, Map<String, dynamic>> _productRatings;

  int _deliveryRating = 0;
  final _deliveryCommentCtrl = TextEditingController();
  late final ReviewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ReviewController>();

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _order = args['order'] as OrderModel;
    _productRatings = args['productRatings'] as Map<int, Map<String, dynamic>>? ?? {};
  }

  @override
  void dispose() {
    _deliveryCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(bool skipDelivery) async {
    final success = await _ctrl.submitReview(
      orderId: _order.id!,
      productRatings: _productRatings,
      deliverymanRating: skipDelivery
          ? null
          : {
              'rating': _deliveryRating,
              'comment': _deliveryCommentCtrl.text.trim().isEmpty ? null : _deliveryCommentCtrl.text.trim()
            },
    );
    if (success && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryman = _order.deliveryman;

    if (deliveryman == null) {
      // Fallback si por alguna razón entra sin repartidor
      return Scaffold(
        body: Center(
          child: Text('Sin repartidor asignado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Calificar repartidor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.mainColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.amber, size: 40),
                const SizedBox(height: 6),
                const Text(
                  '¿Cómo fue la entrega?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ayúdanos a mejorar evaluando a tu repartidor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _deliveryRating > 0 ? AppColors.mainColor.withValues(alpha: 0.4) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Deliveryman info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.mainColor.withValues(alpha: 0.15),
                            backgroundImage: deliveryman.photo != null
                                ? NetworkImage(deliveryman.photo!)
                                : null,
                            child: deliveryman.photo == null
                                ? Icon(Icons.delivery_dining,
                                    color: AppColors.mainColor, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deliveryman.name ?? 'Repartidor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.mainBlackColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tu repartidor',
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stars
                      AnimatedStarRating(
                        initialRating: _deliveryRating,
                        starSize: 36,
                        onRatingChanged: (r) => setState(() => _deliveryRating = r),
                      ),
                      const SizedBox(height: 14),

                      // Comment
                      TextField(
                        controller: _deliveryCommentCtrl,
                        maxLines: 2,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: '¿Algo que destacar del repartidor? (opcional)',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.mainColor, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed bottom bar ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Skip button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Omitir',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit button
                Expanded(
                  flex: 2,
                  child: GetBuilder<ReviewController>(
                    builder: (ctrl) => ElevatedButton(
                      onPressed: ctrl.isSubmitting ? null : () => _submit(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: ctrl.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Enviar reseñas',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                    ),
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
