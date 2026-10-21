import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../cart/domain/cart.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  String _paymentMethod = 'cod';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _name.text = user?.fullName ?? '';
    _email.text = user?.email ?? '';
    _phone.text = user?.phone ?? '';
    _address.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _checkout(Cart cart) async {
    if (!_formKey.currentState!.validate() || !cart.canCheckout) return;

    setState(() => _submitting = true);
    try {
      final order = await ref.read(orderRepositoryProvider).checkout(
        customerName: _name.text.trim(),
        customerEmail: _email.text.trim(),
        customerPhone: _phone.text.trim(),
        shippingAddress: _address.text.trim(),
        paymentMethod: _paymentMethod,
        note: _note.text.trim(),
      );
      ref.invalidate(cartProvider);

      if (!mounted) return;
      context.go('/order-success', extra: order);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Không được để trống' : null;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Thanh toán'),
        leading: IconButton(
          onPressed: () => context.go('/cart'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Không thể tải giỏ hàng.\n$error')),
        data: (value) {
          if (value.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Giỏ hàng trống — quay lại mua sắm'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 800;
                    final form = _buildForm();
                    final summary = _buildSummary(value);
                    return compact
                        ? Column(children: [form, const SizedBox(height: 20), summary])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: form),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: summary),
                            ],
                          );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Thông tin giao hàng', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 22),
            TextFormField(controller: _name, validator: _required, decoration: const InputDecoration(labelText: 'Họ và tên')),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@') ? 'Email không hợp lệ' : null,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (value) => (value?.trim().length ?? 0) < 8 ? 'Số điện thoại không hợp lệ' : null,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Vui lòng nhập địa chỉ đầy đủ' : null,
              decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _note, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)')),
            const SizedBox(height: 28),
            const Text('Phương thức thanh toán', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'cod',
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    subtitle: const Text('Thanh toán tiền mặt khi đơn hàng được giao tới.'),
                    secondary: const Icon(Icons.local_shipping_outlined),
                  ),
                  RadioListTile<String>(
                    value: 'bank_transfer',
                    title: const Text('Chuyển khoản ngân hàng'),
                    subtitle: const Text('Dùng mã đơn hàng làm nội dung chuyển khoản.'),
                    secondary: const Icon(Icons.account_balance_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Cart cart) {
    final shipping = cart.subtotal >= 10000000 ? 0.0 : 30000.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Đơn hàng của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: Text('${item.name} × ${item.quantity}')),
                  Text(_money.format(item.lineTotal)),
                ],
              ),
            ),
          const Divider(height: 28),
          _CheckoutLine(label: 'Tạm tính', value: _money.format(cart.subtotal)),
          const SizedBox(height: 10),
          _CheckoutLine(label: 'Phí giao hàng', value: shipping == 0 ? 'Miễn phí' : _money.format(shipping)),
          const Divider(height: 28),
          _CheckoutLine(label: 'Tổng thanh toán', value: _money.format(cart.subtotal + shipping), strong: true),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _submitting ? null : () => _checkout(cart),
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_outline),
            label: Text(_submitting ? 'Đang tạo đơn...' : 'Đặt hàng'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF0066CC),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Thông tin của bạn được bảo vệ và chỉ dùng để xử lý đơn hàng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w400))),
      Text(value, style: TextStyle(fontSize: strong ? 18 : 14, fontWeight: strong ? FontWeight.w900 : FontWeight.w500)),
    ],
  );
}
