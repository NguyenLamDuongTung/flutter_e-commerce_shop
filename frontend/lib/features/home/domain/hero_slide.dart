class HeroSlide {
  const HeroSlide({
    required this.id,
    required this.productId,
    required this.productSlug,
    required this.productName,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    required this.displayOrder,
    required this.isActive,
  });

  final int id;
  final int productId;
  final String productSlug;
  final String productName;
  final String title;
  final String subtitle;
  final String buttonText;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productSlug: json['productSlug']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? 'Khám phá ngay',
      imageUrl: json['imageUrl']?.toString(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }
}

class HeroSlideInput {
  const HeroSlideInput({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.displayOrder,
    required this.isActive,
  });

  final int productId;
  final String title;
  final String subtitle;
  final String buttonText;
  final int displayOrder;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}
