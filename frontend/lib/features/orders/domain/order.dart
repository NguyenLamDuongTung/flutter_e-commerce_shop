class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.lineTotal,
    this.productImage,
  });

  final int id;
  final int? productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: (json['id'] as num).toInt(),
    productId: (json['productId'] as num?)?.toInt(),
    productName: json['productName']?.toString() ?? '',
    productImage: json['productImage']?.toString(),
    price: (json['price'] as num).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
    lineTotal: (json['lineTotal'] as num).toDouble(),
  );
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.subtotal,
    required this.shippingFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.items,
    this.note,
  });

  final int id;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? note;
  final List<OrderItem> items;

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ShopOrder(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'pending',
      note: json['note']?.toString(),
      items: rawItems
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
