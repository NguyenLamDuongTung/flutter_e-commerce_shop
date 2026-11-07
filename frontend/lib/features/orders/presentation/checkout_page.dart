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
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();

  String _paymentMethod = 'bank_transfer';
  bool _submitting = false;

  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

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
    if (_submitting || !cart.canCheckout) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .checkout(
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo đơn hàng: $error')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _panel(Widget child) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  Widget _buildForm() {
    return _panel(
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              enabled: !_submitting,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 2) {
                  return 'Vui lòng nhập họ và tên';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: !_submitting,
              maxLength: 190,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Email không hợp lệ';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !_submitting,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';

                if (!RegExp(r'^\+?[0-9 ()-]{8,30}$').hasMatch(phone)) {
                  return 'Số điện thoại không hợp lệ';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              enabled: !_submitting,
              maxLength: 500,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 10) {
                  return 'Vui lòng nhập địa chỉ đầy đủ';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              enabled: !_submitting,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Chuyển khoản ngân hàng / QR'),
                ),
                DropdownMenuItem(
                  value: 'cod',
                  child: Text('Thanh toán khi nhận hàng (COD)'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() => _paymentMethod = value);
                    },
            ),
            const SizedBox(height: 12),
            Text(
              _paymentMethod == 'bank_transfer'
                  ? 'QR Vietcombank và nội dung chuyển khoản sẽ xuất hiện '
                        'trên hóa đơn sau khi bạn nhấn Thanh toán.'
                  : 'Thanh toán cho nhân viên giao hàng khi nhận hàng.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      fontSize: strong ? 18 : 15,
      fontWeight: strong ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style)),
        ],
      ),
    );
  }

  Widget _buildSummary(Cart cart) {
    // Matches the existing backend shipping rule.
    final shipping = cart.subtotal >= 10000000 ? 0.0 : 30000.0;

    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đơn hàng của bạn',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          for (final item in cart.items)
            _summaryLine(
              '${item.name} × ${item.quantity}',
              _money.format(item.lineTotal),
            ),
          const Divider(height: 28),
          _summaryLine('Tạm tính', _money.format(cart.subtotal)),
          _summaryLine(
            'Phí giao hàng',
            shipping == 0 ? 'Miễn phí' : _money.format(shipping),
          ),
          const Divider(height: 28),
          _summaryLine(
            'Tổng thanh toán',
            _money.format(cart.subtotal + shipping),
            strong: true,
          ),
          const SizedBox(height: 20),
          if (!cart.canCheckout)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Một số sản phẩm không đủ tồn kho. '
                'Vui lòng quay lại giỏ hàng để điều chỉnh.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          FilledButton.icon(
            onPressed: _submitting || !cart.canCheckout
                ? null
                : () => _checkout(cart),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.receipt_long_outlined),
            label: Text(_submitting ? 'Đang tạo hóa đơn...' : 'Thanh toán'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        leading: IconButton(
          onPressed: _submitting ? null : () => context.go('/cart'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không thể tải giỏ hàng.\n$error',
                textAlign: TextAlign.center,
              ),
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
              child: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Giỏ hàng trống — tiếp tục mua sắm'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final form = _buildForm();
                    final summary = _buildSummary(value);

                    if (constraints.maxWidth < 850) {
                      return Column(
                        children: [form, const SizedBox(height: 20), summary],
                      );
                    }

                    return Row(
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
}
