import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _copy(BuildContext context, String label, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể sao chép tự động.')),
      );
    }
  }

  Widget _copyRow(
    BuildContext context,
    String label,
    String value, {
    String? copyValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sao chép $label',
            onPressed: () => _copy(context, label, copyValue ?? value),
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = order;

    if (value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hóa đơn')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không có dữ liệu hóa đơn trong phiên này.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Quay lại cửa hàng'),
              ),
            ],
          ),
        ),
      );
    }

    final bankTransfer = value.paymentMethod == 'bank_transfer';
    final paid = value.paymentStatus == 'paid';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn đặt hàng'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'NOVA',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'HÓA ĐƠN ĐẶT HÀNG',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _copyRow(context, 'Mã đơn hàng', value.orderNumber),
                    const Divider(height: 28),
                    Text(
                      'Thông tin khách hàng',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(value.customerName),
                    SelectableText(value.customerPhone),
                    SelectableText(value.customerEmail),
                    SelectableText(value.shippingAddress),
                    if ((value.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Ghi chú: ${value.note}'),
                    ],
                    const Divider(height: 28),
                    Text('Sản phẩm', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final item in value.items)
                      _line(
                        '${item.productName} × ${item.quantity}',
                        _money.format(item.lineTotal),
                      ),
                    const Divider(height: 28),
                    _line('Tạm tính', _money.format(value.subtotal)),
                    _line(
                      'Phí giao hàng',
                      value.shippingFee == 0
                          ? 'Miễn phí'
                          : _money.format(value.shippingFee),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tổng thanh toán: '
                      '${_money.format(value.totalAmount)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 32),
                    if (bankTransfer) ...[
                      Text(
                        paid ? 'Đã thanh toán' : 'Quét QR để chuyển khoản',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (!paid) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Quét bằng ứng dụng ngân hàng. Nếu đang dùng '
                          'điện thoại, lưu ảnh QR và chọn từ thư viện ảnh '
                          'trong ứng dụng ngân hàng.',
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Image.asset(
                              'assets/images/bank_qr.jpeg',
                              fit: BoxFit.contain,
                              semanticLabel: 'QR Vietcombank',
                              errorBuilder: (_, _, _) => const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Không tải được QR. Vui lòng chuyển '
                                  'khoản bằng thông tin bên dưới.',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Ngân hàng: Vietcombank'),
                        const SizedBox(height: 8),
                        const SelectableText(
                          'Chủ tài khoản: NGUYEN LAM DUONG TUNG',
                        ),
                        _copyRow(context, 'Số tài khoản', '1031326798'),
                        _copyRow(
                          context,
                          'Số tiền chuyển khoản',
                          _money.format(value.totalAmount),
                          copyValue: value.totalAmount.toStringAsFixed(0),
                        ),
                        _copyRow(
                          context,
                          'Nội dung chuyển khoản',
                          value.orderNumber,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'QR tài khoản cố định: vui lòng nhập đúng '
                          'số tiền và mã đơn hàng ở trên.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Trạng thái: Chờ xác nhận thanh toán.\n'
                          'Cửa hàng sẽ kiểm tra giao dịch và xác nhận '
                          'sau khi nhận được tiền.',
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Thanh toán khi nhận hàng (COD)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn thanh toán cho nhân viên giao hàng '
                        'khi nhận hàng.',
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Tiếp tục mua sắm'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
