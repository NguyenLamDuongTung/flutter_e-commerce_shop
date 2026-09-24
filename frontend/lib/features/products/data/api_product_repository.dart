import '../../../core/network/api_client.dart';
import '../domain/product.dart';

class ApiProductRepository {
  const ApiProductRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ProductCategory>> getCategories() async {
    final response = await _apiClient.get('/products/categories');

    final items = response['data'] as List<dynamic>? ?? [];

    return items
        .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> getProducts({
    String? category,
    String search = '',
    bool? featured,
    int limit = 12,
  }) async {
    final query = <String, dynamic>{
      'page': 1,
      'limit': limit,
      'sort': 'newest',
    };

    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (featured != null) {
      query['featured'] = featured;
    }

    final response = await _apiClient.get('/products', queryParameters: query);

    final data = response['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String slug) async {
    final response = await _apiClient.get('/products/$slug');

    return Product.fromJson(response['data'] as Map<String, dynamic>);
  }
}
