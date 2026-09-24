import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../data/admin_dashboard_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  static final currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminDashboardProvider);
    final user = ref.watch(authControllerProvider).value;
    final desktop = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      drawer: desktop ? null : Drawer(child: _Sidebar(name: user?.fullName ?? 'Admin')),
      body: Row(
        children: [
          if (desktop) _Sidebar(name: user?.fullName ?? 'Admin'),
          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  final refreshed = ref.refresh(adminDashboardProvider.future);
                  await refreshed;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 14),
                      sliver: SliverToBoxAdapter(
                        child: _Header(
                          mobile: !desktop,
                          refresh: () => ref.invalidate(adminDashboardProvider),
                        ),
                      ),
                    ),
                    data.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        child: _ErrorView(
                          error: error.toString(),
                          retry: () => ref.invalidate(adminDashboardProvider),
                        ),
                      ),
                      data: (dashboard) => SliverPadding(
                        padding: const EdgeInsets.fromLTRB(26, 4, 26, 32),
                        sliver: SliverList.list(
                          children: [
                            _StatGrid(stats: dashboard.statistics),
                            const SizedBox(height: 18),
                            _Insights(data: dashboard),
                            const SizedBox(height: 18),
                            _Orders(orders: dashboard.recentOrders),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mobile, required this.refresh});
  final bool mobile;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (mobile) ...[
        Builder(
          builder: (context) => IconButton.filled(
            onPressed: () => Scaffold.of(context).openDrawer(),
            style: IconButton.styleFrom(backgroundColor: Colors.black),
            icon: const Icon(Icons.menu),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NOVA ADMIN SYSTEM', style: TextStyle(fontSize: 10, letterSpacing: 2.2, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1)),
            const Text('Theo dõi sản phẩm, đơn hàng, khách hàng và doanh thu.', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
      IconButton(onPressed: refresh, tooltip: 'Tải lại', icon: const Icon(Icons.refresh)),
      OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.storefront_outlined), label: const Text('Xem cửa hàng')),
    ],
  );
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final AdminStatistics stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Doanh thu', AdminDashboardPage.currency.format(stats.revenue), Icons.payments_outlined, true),
      ('Đơn hàng', '${stats.orders}', Icons.receipt_long_outlined, false),
      ('Sản phẩm', '${stats.products}', Icons.inventory_2_outlined, false),
      ('Khách hàng', '${stats.customers}', Icons.people_alt_outlined, false),
      ('Đơn đang xử lý', '${stats.pendingOrders}', Icons.pending_actions_outlined, false),
      ('Sắp hết hàng', '${stats.lowStockProducts}', Icons.warning_amber_rounded, false),
    ];

    return LayoutBuilder(builder: (context, box) {
      final count = box.maxWidth >= 1150 ? 3 : box.maxWidth >= 620 ? 2 : 1;
      final width = (box.maxWidth - (count - 1) * 14) / count;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: cards.map((card) => SizedBox(width: width, child: _StatCard(label: card.$1, value: card.$2, icon: card.$3, dark: card.$4))).toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.dark});
  final String label;
  final String value;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    height: 124,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF101010) : Colors.white,
      border: dark ? null : Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(color: dark ? Colors.white70 : const Color(0xFF64748B), fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 27, fontWeight: FontWeight.w900)),
      ])),
      Icon(icon, color: dark ? Colors.white : Colors.black, size: 30),
    ]),
  );
}

class _Insights extends StatelessWidget {
  const _Insights({required this.data});
  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final chart = _Panel(title: 'Doanh thu 12 tháng gần nhất', eyebrow: 'SALES INSIGHT', height: 330, child: _Chart(sales: data.monthlySales));
    final health = _Panel(
      title: 'Tình trạng cửa hàng',
      eyebrow: 'STORE HEALTH',
      height: 330,
      child: Column(children: [
        _Line(label: 'Sản phẩm đang bán', value: data.statistics.products),
        _Line(label: 'Sản phẩm sắp hết', value: data.statistics.lowStockProducts, alert: data.statistics.lowStockProducts > 0),
        _Line(label: 'Đơn cần xử lý', value: data.statistics.pendingOrders, alert: data.statistics.pendingOrders > 0),
        _Line(label: 'Khách hàng', value: data.statistics.customers),
        const Spacer(),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => context.go('/admin/products'), style: FilledButton.styleFrom(backgroundColor: Colors.black), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Quản lý sản phẩm'))),
      ]),
    );
    return box.maxWidth < 900
        ? Column(children: [chart, const SizedBox(height: 16), health])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: chart), const SizedBox(width: 16), Expanded(child: health)]);
  });
}

