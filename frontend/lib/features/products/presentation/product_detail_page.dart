import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../domain/product.dart';

final productDetailsProvider = FutureProvider.autoDispose
    .family<Product, String>((ref, slug) {
      return ref.watch(productRepositoryProvider).getProduct(slug);
    });

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;
  int _selectedImage = 0;
  bool _adding = false;

  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.slug != widget.slug) {
      _quantity = 1;
      _selectedImage = 0;
    }
  }

  Future<void> _addToCart(Product product) async {
    if (_adding || product.stockQuantity < 1) return;

    final user = ref.read(authControllerProvider).value;

    if (user == null) {
      final from = '/products/${Uri.encodeComponent(product.slug)}';

      context.go(
        Uri(path: '/login', queryParameters: {'from': from}).toString(),
      );
      return;
    }

    final quantity = _quantity;
    setState(() => _adding = true);

    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(product.id, quantity: quantity);

      ref.invalidate(cartProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $quantity sản phẩm vào giỏ hàng.'),
          action: SnackBarAction(
            label: 'Xem giỏ',
            onPressed: () {
              if (mounted) context.go('/cart');
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể thêm vào giỏ: $error')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Widget _gallery(Product product) {
    final images = product.images
        .map((image) => image.imageUrl)
        .where((url) => url.trim().isNotEmpty)
        .toList();

    final primary = product.primaryImageUrl;

    if (images.isEmpty && primary != null && primary.isNotEmpty) {
      images.add(primary);
    }

    final selected = images.isEmpty
        ? 0
        : _selectedImage.clamp(0, images.length - 1).toInt();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: images.isEmpty
                ? const Icon(Icons.devices, size: 100, color: Colors.black26)
                : CachedNetworkImage(
                    imageUrl: AppConfig.resolveImageUrl(images[selected]),
                    fit: BoxFit.contain,
                    placeholder: (_, _) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined, size: 80),
                  ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => InkWell(
                onTap: () => setState(() => _selectedImage = index),
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == index
                          ? const Color(0xFF0066CC)
                          : Colors.black12,
                      width: selected == index ? 2 : 1,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: AppConfig.resolveImageUrl(images[index]),
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _information(Product product) {
    final available = product.stockQuantity > 0 && product.isActive;
    final maxQuantity = product.stockQuantity.clamp(0, 99).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.categoryName,
          style: const TextStyle(
            color: Color(0xFF0066CC),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _money.format(product.price),
              style: const TextStyle(
                fontSize: 28,
                color: Color(0xFF0066CC),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.hasDiscount)
              Text(
                _money.format(product.comparePrice),
                style: const TextStyle(
                  color: Colors.black45,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          available ? 'Còn ${product.stockQuantity} sản phẩm' : 'Tạm hết hàng',
          style: TextStyle(
            color: available ? Colors.green.shade700 : Colors.red,
          ),
        ),
        if ((product.shortDescription ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            product.shortDescription!,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Số lượng'),
            const SizedBox(width: 16),
            IconButton(
              onPressed: !_adding && _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$_quantity',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: !_adding && available && _quantity < maxQuantity
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: available && !_adding ? () => _addToCart(product) : null,
          icon: _adding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_shopping_cart),
          label: Text(
            _adding
                ? 'Đang thêm...'
                : available
                ? 'Thêm vào giỏ hàng'
                : 'Tạm hết hàng',
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go('/cart'),
          child: const Text('Mở giỏ hàng'),
        ),
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 14),
        const Text(
          'Thông tin sản phẩm',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SelectableText(
          (product.description ?? '').trim().isEmpty
              ? 'Thông tin đang được cập nhật.'
              : product.description!,
          style: const TextStyle(height: 1.7),
        ),
        if (product.specifications.isNotEmpty) ...[
          const SizedBox(height: 26),
          const Text(
            'Thông số kỹ thuật',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final entry in product.specifications.entries)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: SelectableText('${entry.value}')),
                ],
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(productDetailsProvider(widget.slug));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('NOVA • Chi tiết sản phẩm'),
        leading: IconButton(
          tooltip: 'Trang chủ',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 14),
                Text(
                  'Không tải được sản phẩm.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(productDetailsProvider(widget.slug)),
                  child: const Text('Thử lại'),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
              ],
            ),
          ),
        ),
        data: (product) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        _gallery(product),
                        const SizedBox(height: 28),
                        _information(product),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _gallery(product)),
                      const SizedBox(width: 40),
                      Expanded(child: _information(product)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
