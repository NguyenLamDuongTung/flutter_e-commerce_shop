import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_login_page.dart';
import '../features/admin/presentation/admin_products_page.dart';
import '../features/admin/presentation/admin_section_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/cart/presentation/cart_page.dart';
import '../features/home/presentation/shop_home_page.dart';
import '../features/orders/domain/order.dart';
import '../features/orders/presentation/checkout_page.dart';
import '../features/orders/presentation/order_success_page.dart';
import '../features/products/presentation/product_detail_page.dart';
import 'providers.dart';

String? _safeReturnPath(String? value) {
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);

  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/')) {
    return null;
  }

  final allowed =
      uri.path == '/' ||
      uri.path == '/cart' ||
      uri.path == '/checkout' ||
      uri.path.startsWith('/products/') ||
      uri.path.startsWith('/categories/');

  return allowed ? uri.toString() : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      if (auth.isLoading) return null;

      final user = auth.value;
      final path = state.uri.path;

      final adminLogin = path == '/admin/login';
      final adminPath = path == '/admin' || path.startsWith('/admin/');

      if (adminPath && !adminLogin) {
        if (user == null || !user.isAdmin) {
          return '/admin/login';
        }
      }

      if (adminLogin && user?.isAdmin == true) {
        return '/admin';
      }

      final protectedCustomerPage =
          path == '/cart' || path == '/checkout' || path == '/order-success';

      if (protectedCustomerPage && user == null) {
        return Uri(
          path: '/login',
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      if ((path == '/login' || path == '/register') && user != null) {
        final from = _safeReturnPath(state.uri.queryParameters['from']);

        return from ?? (user.isAdmin ? '/admin' : '/');
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Đường dẫn không tồn tại: ${state.uri.path}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ShopHomePage()),
      GoRoute(
        path: '/categories/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;

          return ShopHomePage(
            key: ValueKey('category-$slug'),
            categorySlug: slug,
          );
        },
      ),
      GoRoute(
        path: '/products/:slug',
        builder: (context, state) => ProductDetailPage(
          key: ValueKey(state.pathParameters['slug']),
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) => OrderSuccessPage(
          order: state.extra is ShopOrder ? state.extra as ShopOrder : null,
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/loading', redirect: (context, state) => '/'),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsPage(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminSectionPage(
          title: 'Quản lý đơn hàng',
          description: 'Theo dõi và cập nhật đơn hàng khách hàng.',
          icon: Icons.receipt_long_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/customers',
        builder: (context, state) => const AdminSectionPage(
          title: 'Quản lý khách hàng',
          description: 'Thông tin khách hàng thành viên.',
          icon: Icons.people_alt_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminSectionPage(
          title: 'Doanh thu và phân tích',
          description: 'Theo dõi kết quả kinh doanh.',
          icon: Icons.query_stats_rounded,
        ),
      ),
    ],
  );

  ref.listen(authControllerProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});
