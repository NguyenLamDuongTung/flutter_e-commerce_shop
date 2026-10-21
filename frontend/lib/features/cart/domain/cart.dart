class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.slug,
    required this.price,
    required this.previousPrice,
    required this.quantity,
    required this.stockQuantity,
    required this.isAvailable,
    required this.lineTotal,
    this.imageUrl,
  });

  final int id;
  final int productId;
  final String name;
  final String slug;
  final String? imageUrl;
  final double price;
  final double previousPrice;
  final int quantity;
  final int stockQuantity;
  final bool isAvailable;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: (json['id'] as num).toInt(),
    productId: (json['productId'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    slug: json['slug']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString(),
    price: (json['price'] as num).toDouble(),
    previousPrice: (json['previousPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num).toInt(),
    stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    isAvailable: json['isAvailable'] == true,
    lineTotal: (json['lineTotal'] as num).toDouble(),
  );
}

class Cart {
  const Cart({
    required this.id,
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  final int id;
  final List<CartItem> items;
  final int itemCount;
  final double subtotal;

  bool get isEmpty => items.isEmpty;
  bool get canCheckout => items.isNotEmpty && items.every((item) => item.isAvailable);

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return Cart(
      id: (json['id'] as num).toInt(),
      items: rawItems
          .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
