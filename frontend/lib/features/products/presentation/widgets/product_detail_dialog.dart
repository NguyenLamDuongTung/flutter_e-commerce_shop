import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/product.dart';

Future<void> showProductDetails(
  BuildContext context,
  Product product,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => ProductDetailDialog(product: product),
  );
}

class ProductDetailDialog extends ConsumerStatefulWidget {
  const ProductDetailDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends ConsumerState<ProductDetailDialog> {
  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  late Future<Product> _details;
  int _quantity = 1;
  int _selectedImage = 0;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _details = ref.read(productRepositoryProvider).getProduct(widget.product.slug);
  }

  Future<void> _addToCart(Product product) async {
    final user = ref.read(authControllerProvider).value;

    if (user == null) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go('/login?from=%2F');
      return;
    }

    setState(() => _adding = true);
    try {
      await ref.read(cartRepositoryProvider).addItem(
        product.id,
        quantity: _quantity,
      );
      ref.invalidate(cartProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $_quantity ${product.name} vào giỏ hàng.'),
          action: SnackBarAction(
            label: 'Xem giỏ',
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/cart');
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 720),
        child: FutureBuilder<Product>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                width: 720,
                height: 420,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                width: 620,
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text('Không thể tải thông tin sản phẩm.\n${snapshot.error}'),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => setState(() {
                          _details = ref
                              .read(productRepositoryProvider)
                              .getProduct(widget.product.slug);
                        }),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final product = snapshot.data!;
            final images = product.images.isEmpty
                ? <String>[
                    if ((product.primaryImage ?? '').isNotEmpty)
                      product.primaryImage!,
                  ]
                : product.images.map((image) => image.imageUrl).toList();
            final safeImageIndex = images.isEmpty
                ? 0
                : _selectedImage.clamp(0, images.length - 1).toInt();

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      final gallery = _ProductGallery(
                        images: images,
                        selectedIndex: safeImageIndex,
                        onSelected: (index) => setState(() => _selectedImage = index),
                      );
                      final information = _ProductInformation(
                        product: product,
                        money: _money,
                        quantity: _quantity,
                        adding: _adding,
                        onDecrease: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        onIncrease: _quantity < product.stockQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                        onAdd: product.stockQuantity > 0 && !_adding
                            ? () => _addToCart(product)
                            : null,
                      );

                      if (compact) {
                        return Column(
                          children: [gallery, const SizedBox(height: 28), information],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: gallery),
                          const SizedBox(width: 36),
                          Expanded(child: information),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({
    required this.images,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final imageUrl = images.isEmpty
        ? ''
        : AppConfig.resolveImageUrl(images[selectedIndex]);

    return Column(
      children: [
        Container(
          height: 390,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(18),
          ),
          child: imageUrl.isEmpty
              ? const Icon(Icons.devices_rounded, size: 120, color: Colors.black26)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 70),
                ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == selectedIndex
                          ? const Color(0xFF0066CC)
                          : const Color(0xFFE1E1E5),
                      width: index == selectedIndex ? 2 : 1,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: AppConfig.resolveImageUrl(images[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({
    required this.product,
    required this.money,
    required this.quantity,
    required this.adding,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });

  final Product product;
  final NumberFormat money;
  final int quantity;
  final bool adding;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.categoryName, style: const TextStyle(color: Color(0xFF0066CC))),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        if ((product.shortDescription ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            product.shortDescription!,
            style: const TextStyle(fontSize: 17, color: Colors.black54, height: 1.5),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              money.format(product.price),
              style: const TextStyle(
                color: Color(0xFF0066CC),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (product.hasDiscount)
              Text(
                money.format(product.comparePrice),
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 17,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              product.stockQuantity > 0 ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: product.stockQuantity > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 7),
            Text(
              product.stockQuantity > 0
                  ? 'Còn ${product.stockQuantity} sản phẩm'
                  : 'Tạm hết hàng',
            ),
          ],
        ),
        if ((product.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('Thông tin sản phẩm', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(product.description!, style: const TextStyle(height: 1.55)),
        ],
        if (product.specifications.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Thông số kỹ thuật', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final entry in product.specifications.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
                    child: Text(entry.key, style: const TextStyle(color: Colors.black54)),
                  ),
                  Expanded(child: Text('${entry.value}')),
                ],
              ),
            ),
        ],
        const SizedBox(height: 26),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D1D6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
                  SizedBox(
                    width: 34,
                    child: Text('$quantity', textAlign: TextAlign.center),
                  ),
                  IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(adding ? 'Đang thêm...' : 'Thêm vào giỏ hàng'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFF0066CC),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
