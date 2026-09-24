import '../../../core/network/api_client.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminDashboardData> getDashboard() async {
    final response = await _apiClient.get(
      '/admin/dashboard',
      authenticated: true,
    );

    return AdminDashboardData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.statistics,
    required this.recentOrders,
    required this.monthlySales,
  });

  final AdminStatistics statistics;
  final List<AdminRecentOrder> recentOrders;
  final List<AdminMonthlySale> monthlySales;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      statistics: AdminStatistics.fromJson(
        Map<String, dynamic>.from(json['statistics'] as Map? ?? const {}),
      ),
      recentOrders: (json['recentOrders'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AdminRecentOrder.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      monthlySales: (json['monthlySales'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AdminMonthlySale.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class AdminStatistics {
  const AdminStatistics({
    required this.customers,
    required this.products,
    required this.orders,
    required this.revenue,
    required this.pendingOrders,
    required this.lowStockProducts,
  });

  final int customers;
  final int products;
  final int orders;
  final double revenue;
  final int pendingOrders;
  final int lowStockProducts;

  factory AdminStatistics.fromJson(Map<String, dynamic> json) {
    return AdminStatistics(
      customers: _int(json['customers']),
      products: _int(json['products']),
      orders: _int(json['orders']),
      revenue: _double(json['revenue']),
      pendingOrders: _int(json['pendingOrders']),
      lowStockProducts: _int(json['lowStockProducts']),
    );
  }
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.totalAmount,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String orderNumber;
  final String customerName;
  final double totalAmount;
  final String paymentStatus;
  final String status;
  final DateTime? createdAt;

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    return AdminRecentOrder(
      id: _int(json['id']),
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      totalAmount: _double(json['totalAmount']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class AdminMonthlySale {
  const AdminMonthlySale({
    required this.month,
    required this.revenue,
    required this.orderCount,
  });

  final String month;
  final double revenue;
  final int orderCount;

  factory AdminMonthlySale.fromJson(Map<String, dynamic> json) {
    return AdminMonthlySale(
      month: json['month']?.toString() ?? '',
      revenue: _double(json['revenue']),
      orderCount: _int(json['orderCount']),
    );
  }
}

int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
