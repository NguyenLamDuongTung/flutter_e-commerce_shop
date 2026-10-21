import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/product.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, required this.onPressed});

  final Product product;
  final VoidCallback onPressed;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final isSoldOut = product.stockQuantity <= 0;

    return Semantics(
      button: true,
      label: 'Xem chi tiết ${product.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: .35)
                    : theme.colorScheme.outlineVariant.withValues(alpha: .55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered ? .13 : .07,
                  ),
                  blurRadius: _isHovered ? 24 : 14,
                  offset: Offset(0, _isHovered ? 10 : 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ColoredBox(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: CachedNetworkImage(
                                  imageUrl: AppConfig.resolveImageUrl(
                                    product.primaryImageUrl,
                                  ),
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) => const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (_, _, _) => Icon(
                                    Icons.image_not_supported_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 42,
                                  ),
                                ),
                              ),
                            ),
                            if (product.hasDiscount)
                              Positioned(
                                left: 10,
                                top: 10,
                                child: _Badge(
                                  label: '-${product.discountPercent.round()}%',
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: _Badge(
                                label: isSoldOut ? 'Hết hàng' : 'Mới',
                                color: isSoldOut
                                    ? theme.colorScheme.error
                                    : const Color(0xFF167D4D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            _currency.format(product.effectivePrice),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (product.hasDiscount)
                            Text(
                              _currency.format(product.comparePrice),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isSoldOut
                                ? Icons.remove_shopping_cart_outlined
                                : Icons.touch_app_outlined,
                            size: 16,
                            color: isSoldOut
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              isSoldOut
                                  ? 'Tạm hết hàng'
                                  : 'Nhấn để xem chi tiết',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSoldOut
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
