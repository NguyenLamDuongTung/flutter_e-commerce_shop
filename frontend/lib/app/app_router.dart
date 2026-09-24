import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_login_page.dart';
import '../features/admin/presentation/admin_section_page.dart';
import '../features/admin/presentation/admin_products_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/presentation/shop_home_page.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Dùng ref.read để router không bị tạo lại mỗi lần auth thay đổi.
      final authState = ref.read(authControllerProvider);
      final path = state.uri.path;

      // Keep the current page while login/session restoration is running.
      // Redirecting to /loading here unmounts the login form before the
      // authentication request completes and can send the user back home.
      if (authState.isLoading) return null;

      final user = authState.value;

      final isAdminPath = path.startsWith('/admin');
      final isAdminLogin = path == '/admin/login';

      final isCustomerProtected =
          path.startsWith('/cart') ||
          path.startsWith('/checkout') ||
          path.startsWith('/account');

      if (path == '/loading') return user?.isAdmin == true ? '/admin' : '/';

      // Bảo vệ tất cả trang admin, ngoại trừ trang đăng nhập.
      if (isAdminPath && !isAdminLogin) {
        if (user == null || !user.isAdmin) {
          return '/admin/login';
        }
      }

      // Admin đã đăng nhập thì không cho quay lại trang login admin.
      if (isAdminLogin && user?.isAdmin == true) {
        return '/admin';
      }

      // Khách hàng phải đăng nhập trước khi dùng cart/checkout/account.
      if (isCustomerProtected && user == null) {
        return '/login';
      }

      // Người dùng đã đăng nhập thì không hiển thị login/register.
      if ((path == '/login' || path == '/register') && user != null) {
        return user.isAdmin ? '/admin' : '/';
      }

      return null;
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.path}'),
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const ShopHomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
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
          description: 'Theo dõi và cập nhật trạng thái đơn hàng khách hàng.',
          icon: Icons.receipt_long_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/customers',
        builder: (context, state) => const AdminSectionPage(
          title: 'Quản lý khách hàng',
          description: 'Xem tài khoản, lịch sử mua hàng và hoạt động thành viên.',
          icon: Icons.people_alt_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminSectionPage(
          title: 'Doanh thu và phân tích',
          description: 'Theo dõi doanh thu, sản phẩm bán chạy và xu hướng bán hàng.',
          icon: Icons.query_stats_rounded,
        ),
      ),
    ],
  );

  // Khi đăng nhập hoặc đăng xuất, chỉ refresh redirect.
  // GoRouter không bị khởi tạo lại và không mất URL hiện tại.
  ref.listen(authControllerProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});
