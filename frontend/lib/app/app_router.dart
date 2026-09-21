import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/admin/presentation/admin_login_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/presentation/shop_home_page.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final path = state.uri.path;

      if (authState.isLoading) {
        return path == '/loading' ? null : '/loading';
      }

      final user = authState.value;
      final isAdminPath = path.startsWith('/admin');
      final isAdminLogin = path == '/admin/login';
      final isCustomerProtected =
          path.startsWith('/cart') ||
          path.startsWith('/checkout') ||
          path.startsWith('/account');

      if (path == '/loading') {
        if (user?.isAdmin == true) {
          return '/admin';
        }

        return '/';
      }

      if (isAdminPath && !isAdminLogin) {
        if (user == null || !user.isAdmin) {
          return '/admin/login';
        }
      }

      if (isAdminLogin && user?.isAdmin == true) {
        return '/admin';
      }

      if (isCustomerProtected && user == null) {
        return '/login';
      }

      if ((path == '/login' || path == '/register') && user != null) {
        return user.isAdmin ? '/admin' : '/';
      }

      return null;
    },

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(child: Text('Page not found: ${state.uri.path}')),
      );
    },

    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(path: '/', builder: (context, state) => const ShopHomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
    ],
  );
});
