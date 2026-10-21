import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../domain/cart.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
    int quantity,
  ) async {
    try {
      await ref.read(cartRepositoryProvider).updateItem(item.productId, quantity);
      ref.invalidate(cartProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
  ) async {
    try {
      await ref.read(cartRepositoryProvider).removeItem(item.productId);
      ref.invalidate(cartProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Không thể tải giỏ hàng.\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(cartProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (value) {
          if (value.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 84, color: Colors.black26),
                  const SizedBox(height: 18),
                  const Text(
                    'Giỏ hàng của bạn đang trống',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final products = _CartItems(
                cart: value,
                money: _money,
                onUpdate: (item, quantity) => _update(context, ref, item, quantity),
                onRemove: (item) => _remove(context, ref, item),
              );
              final summary = _CartSummary(cart: value, money: _money);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: compact
                        ? Column(
                            children: [products, const SizedBox(height: 20), summary],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: products),
                              const SizedBox(width: 24),
                              Expanded(flex: 3, child: summary),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CartItems extends StatelessWidget {
  const _CartItems({
    required this.cart,
    required this.money,
    required this.onUpdate,
    required this.onRemove,
  });

  final Cart cart;
  final NumberFormat money;
  final void Function(CartItem item, int quantity) onUpdate;
  final ValueChanged<CartItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var index = 0; index < cart.items.length; index++) ...[
            _CartItemRow(
              item: cart.items[index],
              money: money,
              onUpdate: (quantity) => onUpdate(cart.items[index], quantity),
              onRemove: () => onRemove(cart.items[index]),
            ),
            if (index < cart.items.length - 1) const Divider(height: 32),
          ],
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.money,
    required this.onUpdate,
    required this.onRemove,
  });

  final CartItem item;
  final NumberFormat money;
  final ValueChanged<int> onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConfig.resolveImageUrl(item.imageUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: imageUrl.isEmpty
              ? const Icon(Icons.devices_rounded, color: Colors.black26)
              : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                item.isAvailable
                    ? 'Còn ${item.stockQuantity} sản phẩm'
                    : 'Sản phẩm không đủ tồn kho',
                style: TextStyle(
                  color: item.isAvailable ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D1D6)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: item.quantity > 1
                              ? () => onUpdate(item.quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          onPressed: item.quantity < item.stockQuantity
                              ? () => onUpdate(item.quantity + 1)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          money.format(item.lineTotal),
          style: const TextStyle(
            color: Color(0xFF0066CC),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart, required this.money});

  final Cart cart;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final shipping = cart.subtotal >= 10000000 ? 0.0 : 30000.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          _SummaryLine(label: 'Tạm tính (${cart.itemCount} sản phẩm)', value: money.format(cart.subtotal)),
          const SizedBox(height: 12),
          _SummaryLine(
            label: 'Phí giao hàng',
            value: shipping == 0 ? 'Miễn phí' : money.format(shipping),
          ),
          const Divider(height: 32),
          _SummaryLine(
            label: 'Tổng cộng',
            value: money.format(cart.subtotal + shipping),
            emphasized: true,
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: cart.canCheckout ? () => context.go('/checkout') : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF0066CC),
            ),
            child: const Text('Tiến hành thanh toán'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 18 : 15,
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
