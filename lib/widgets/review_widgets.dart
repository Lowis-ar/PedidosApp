import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/repository/product_repo.dart';
import '../../models/product_model.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';

// ─── Review Card (horizontal carousel) ────────────────────────────────────────

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimensions.screenWidth * 0.75,
      margin: EdgeInsets.only(right: Dimensions.width15),
      padding: EdgeInsets.all(Dimensions.height10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Dimensions.radius15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.name ?? "Anónimo",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Dimensions.font16 / 1.1,
                    color: AppColors.mainBlackColor,
                  ),
                ),
              ),
              Text(
                review.date ?? "",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star,
                color: i < (review.rating?.floor() ?? 5)
                    ? AppColors.yellowColor
                    : Colors.grey.shade300,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              review.comment ?? "",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review List Item (inside modal) ──────────────────────────────────────────

class ReviewListItem extends StatelessWidget {
  final ReviewModel review;
  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.mainColor.withValues(alpha: 0.15),
              child: Text(
                (review.name?.isNotEmpty == true)
                    ? review.name![0].toUpperCase()
                    : "A",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                review.name ?? "Anónimo",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.font16,
                  color: AppColors.mainBlackColor,
                ),
              ),
            ),
            Text(
              review.date ?? "",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              Icons.star,
              color: i < (review.rating?.floor() ?? 5)
                  ? AppColors.yellowColor
                  : Colors.grey.shade300,
              size: 18,
            ),
          ),
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          "Denunciar",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Reviews Bottom Sheet Modal ────────────────────────────────────────────────

class ReviewsBottomSheet extends StatefulWidget {
  final int productId;
  const ReviewsBottomSheet({super.key, required this.productId});

  @override
  State<ReviewsBottomSheet> createState() => _ReviewsBottomSheetState();
}

class _ReviewsBottomSheetState extends State<ReviewsBottomSheet> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final repo = Get.find<ProductRepo>();
      final response =
          await repo.getProductReviews(widget.productId, perPage: 50);
      if (response.statusCode == 200 && response.body != null) {
        final body = response.body;
        List<dynamic>? list;
        if (body['data'] is Map && body['data']['data'] is List) {
          list = body['data']['data'] as List<dynamic>;
        } else if (body['data'] is List) {
          list = body['data'] as List<dynamic>;
        }
        if (mounted) {
          setState(() {
            _reviews = (list ?? []).map((e) => ReviewModel.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Opiniones",
                      style: TextStyle(
                        fontSize: Dimensions.font26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainBlackColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.mainColor))
                    : _hasError
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  "No se pudieron cargar las opiniones",
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : _reviews.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_border,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Sin opiniones aún",
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                itemCount: _reviews.length,
                                separatorBuilder: (_, i) => Divider(
                                    height: 24, color: Colors.grey.shade200),
                                itemBuilder: (_, index) => ReviewListItem(
                                    review: _reviews[index]),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
