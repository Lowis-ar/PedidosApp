import 'package:flutter/material.dart';

class CartAnimationHelper {
  static void runAddToCartAnimation({
    required BuildContext context,
    required GlobalKey fromKey,
    required GlobalKey toKey,
    required Widget child,
    VoidCallback? onComplete,
  }) {
    final RenderBox? fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? toBox = toKey.currentContext?.findRenderObject() as RenderBox?;

    if (fromBox == null || toBox == null) {
      if (onComplete != null) onComplete();
      return;
    }

    final Offset startOffset = fromBox.localToGlobal(Offset.zero) +
        Offset(fromBox.size.width / 2, fromBox.size.height / 2);
    final Offset endOffset = toBox.localToGlobal(Offset.zero) +
        Offset(toBox.size.width / 2, toBox.size.height / 2);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return _FlyAnimationWidget(
          startOffset: startOffset,
          endOffset: endOffset,
          child: child,
          onComplete: () {
            overlayEntry.remove();
            if (onComplete != null) onComplete();
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

class _FlyAnimationWidget extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final Widget child;
  final VoidCallback onComplete;

  const _FlyAnimationWidget({
    required this.startOffset,
    required this.endOffset,
    required this.child,
    required this.onComplete,
  });

  @override
  State<_FlyAnimationWidget> createState() => _FlyAnimationWidgetState();
}

class _FlyAnimationWidgetState extends State<_FlyAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuad,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double t = _animation.value;

        // Curved path interpolation (parabolic arc)
        final double x = widget.startOffset.dx + (widget.endOffset.dx - widget.startOffset.dx) * t;
        final double yBase = widget.startOffset.dy + (widget.endOffset.dy - widget.startOffset.dy) * t;

        // Peak height of the arc (curves up first, then falls into the cart)
        const double arcHeight = 160.0;
        final double arc = 4 * arcHeight * t * (1 - t);
        final double y = yBase - arc;

        // Scale down from 1.0 to 0.2
        final double scale = 1.0 - 0.8 * t;

        // Opacity transition (quick fade-in, fade-out near the end)
        double opacity = 1.0;
        if (t < 0.1) {
          opacity = t / 0.1;
        } else if (t > 0.8) {
          opacity = (1.0 - t) / 0.2;
        }

        return Positioned(
          left: x - 20, // Centering adjustments
          top: y - 20,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
