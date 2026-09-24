import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onPressed,
  });

  final Product product;
  final VoidCallback onPressed;

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConfig.resolveImageUrl(product.primaryImage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.devices_rounded,
                            size: 90,
                            color: Colors.black26,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 180),
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 60,
                            ),
                          ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        _money.format(product.price),
                        style: const TextStyle(
                          color: Color(0xFF0066CC),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.hasDiscount)
                        Text(
                          _money.format(product.comparePrice),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (product.hasDiscount)
              Positioned(
                left: 0,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFED1B24),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Giảm ${product.discountPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 10,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF45A928)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '● Mới',
                  style: TextStyle(
                    color: Color(0xFF45A928),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
