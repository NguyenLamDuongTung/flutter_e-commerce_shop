import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/admin_product.dart';

typedef ProductUpload = ({String name, List<int> bytes});

class AdminProductInput {
  const AdminProductInput({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.stockQuantity,
    required this.featured,
    required this.isActive,
    this.specifications = const {},
  });

  final int categoryId;
  final String name;
  final String slug;
  final String shortDescription;
  final String description;
  final double price;
  final double? comparePrice;
  final int stockQuantity;
  final bool featured;
  final bool isActive;
  final Map<String, dynamic> specifications;

  Map<String, String> toFields() => {
    'categoryId': '$categoryId',
    'name': name,
    'slug': slug,
    'shortDescription': shortDescription,
    'description': description,
    'price': '$price',
    'comparePrice': comparePrice == null ? '' : '$comparePrice',
    'stockQuantity': '$stockQuantity',
    'featured': '$featured',
    'isActive': '$isActive',
    'specifications': jsonEncode(specifications),
  };
}

class AdminProductRepository {
  const AdminProductRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<AdminProductPage> getProducts({
    int page = 1,
    String search = '',
    String status = 'all',
  }) async {
    final response = await _apiClient.get(
      '/admin/products',
      authenticated: true,
      queryParameters: {
        'page': page,
        'limit': 20,
        'search': search,
        'status': status,
      },
    );
    return AdminProductPage.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<AdminProduct> save({
    int? id,
    required AdminProductInput input,
    List<ProductUpload> images = const [],
  }) async {
    final response = await _apiClient.multipart(
      id == null ? '/admin/products' : '/admin/products/$id',
      method: id == null ? 'POST' : 'PUT',
      fields: input.toFields(),
      files: images,
    );
    return AdminProduct.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    await _apiClient.patch(
      '/admin/products/$id/status',
      authenticated: true,
      body: {'isActive': isActive},
    );
  }

  Future<void> deleteProduct(int id) async {
    await _apiClient.delete('/admin/products/$id', authenticated: true);
  }
}
