import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2F38) : Colors.grey.shade300;
    final highlightColor =
        isDark ? const Color(0xFF3A414C) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: baseColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _bar(borderRadius: 16)),
            const SizedBox(height: 14),
            _bar(height: 18),
            const SizedBox(height: 9),
            FractionallySizedBox(
              widthFactor: .68,
              child: _bar(height: 18),
            ),
            const SizedBox(height: 14),
            FractionallySizedBox(
              widthFactor: .48,
              child: _bar(height: 21),
            ),
            const SizedBox(height: 9),
            FractionallySizedBox(
              widthFactor: .6,
              child: _bar(height: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({double? height, double borderRadius = 8}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