class _Chart extends StatelessWidget {
  const _Chart({required this.sales});
  final List<AdminMonthlySale> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const Center(child: Text('Chưa có dữ liệu doanh thu.'));
    final maximum = sales.fold<double>(0, (value, item) => math.max(value, item.revenue));
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: BarChart(BarChartData(
        maxY: maximum <= 0 ? 1 : maximum * 1.2,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= sales.length) return const SizedBox.shrink();
            final parts = sales[index].month.split('-');
            return Padding(padding: const EdgeInsets.only(top: 7), child: Text(parts.length == 2 ? parts[1] : sales[index].month, style: const TextStyle(fontSize: 10)));
          })),
        ),
        barGroups: [for (var i = 0; i < sales.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: sales[i].revenue, width: 18, color: Colors.black, borderRadius: BorderRadius.circular(5))])],
      )),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.alert = false});
  final String label;
  final int value;
  final bool alert;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B)))),
      Text('$value', style: TextStyle(fontWeight: FontWeight.w900, color: alert ? const Color(0xFFBE123C) : Colors.black)),
    ]),
  );
}

class _Orders extends StatelessWidget {
  const _Orders({required this.orders});
  final List<AdminRecentOrder> orders;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Đơn hàng mới nhất',
    eyebrow: 'RECENT ORDERS',
    child: orders.isEmpty
        ? const SizedBox(height: 120, child: Center(child: Text('Chưa có đơn hàng.')))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF111111)),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              columns: const [DataColumn(label: Text('MÃ ĐƠN')), DataColumn(label: Text('KHÁCH HÀNG')), DataColumn(label: Text('TỔNG TIỀN')), DataColumn(label: Text('THANH TOÁN')), DataColumn(label: Text('TRẠNG THÁI'))],
              rows: orders.map((order) => DataRow(cells: [
                DataCell(Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(Text(order.customerName)),
                DataCell(Text(AdminDashboardPage.currency.format(order.totalAmount))),
                DataCell(Text(order.paymentStatus)),
                DataCell(Text(order.status)),
              ])).toList(),
            ),
          ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.eyebrow, required this.child, this.height});
  final String title;
  final String eyebrow;
  final Widget child;
  final double? height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow, style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (height == null) child else Expanded(child: child),
    ]),
  );
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    width: 258,
    color: const Color(0xFF0B0B0B),
    padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [CircleAvatar(backgroundColor: Colors.white, child: Text('N', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))), SizedBox(width: 12), Expanded(child: Text('NOVA ADMIN SYSTEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)))]),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(17)), child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), const Text('Online', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12))])),
      ])),
      const SizedBox(height: 22),
      _Nav(icon: Icons.grid_view_rounded, label: 'Dashboard', active: true, tap: () => context.go('/admin')),
      _Nav(icon: Icons.inventory_2_outlined, label: 'Sản phẩm', tap: () => context.go('/admin/products')),
      _Nav(icon: Icons.receipt_long_outlined, label: 'Đơn hàng', tap: () => context.go('/admin/orders')),
      _Nav(icon: Icons.people_alt_outlined, label: 'Khách hàng', tap: () => context.go('/admin/customers')),
      _Nav(icon: Icons.query_stats_rounded, label: 'Doanh thu', tap: () => context.go('/admin/analytics')),
      const Spacer(),
      _Nav(icon: Icons.storefront_outlined, label: 'Xem cửa hàng', tap: () => context.go('/')),
      _Nav(icon: Icons.logout, label: 'Đăng xuất', tap: () async { await ref.read(authControllerProvider.notifier).logout(); if (context.mounted) context.go('/admin/login'); }),
    ])),
  );
}

class _Nav extends StatelessWidget {
  const _Nav({required this.icon, required this.label, required this.tap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback tap;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(13), child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(13), child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(children: [Icon(icon, size: 20, color: active ? Colors.black : Colors.white70), const SizedBox(width: 12), Text(label, style: TextStyle(color: active ? Colors.black : Colors.white, fontWeight: FontWeight.w700))]),
    ))),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.retry});
  final String error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off, size: 50),
    const SizedBox(height: 12),
    const Text('Không thể tải dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Text(error, textAlign: TextAlign.center),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
  ])));
}
