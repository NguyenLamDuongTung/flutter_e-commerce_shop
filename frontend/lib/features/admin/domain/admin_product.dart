class AdminProductImage {
  const AdminProductImage({
    required this.id,
    required this.imageUrl,
    required this.altText,
    required this.displayOrder,
    required this.isPrimary,
  });

  final int id;
  final String imageUrl;
  final String altText;
  final int displayOrder;
  final bool isPrimary;

  factory AdminProductImage.fromJson(Map<String, dynamic> json) {
    return AdminProductImage(
      id: _toInt(json['id']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      altText: json['altText']?.toString() ?? '',
      displayOrder: _toInt(json['displayOrder']),
      isPrimary: _toBool(json['isPrimary']),
    );
  }
}

class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.name,
    required this.slug,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.comparePrice,
    required this.stockQuantity,
    required this.featured,
    required this.isActive,
    required this.specifications,
    required this.images,
    required this.primaryImage,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final String categorySlug;

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
  final List<AdminProductImage> images;
  final String? primaryImage;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isInStock => stockQuantity > 0;

  bool get hasDiscount {
    return comparePrice != null && comparePrice! > price;
  }

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];

    final images = rawImages is List
        ? rawImages
            .whereType<Map>()
            .map(
              (item) => AdminProductImage.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <AdminProductImage>[];

    return AdminProduct(
      id: _toInt(json['id']),
      categoryId: _toInt(json['categoryId']),
      categoryName: json['categoryName']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      comparePrice: json['comparePrice'] == null
          ? null
          : _toDouble(json['comparePrice']),
      stockQuantity: _toInt(json['stockQuantity']),
      featured: _toBool(json['featured']),
      isActive: _toBool(json['isActive']),
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : <String, dynamic>{},
      images: images,
      primaryImage: json['primaryImage']?.toString(),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }
}

class AdminProductPage {
  const AdminProductPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final List<AdminProduct> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  bool get hasPreviousPage => page > 1;

  bool get hasNextPage => page < totalPages;

  factory AdminProductPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => AdminProduct.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <AdminProduct>[];

    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : <String, dynamic>{};

    return AdminProductPage(
      items: items,
      page: _toInt(pagination['page'], fallback: 1),
      limit: _toInt(pagination['limit'], fallback: 20),
      totalItems: _toInt(pagination['totalItems']),
      totalPages: _toInt(pagination['totalPages']),
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().toLowerCase();

  return normalized == 'true' || normalized == '1';
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}