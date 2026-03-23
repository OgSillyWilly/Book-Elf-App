import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int rating;
  final bool editable;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.editable = false,
    this.onRatingChanged,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.orange;
    final inactive = inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isActive = starNumber <= rating;

        return editable
            ? InkWell(
                onTap: () => onRatingChanged?.call(starNumber),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isActive ? Icons.star : Icons.star_border,
                    color: isActive ? active : inactive,
                    size: size,
                  ),
                ),
              )
            : Icon(
                isActive ? Icons.star : Icons.star_border,
                color: isActive ? active : inactive,
                size: size,
              );
      }),
    );
  }
}
