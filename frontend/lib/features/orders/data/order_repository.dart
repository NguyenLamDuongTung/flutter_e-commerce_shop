import '../../../core/network/api_client.dart';
import '../domain/order.dart';

class OrderRepository {
  const OrderRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ShopOrder> checkout({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    required String paymentMethod,
    String note = '',
  }) async {
    final response = await _apiClient.post(
      '/orders/checkout',
      authenticated: true,
      body: {
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'note': note,
      },
    );

    return ShopOrder.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
