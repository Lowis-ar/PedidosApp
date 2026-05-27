import 'package:flutter/material.dart';
import '../utils/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Base shimmer animation widget
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 0.5, 0),
              end: Alignment(_anim.value + 0.5, 0),
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF5F5F5),
                Color(0xFFEBEBEB),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public helper – create a single shimmer block
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Skeleton for popular-product card (PageView slider)
// ─────────────────────────────────────────────────────────────────────────────
class PopularProductSkeleton extends StatelessWidget {
  const PopularProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.82;
    return Container(
      width: w,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // Image placeholder
          ShimmerBlock(
            width: w,
            height: 200,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(height: 10),
          // Card info placeholder
          Container(
            width: w,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: w * 0.6, height: 16),
                const SizedBox(height: 8),
                ShimmerBlock(width: w * 0.4, height: 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBlock(width: 60, height: 10),
                    const SizedBox(width: 12),
                    ShimmerBlock(width: 60, height: 10),
                    const SizedBox(width: 12),
                    ShimmerBlock(width: 60, height: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Skeleton for recommended-product list row
// ─────────────────────────────────────────────────────────────────────────────
class RecommendedProductSkeleton extends StatelessWidget {
  const RecommendedProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          ShimmerBlock(
            width: 110,
            height: 110,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ShimmerBlock(width: w * 0.35, height: 14),
                  ShimmerBlock(width: w * 0.2, height: 10),
                  Row(
                    children: [
                      ShimmerBlock(width: 50, height: 10),
                      const SizedBox(width: 8),
                      ShimmerBlock(width: 50, height: 10),
                      const SizedBox(width: 8),
                      ShimmerBlock(width: 50, height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Skeleton for order history card
// ─────────────────────────────────────────────────────────────────────────────
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(width: w * 0.35, height: 14),
              ShimmerBlock(
                width: 90,
                height: 26,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShimmerBlock(width: w * 0.6, height: 12),
          const SizedBox(height: 8),
          ShimmerBlock(width: w * 0.4, height: 12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(width: 100, height: 14),
              ShimmerBlock(
                width: 80,
                height: 30,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Skeleton for cart items list
// ─────────────────────────────────────────────────────────────────────────────
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ShimmerBlock(
            width: 90,
            height: 90,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 140, height: 14),
                const SizedBox(height: 8),
                ShimmerBlock(width: 80, height: 10),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBlock(width: 60, height: 14),
                    ShimmerBlock(
                      width: 90,
                      height: 32,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Full-page loading overlay (for auth/submit actions)
// ─────────────────────────────────────────────────────────────────────────────
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? label;
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.mainColor,
                          strokeWidth: 3.5,
                        ),
                      ),
                      if (label != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          label!,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Inline centered spinner (for sections within a page)
// ─────────────────────────────────────────────────────────────────────────────
class AppSpinner extends StatelessWidget {
  final double size;
  const AppSpinner({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: AppColors.mainColor,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
