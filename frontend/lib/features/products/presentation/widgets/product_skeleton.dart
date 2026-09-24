import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE4E5E7),
      highlightColor: const Color(0xFFF8F8F8),
      child: Container(
        height: 410,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 18, color: Colors.white),
            const SizedBox(height: 10),
            Container(width: 150, height: 18, color: Colors.white),
            const Spacer(),
            Container(width: 120, height: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
