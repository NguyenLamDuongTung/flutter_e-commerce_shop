import '../../../core/network/api_client.dart';
import '../domain/cart.dart';

class CartRepository {
  const CartRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Cart> getCart() async {
    final response = await _apiClient.get('/cart', authenticated: true);
    return Cart.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<Cart> addItem(int productId, {int quantity = 1}) async {
    final response = await _apiClient.post(
      '/cart/items',
      authenticated: true,
      body: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<Cart> updateItem(int productId, int quantity) async {
    final response = await _apiClient.put(
      '/cart/items/$productId',
      authenticated: true,
      body: {'quantity': quantity},
    );
    return Cart.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<Cart> removeItem(int productId) async {
    final response = await _apiClient.delete(
      '/cart/items/$productId',
      authenticated: true,
    );
    return Cart.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }
}
