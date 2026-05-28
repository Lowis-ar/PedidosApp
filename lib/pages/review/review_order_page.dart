import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/review_controller.dart';
import '../../models/order_model.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../widgets/animated_star_rating.dart';

/// Full-screen review page shown after a delivered order.
/// Products and deliveryman ratings are all optional.
class ReviewOrderPage extends StatefulWidget {
  final OrderModel order;

  const ReviewOrderPage({super.key, required this.order});

  @override
  State<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends State<ReviewOrderPage> {
  // productId → { rating, comment }
  late Map<int, Map<String, dynamic>> _productRatings;

  // Deliveryman rating
  int _deliveryRating = 0;
  final _deliveryCommentCtrl = TextEditingController();

  late final ReviewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ReviewController>();

    // Initialize ratings map
    _productRatings = {};
    for (final detail in widget.order.details ?? []) {
      if (detail.productId != null) {
        _productRatings[detail.productId!] = {'rating': 0, 'comment': null};
      }
    }
  }

  @override
  void dispose() {
    _deliveryCommentCtrl.dispose();
    super.dispose();
  }

  void _submitOrNext() async {
    if (widget.order.deliveryman != null) {
      Get.offNamed(
        RouteHelper.getReviewDelivery(),
        arguments: {
          'order': widget.order,
          'productRatings': _productRatings,
        },
      );
    } else {
      final success = await _ctrl.submitReview(
        orderId: widget.order.id!,
        productRatings: _productRatings,
        deliverymanRating: null,
      );
      if (success && mounted) {
        // Cerrar todo el flujo de reseñas y volver al inicio
        Get.until((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.order.details ?? [];
    final deliveryman = widget.order.deliveryman;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Calificar pedido',
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
                const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                const SizedBox(height: 6),
                const Text(
                  '¿Cómo estuvo tu pedido?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tus opiniones son opcionales y nos ayudan a mejorar.',
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
                // Products section
                if (details.isNotEmpty) ...[
                  _sectionTitle('Productos'),
                  const SizedBox(height: 10),
                  ...details.map((detail) => _ProductReviewCard(
                        detail: detail,
                        onRatingChanged: (r) {
                          if (detail.productId != null) {
                            setState(() {
                              _productRatings[detail.productId!]!['rating'] = r;
                            });
                          }
                        },
                        onCommentChanged: (c) {
                          if (detail.productId != null) {
                            _productRatings[detail.productId!]!['comment'] =
                                c.trim().isEmpty ? null : c.trim();
                          }
                        },
                      )),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 10),
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
                    onPressed: () {
                      if (deliveryman != null) {
                        Get.offNamed(
                          RouteHelper.getReviewDelivery(),
                          arguments: {
                            'order': widget.order,
                            'productRatings': <int, Map<String, dynamic>>{}, // empty ratings
                          },
                        );
                      } else {
                        Get.back();
                      }
                    },
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
                      onPressed: ctrl.isSubmitting ? null : _submitOrNext,
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
                          : Text(
                              deliveryman != null ? 'Siguiente' : 'Enviar reseñas',
                              style: const TextStyle(
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

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: Dimensions.font20,
            fontWeight: FontWeight.bold,
            color: AppColors.mainBlackColor,
          ),
        ),
      ],
    );
  }
}

// ── Product review card ──────────────────────────────────────────────────────

class _ProductReviewCard extends StatefulWidget {
  final OrderDetail detail;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onCommentChanged;

  const _ProductReviewCard({
    required this.detail,
    required this.onRatingChanged,
    required this.onCommentChanged,
  });

  @override
  State<_ProductReviewCard> createState() => _ProductReviewCardState();
}

class _ProductReviewCardState extends State<_ProductReviewCard> {
  bool _expanded = false;
  int _rating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _rating > 0 ? AppColors.mainColor.withValues(alpha: 0.4) : Colors.grey.shade200,
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product row
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.detail.img != null
                      ? Image.network(
                          widget.detail.img!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.detail.name ?? 'Producto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.mainBlackColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${widget.detail.quantity ?? 1}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stars
            Center(
              child: AnimatedStarRating(
                initialRating: _rating,
                starSize: 34,
                onRatingChanged: (r) {
                  setState(() {
                    _rating = r;
                    _expanded = true;
                  });
                  widget.onRatingChanged(r);
                },
              ),
            ),

            // Expandable comment field
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _commentCtrl,
                  maxLines: 2,
                  maxLength: 300,
                  onChanged: widget.onCommentChanged,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario (opcional)...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.mainColor.withValues(alpha: 0.1),
      child: Icon(Icons.fastfood_rounded,
          color: AppColors.mainColor, size: 30),
    );
  }
}

// ── Deliveryman review card ──────────────────────────────────────────────────

class _DeliverymanReviewCard extends StatelessWidget {
  final OrderDeliveryman deliveryman;
  final TextEditingController commentController;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _DeliverymanReviewCard({
    required this.deliveryman,
    required this.commentController,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rating > 0 ? AppColors.mainColor.withValues(alpha: 0.4) : Colors.grey.shade200,
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
            initialRating: rating,
            starSize: 36,
            onRatingChanged: onRatingChanged,
          ),
          const SizedBox(height: 14),

          // Comment
          TextField(
            controller: commentController,
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
    );
  }
}
