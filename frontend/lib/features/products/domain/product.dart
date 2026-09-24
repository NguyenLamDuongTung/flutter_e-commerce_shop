class ProductImage {
  const ProductImage({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    this.altText,
    this.displayOrder = 0,
  });

  final int id;
  final String imageUrl;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: (json['id'] as num).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      altText: json['altText']?.toString(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isPrimary: json['isPrimary'] == true || json['isPrimary'] == 1,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.name,
    required this.slug,
    required this.price,
    required this.stockQuantity,
    required this.featured,
    required this.isActive,
    required this.images,
    this.shortDescription,
    this.description,
    this.comparePrice,
    this.primaryImage,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final String categorySlug;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? comparePrice;
  final int stockQuantity;
  final bool featured;
  final bool isActive;
  final List<ProductImage> images;
  final String? primaryImage;

  bool get hasDiscount => comparePrice != null && comparePrice! > price;

  int get discountPercent {
    if (!hasDiscount) {
      return 0;
    }

    return (((comparePrice! - price) / comparePrice!) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? [];

    return Product(
      id: (json['id'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      categoryName: json['categoryName']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString(),
      description: json['description']?.toString(),
      price: (json['price'] as num).toDouble(),
      comparePrice: json['comparePrice'] == null
          ? null
          : (json['comparePrice'] as num).toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      featured: json['featured'] == true,
      isActive: json['isActive'] != false,
      images: rawImages
          .map((item) => ProductImage.fromJson(item as Map<String, dynamic>))
          .toList(),
      primaryImage: json['primaryImage']?.toString(),
    );
  }
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.productCount,
  });

  final int id;
  final String name;
  final String slug;
  final int productCount;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}
