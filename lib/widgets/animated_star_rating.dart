import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Animated 5-star rating widget.
/// [onRatingChanged] is called every time the user selects a star.
class AnimatedStarRating extends StatefulWidget {
  final int initialRating;
  final double starSize;
  final ValueChanged<int>? onRatingChanged;
  final bool readOnly;

  const AnimatedStarRating({
    super.key,
    this.initialRating = 0,
    this.starSize = 36,
    this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  State<AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<AnimatedStarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _setRating(int value) {
    if (widget.readOnly) return;
    setState(() => _rating = value);
    widget.onRatingChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= _rating;
        return GestureDetector(
          onTap: () => _setRating(starValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedScale(
              scale: isFilled ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: widget.starSize,
                color: isFilled ? AppColors.yellowColor : Colors.grey.shade300,
              ),
            ),
          ),
        );
      }),
    );
  }
}
