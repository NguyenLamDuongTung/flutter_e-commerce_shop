import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/order.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.order});

  final ShopOrder? order;

  static final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Quay lại cửa hàng'),
          ),
        ),
      );
    }

    final value = order!;
    final bankTransfer = value.paymentMethod == 'bank_transfer';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 680,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 78, color: Colors.green),
                const SizedBox(height: 18),
                const Text('Đặt hàng thành công', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Mã đơn hàng: ${value.orderNumber}', style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 28),
                if (bankTransfer)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB8D8FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin chuyển khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        const Text('Ngân hàng: NOVA BANK'),
                        const Text('Số tài khoản: 0123 456 789'),
                        const Text('Chủ tài khoản: CONG TY NOVA STORE'),
                        Text('Số tiền: ${_money.format(value.totalAmount)}'),
                        Text('Nội dung: ${value.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        const Text('Đơn hàng sẽ được xác nhận sau khi hệ thống nhận được thanh toán.'),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Bạn sẽ thanh toán khi nhận hàng. Chúng tôi sẽ liên hệ để xác nhận đơn hàng.',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sản phẩm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in value.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.productName} × ${item.quantity}'),
                        ),
                        Text(_money.format(item.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(child: Text('Tổng thanh toán', style: Theme.of(context).textTheme.titleMedium)),
                    Text(_money.format(value.totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0066CC))),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => context.go('/'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16)),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
